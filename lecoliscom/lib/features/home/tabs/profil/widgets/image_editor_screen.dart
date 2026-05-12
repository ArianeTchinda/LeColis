// lib/core/widgets/image_editor_screen.dart
//
// Éditeur d'image avec :
//  - Sélection image depuis galerie ou caméra (image_picker)
//  - Placement d'emojis/stickers déplaçables et redimensionnables
//  - Zone de flou (blur) dessinable sur l'image
//  - Export en Uint8List via RepaintBoundary
//  - Responsive mobile / tablette / web

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '/core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────
// POINT D'ENTRÉE — ouvre l'éditeur et retourne Uint8List?
// ─────────────────────────────────────────────────────────
Future<Uint8List?> ouvrirEditeurImage(
  BuildContext context, {
  Uint8List? imageInitiale, // si null → demande la source
}) async {
  Uint8List? imageBytes = imageInitiale;

  if (imageBytes == null) {
    // Choix source
    final source = await _choisirSource(context);
    if (source == null) return null;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (xFile == null) return null;
    imageBytes = await xFile.readAsBytes();
  }

  if (!context.mounted) return null;

  return Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ImageEditorScreen(imageBytes: imageBytes!),
    ),
  );
}

Future<ImageSource?> _choisirSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choisir la source',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _SourceTile(
            icon: Icons.photo_library_rounded,
            label: 'Galerie photos',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          _SourceTile(
            icon: Icons.camera_alt_rounded,
            label: 'Prendre une photo',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryPink.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryPink, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MODÈLES internes
// ─────────────────────────────────────────────────────────

class _EmojiSticker {
  String emoji;
  Offset position;
  double size;
  bool selected;

  _EmojiSticker({
    required this.emoji,
    required this.position,
    // ignore: unused_element_parameter
    this.size = 48,
    this.selected = false,
  });
}

class _BlurZone {
  Offset center;
  double radius;
  double sigma; // intensité du flou

  _BlurZone({required this.center, required this.radius, this.sigma = 18});
}

enum _EditorTool { emojis, blur, none }

// ─────────────────────────────────────────────────────────
// ÉCRAN ÉDITEUR
// ─────────────────────────────────────────────────────────

class ImageEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const ImageEditorScreen({super.key, required this.imageBytes});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _repaintKey  = GlobalKey();
  final TransformationController _zoomCtrl = TransformationController();

  final List<_EmojiSticker> _stickers  = [];
  final List<_BlurZone>     _blurZones = [];

  _EditorTool _activeTool    = _EditorTool.none;
  bool        _isExporting   = false;

  // Curseur flou
  Offset? _blurCursorPos;
  bool    _blurCursorVisible = false;

  double _blurRadius = 40;
  double _blurSigma  = 18; // degré de flou (intensité)

  @override
  void dispose() {
    _zoomCtrl.dispose();
    super.dispose();
  }

  static const _emojis = [
    '😊', '😎', '🙈', '🤩', '🥰', '😍', '🤫', '🤐',
    '🌸', '🌟', '💫', '✨', '🔥', '💕', '💋', '👑',
    '🎭', '🎪', '🌺', '🦋', '🌈', '💎', '🍑', '🌙',
    '⭐', '🎀', '🪷', '🦄', '🌹', '💐', '🫧', '🌊',
    '⬛', '🟥', '🟦', '🟩', '⬜', '🔲', '🔳', '▪️',
  ];

  // ── Export ───────────────────────────────────────────
  Future<void> _exporter() async {
    setState(() => _isExporting = true);

    // Désélectionner tous les stickers avant capture
    for (final s in _stickers) {
      s.selected = false;
    }
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 80));

    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (mounted) Navigator.pop(context, bytes);
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur export : $e'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  void _ajouterBlur(Offset localPos) {
    setState(() {
      _blurZones.add(_BlurZone(
        center: localPos,
        radius: _blurRadius,
        sigma:  _blurSigma,
      ));
    });
  }

  void _ajouterEmoji(String emoji) {
    setState(() {
      for (final s in _stickers) s.selected = false;
      _stickers.add(_EmojiSticker(
        emoji: emoji,
        position: const Offset(150, 200),
        selected: true,
      ));
    });
  }

  void _supprimerStickerSelectionne() {
    setState(() => _stickers.removeWhere((s) => s.selected));
  }

  void _supprimerDernierBlur() {
    if (_blurZones.isNotEmpty) setState(() => _blurZones.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: _buildAppBar(),
      body: isWide
          ? _buildWideLayout()
          : _buildMobileLayout(),
      bottomNavigationBar: isWide ? null : _buildBottomToolbar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A14),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Modifier l\'image',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        // Supprimer sélection
        if (_stickers.any((s) => s.selected))
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Color(0xFFFF5252)),
            onPressed: _supprimerStickerSelectionne,
            tooltip: 'Supprimer le sticker',
          ),
        // Annuler dernier flou
        if (_blurZones.isNotEmpty && _activeTool == _EditorTool.blur)
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.white70),
            onPressed: _supprimerDernierBlur,
            tooltip: 'Annuler dernier flou',
          ),
        // Valider
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _isExporting ? null : _exporter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isExporting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Valider',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Layout mobile ─────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildCanvas()),
        if (_activeTool == _EditorTool.emojis) _buildEmojiPicker(),
        if (_activeTool == _EditorTool.blur) _buildBlurControls(),
      ],
    );
  }

  // ── Layout desktop ────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Canvas centré
        Expanded(child: _buildCanvas()),
        // Panel latéral outils
        _buildSidePanel(),
      ],
    );
  }

  // ── Canvas éditeur ────────────────────────────────────
  Widget _buildCanvas() {
    // Le RepaintBoundary capture image + stickers + flous
    Widget imageStack = RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        children: [
          Image.memory(
            widget.imageBytes,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
          ..._blurZones.map((zone) => _BlurZoneWidget(zone: zone)),
          ..._stickers.map((sticker) => _StickerWidget(
                sticker:  sticker,
                onUpdate: () => setState(() {}),
                onSelect: () => setState(() {
                  for (final s in _stickers) s.selected = false;
                  sticker.selected = true;
                }),
              )),
        ],
      ),
    );

    // GestureDetector INSIDE InteractiveViewer — coords sont locales à l'image
    Widget gestureWrapped = GestureDetector(
      onTapDown: (d) {
        if (_activeTool == _EditorTool.blur) {
          _ajouterBlur(d.localPosition);
          return;
        }
        // Désélectionner stickers si tap en dehors
        bool hit = false;
        for (final s in _stickers) {
          final r = Rect.fromCenter(
              center: s.position, width: s.size, height: s.size);
          if (r.contains(d.localPosition)) { hit = true; break; }
        }
        if (!hit) setState(() { for (final s in _stickers) s.selected = false; });
      },
      onPanStart: (d) {
        if (_activeTool == _EditorTool.blur) {
          setState(() {
            _blurCursorVisible = true;
            _blurCursorPos = d.localPosition;
          });
        }
      },
      onPanUpdate: (d) {
        if (_activeTool == _EditorTool.blur) {
          setState(() => _blurCursorPos = d.localPosition);
        }
      },
      onPanEnd: (_) {
        if (_activeTool == _EditorTool.blur && _blurCursorPos != null) {
          _ajouterBlur(_blurCursorPos!);
        }
      },
      child: imageStack,
    );

    // InteractiveViewer — zoom uniquement quand outil = none
    Widget zoomable = InteractiveViewer(
      transformationController: _zoomCtrl,
      minScale: 0.5,
      maxScale: 5.0,
      panEnabled:   _activeTool == _EditorTool.none,
      scaleEnabled: _activeTool == _EditorTool.none,
      child: Center(child: gestureWrapped),
    );

    // Curseur fantôme flou (hors RepaintBoundary → non exporté)
    return MouseRegion(
      cursor: _activeTool == _EditorTool.blur
          ? SystemMouseCursors.none
          : SystemMouseCursors.basic,
      onExit: (_) => setState(() => _blurCursorVisible = false),
      onHover: (event) {
        if (_activeTool == _EditorTool.blur) {
          setState(() {
            _blurCursorVisible = true;
            _blurCursorPos = event.localPosition;
          });
        }
      },
      child: Stack(children: [
        zoomable,
        // Curseur fantôme affiché AU DESSUS de l'InteractiveViewer
        if (_activeTool == _EditorTool.blur &&
            _blurCursorVisible &&
            _blurCursorPos != null)
          Positioned(
            left:  _blurCursorPos!.dx - _blurRadius,
            top:   _blurCursorPos!.dy - _blurRadius,
            child: IgnorePointer(
              child: Container(
                width:  _blurRadius * 2,
                height: _blurRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primaryPink.withOpacity(0.85), width: 2),
                  color: AppColors.primaryPink.withOpacity(0.10),
                ),
                child: const Center(
                  child: Icon(Icons.blur_on_rounded,
                      color: Colors.white60, size: 16),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  // ── Toolbar mobile (bas) ─────────────────────────────
  Widget _buildBottomToolbar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF10101A),
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolBtn(
            icon: Icons.emoji_emotions_rounded,
            label: 'Emojis',
            active: _activeTool == _EditorTool.emojis,
            onTap: () => setState(() {
              _activeTool = _activeTool == _EditorTool.emojis
                  ? _EditorTool.none
                  : _EditorTool.emojis;
            }),
          ),
          _ToolBtn(
            icon: Icons.blur_on_rounded,
            label: 'Flou',
            active: _activeTool == _EditorTool.blur,
            onTap: () => setState(() {
              _activeTool = _activeTool == _EditorTool.blur
                  ? _EditorTool.none
                  : _EditorTool.blur;
            }),
          ),
          if (_blurZones.isNotEmpty)
            _ToolBtn(
              icon: Icons.undo_rounded,
              label: 'Annuler',
              active: false,
              onTap: _supprimerDernierBlur,
            ),
          if (_stickers.any((s) => s.selected))
            _ToolBtn(
              icon: Icons.delete_rounded,
              label: 'Supprimer',
              active: false,
              color: const Color(0xFFFF5252),
              onTap: _supprimerStickerSelectionne,
            ),
        ],
      ),
    );
  }

  // ── Panel latéral desktop ─────────────────────────────
  Widget _buildSidePanel() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF10101A),
        border: Border(left: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Outil Emojis
          _PanelSection(
            title: 'Emojis / Stickers',
            icon: Icons.emoji_emotions_rounded,
            active: _activeTool == _EditorTool.emojis,
            onToggle: () => setState(() {
              _activeTool = _activeTool == _EditorTool.emojis
                  ? _EditorTool.none
                  : _EditorTool.emojis;
            }),
            child: _activeTool == _EditorTool.emojis
                ? SizedBox(height: 220, child: _buildEmojiGrid())
                : null,
          ),

          const Divider(color: Color(0xFF1E1E2E), height: 1),

          // Outil Flou
          _PanelSection(
            title: 'Zone de flou',
            icon: Icons.blur_on_rounded,
            active: _activeTool == _EditorTool.blur,
            onToggle: () => setState(() {
              _activeTool = _activeTool == _EditorTool.blur
                  ? _EditorTool.none
                  : _EditorTool.blur;
            }),
            child: _activeTool == _EditorTool.blur
                ? _buildBlurControlsDesktop()
                : null,
          ),

          // Slider taille sticker sélectionné (desktop)
          if (_stickers.any((s) => s.selected)) ...[
            const Divider(color: Color(0xFF1E1E2E), height: 1),
            _PanelSection(
              title: 'Taille du sticker',
              icon: Icons.format_size_rounded,
              active: true,
              onToggle: () {},
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_stickers.firstWhere((s) => s.selected).size.toInt()} px',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primaryPink,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: AppColors.primaryPink,
                        overlayColor: AppColors.primaryPink.withOpacity(0.15),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _stickers.firstWhere((s) => s.selected).size,
                        min: 24,
                        max: 180,
                        onChanged: (v) => setState(() {
                          _stickers.firstWhere((s) => s.selected).size = v;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Infos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '💡 Placez des emojis ou des zones de flou pour masquer votre visage avant de publier.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Picker emojis mobile ──────────────────────────────
  Widget _buildEmojiPicker() {
    final selectedSticker = _stickers.where((s) => s.selected).firstOrNull;
    return Container(
      color: const Color(0xFF10101A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slider taille si sticker sélectionné
          if (selectedSticker != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taille : ${selectedSticker.size.toInt()} px',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primaryPink,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primaryPink,
                      overlayColor: AppColors.primaryPink.withOpacity(0.15),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: selectedSticker.size,
                      min: 24,
                      max: 180,
                      onChanged: (v) => setState(() => selectedSticker.size = v),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              selectedSticker != null
                  ? 'Sélectionnez un autre emoji'
                  : 'Appuyez pour ajouter',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          SizedBox(height: 160, child: _buildEmojiGrid()),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _emojis.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _ajouterEmoji(_emojis[i]),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(_emojis[i], style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }

  // ── Contrôles flou mobile ────────────────────────────
  Widget _buildBlurControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: const Color(0xFF10101A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryPink.withOpacity(0.8), width: 2),
                color: AppColors.primaryPink.withOpacity(0.12),
              ),
              child: const Icon(Icons.blur_on_rounded, color: AppColors.primaryPink, size: 13),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Appuyez sur l\'image pour flouter',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          // Taille
          Text('Taille : ${_blurRadius.toInt()} px',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          _miniSlider(
            value: _blurRadius, min: 20, max: 120,
            onChanged: (v) => setState(() => _blurRadius = v),
          ),
          // Intensité
          Text('Intensité : ${_blurSigma.toInt()}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          _miniSlider(
            value: _blurSigma, min: 2, max: 40,
            onChanged: (v) => setState(() => _blurSigma = v),
          ),
          if (_blurZones.isNotEmpty)
            TextButton.icon(
              onPressed: _supprimerDernierBlur,
              icon: const Icon(Icons.undo_rounded, size: 15),
              label: const Text('Annuler dernier'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPinkSoft,
                  padding: EdgeInsets.zero),
            ),
        ],
      ),
    );
  }

  Widget _buildBlurControlsDesktop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cliquez sur l\'image pour placer un flou',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          Text('Taille : ${_blurRadius.toInt()} px',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          _miniSlider(
            value: _blurRadius, min: 20, max: 120,
            onChanged: (v) => setState(() => _blurRadius = v),
          ),
          Text('Intensité : ${_blurSigma.toInt()}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          _miniSlider(
            value: _blurSigma, min: 2, max: 40,
            onChanged: (v) => setState(() => _blurSigma = v),
          ),
          if (_blurZones.isNotEmpty)
            TextButton.icon(
              onPressed: _supprimerDernierBlur,
              icon: const Icon(Icons.undo_rounded, size: 14),
              label: const Text('Annuler dernier'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPinkSoft,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  // Slider compact réutilisable
  Widget _miniSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor:   AppColors.primaryPink,
        inactiveTrackColor: AppColors.divider,
        thumbColor:         AppColors.primaryPink,
        overlayColor:       AppColors.primaryPink.withOpacity(0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 3,
      ),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGET STICKER DÉPLAÇABLE
// ─────────────────────────────────────────────────────────
class _StickerWidget extends StatefulWidget {
  final _EmojiSticker sticker;
  final VoidCallback onUpdate;
  final VoidCallback onSelect;

  const _StickerWidget({
    required this.sticker,
    required this.onUpdate,
    required this.onSelect,
  });

  @override
  State<_StickerWidget> createState() => _StickerWidgetState();
}

class _StickerWidgetState extends State<_StickerWidget> {
  // Taille au début du geste de pinch — évite la dérive cumulative
  double _baseSizeAtGestureStart = 48;

  @override
  Widget build(BuildContext context) {
    final sticker = widget.sticker;

    return Positioned(
      left: sticker.position.dx - sticker.size / 2,
      top:  sticker.position.dy - sticker.size / 2,
      child: GestureDetector(
        onTap: widget.onSelect,
        onScaleStart: (d) {
          // Mémorise la taille au début du pinch
          _baseSizeAtGestureStart = sticker.size;
        },
        onScaleUpdate: (d) {
          // Déplacement (1 doigt ou focal shift multi-doigts)
          sticker.position = Offset(
            sticker.position.dx + d.focalPointDelta.dx,
            sticker.position.dy + d.focalPointDelta.dy,
          );
          // Redimensionnement pinch (2 doigts) — relatif à la taille initiale
          if (d.pointerCount >= 2 && d.scale != 1.0) {
            sticker.size = (_baseSizeAtGestureStart * d.scale)
                .clamp(24.0, 220.0);
          }
          widget.onUpdate();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bordure si sélectionné
            if (sticker.selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primaryPink, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            Text(
              sticker.emoji,
              style: TextStyle(fontSize: sticker.size * 0.75),
            ),
            // Handle coin bas-droite (souris / 1 doigt)
            if (sticker.selected)
              Positioned(
                right: -10, bottom: -10,
                child: GestureDetector(
                  onPanStart: (_) {
                    _baseSizeAtGestureStart = sticker.size;
                  },
                  onPanUpdate: (d) {
                    final delta = (d.delta.dx + d.delta.dy) / 2;
                    sticker.size = (sticker.size + delta).clamp(24.0, 220.0);
                    widget.onUpdate();
                  },
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.open_in_full_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGET ZONE FLOU
// ─────────────────────────────────────────────────────────
class _BlurZoneWidget extends StatelessWidget {
  final _BlurZone zone;
  const _BlurZoneWidget({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: zone.center.dx - zone.radius,
      top:  zone.center.dy - zone.radius,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: zone.sigma, sigmaY: zone.sigma),
          child: Container(
            width:  zone.radius * 2,
            height: zone.radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.01),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS UI INTERNES
// ─────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? AppColors.primaryPink : AppColors.textMuted);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onToggle;
  final Widget? child;

  const _PanelSection({
    required this.title,
    required this.icon,
    required this.active,
    required this.onToggle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.transparent,
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: active
                        ? AppColors.primaryPink
                        : AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: active
                          ? AppColors.primaryPink
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  active
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}