// lib/features/home/tabs/profil/screens/publication_form_screen.dart
//
// Formulaire d'ajout / modification d'une publication.
// Utilisé depuis ProfilDashboard pour créer ou éditer.
// Structure : titre, description, catégories (multi-select),
//             localisation hiérarchique (pays→région→ville→quartier),
//             tarif, disponibilité, images (placeholder upload).

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/data/categories_data.dart';
import '../../../../../core/data/location_data.dart';
import '../widgets/image_editor_screen.dart';
import '/core/models/escort_model.dart';

// ─────────────────────────────────────────────────────────
// Résultat du formulaire — transmis au dashboard
// ─────────────────────────────────────────────────────────
class PublicationFormResult {
  final String       titre;
  final String       description;
  final List<String> categories;
  final String       pays;
  final String       region;
  final String       ville;
  final String       quartier;
  final double?      tarif;
  final bool         estDisponible;
  // En prod : List<File> pour les images uploadées
  final List<String> imageUrls; // mock : URLs vides pour l'instant

  const PublicationFormResult({
    required this.titre,
    required this.description,
    required this.categories,
    required this.pays,
    required this.region,
    required this.ville,
    required this.quartier,
    this.tarif,
    required this.estDisponible,
    required this.imageUrls,
  });
}

// ─────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────────────────
class PublicationFormScreen extends StatefulWidget {
  /// null → création, non-null → modification
  final PublicationGestion? existing;

  const PublicationFormScreen({super.key, this.existing});

  @override
  State<PublicationFormScreen> createState() => _PublicationFormScreenState();
}

class _PublicationFormScreenState extends State<PublicationFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titreCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _tarifCtrl   = TextEditingController();

  // Localisation
  String  _pays      = 'Cameroun';
  String  _region    = '';
  String  _ville     = '';
  String  _quartier  = '';

  // Catégories sélectionnées
  final Set<String> _categories = {};

  // Disponibilité
  bool _estDisponible = true;

  // Images réelles — stockées en bytes après édition
  final List<Uint8List> _imageBytesList = [];

  bool _loading = false;

  bool get _estModification => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      // Pré-remplir pour modification
      _titreCtrl.text = e.titre;
      _descCtrl.text  = ''; // PublicationGestion n'a pas de desc — à enrichir
      _categories.add(e.categorie);
      if (e.imageUrl != null) {
        // En modification : l'image existante reste une URL réseau
        // On ne la charge pas en bytes ici — géré côté API
      }
      // Localisation non présente dans PublicationGestion → défaut
      _pays = 'Cameroun';
    }
    // Init région/ville/quartier sur premier disponible
    _syncRegion();
  }

  void _syncRegion() {
    final regions = getRegions(_pays);
    if (regions.isNotEmpty && !regions.contains(_region)) {
      _region = regions.first;
    }
    _syncVille();
  }

  void _syncVille() {
    final villes = getVilles(_pays, _region);
    if (villes.isNotEmpty && !villes.contains(_ville)) {
      _ville = villes.first;
    }
    _syncQuartier();
  }

  void _syncQuartier() {
    final quartiers = getQuartiers(_pays, _region, _ville);
    if (quartiers.isNotEmpty && !quartiers.contains(_quartier)) {
      _quartier = quartiers.first;
    } else if (quartiers.isEmpty) {
      _quartier = '';
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _tarifCtrl.dispose();
    super.dispose();
  }

   // ── Validation et envoi ───────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_categories.isEmpty) {
      _showError('Sélectionnez au moins une catégorie.');
      return;
    }

    if (_ville.isEmpty) {
      _showError('Choisissez une ville.');
      return;
    }

    // Optionnel mais recommandé
    if (_imageBytesList.isEmpty && !_estModification) {
      _showError('Ajoutez au moins une photo pour la publication.');
      return;
    }

    setState(() => _loading = true);

    // Simule un délai API
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      // Création d'URLs mock à partir des images en bytes
      final List<String> mockImageUrls = _imageBytesList.isNotEmpty
          ? List.generate(
              _imageBytesList.length,
              (index) => 'image_${DateTime.now().millisecondsSinceEpoch}_$index.jpg')
          : (widget.existing?.imageUrl != null 
              ? [widget.existing!.imageUrl!] 
              : <String>[]);

      final result = PublicationFormResult(
        titre:         _titreCtrl.text.trim(),
        description:   _descCtrl.text.trim(),
        categories:    _categories.toList(),
        pays:          _pays,
        region:        _region,
        ville:         _ville,
        quartier:      _quartier,
        tarif:         double.tryParse(
                       _tarifCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        estDisponible: _estDisponible,
        imageUrls:     mockImageUrls,          // ← Correction principale
      );

      Navigator.pop(context, result);
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final hPad   = isWide ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor:  AppColors.background,
        elevation:        0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _estModification ? 'Modifier la publication' : 'Nouvelle publication',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryPink))
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _estModification ? 'Enregistrer' : 'Publier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 48),
                    child: isWide
                        ? _buildWideLayout()
                        : _buildNarrowLayout(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layout 2 colonnes (tablette/desktop) ─────────────

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche : images + disponibilité
        SizedBox(
          width: 260,
          child: Column(children: [
            _ImagesSection(
              imageBytesList: _imageBytesList,
              onAddImage:     _ajouterImage,
              onEditImage:    _modifierImage,
              onRemove:       (i) => setState(() => _imageBytesList.removeAt(i)),
            ),
            const SizedBox(height: 16),
            _DisponibiliteToggle(
              value:     _estDisponible,
              onChanged: (v) => setState(() => _estDisponible = v),
            ),
          ]),
        ),
        const SizedBox(width: 24),
        // Colonne droite : tous les champs texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFormFields(),
          ),
        ),
      ],
    );
  }

  // ── Layout 1 colonne (mobile) ─────────────────────────

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImagesSection(
          imageBytesList: _imageBytesList,
          onAddImage:     _ajouterImage,
          onEditImage:    _modifierImage,
          onRemove:       (i) => setState(() => _imageBytesList.removeAt(i)),
        ),
        const SizedBox(height: 16),
        ..._buildFormFields(),
        const SizedBox(height: 16),
        _DisponibiliteToggle(
          value:     _estDisponible,
          onChanged: (v) => setState(() => _estDisponible = v),
        ),
      ],
    );
  }

  // ── Champs communs ────────────────────────────────────

  List<Widget> _buildFormFields() {
    return [
      // Titre
      _SectionLabel('Titre de l\'annonce'),
      const SizedBox(height: 8),
      _FormField(
        controller: _titreCtrl,
        hint:       'Ex: Disponible ce soir à Bastos',
        maxLength:  80,
        validator:  (v) {
          if (v == null || v.trim().length < 5) return '5 caractères minimum';
          return null;
        },
      ),

      const SizedBox(height: 18),

      // Description
      _SectionLabel('Description'),
      const SizedBox(height: 8),
      _FormField(
        controller: _descCtrl,
        hint:       'Décrivez vos services, disponibilités, conditions…',
        maxLines:   5,
        maxLength:  600,
        validator:  (v) {
          if (v == null || v.trim().length < 20) return '20 caractères minimum';
          return null;
        },
      ),

      const SizedBox(height: 18),

      // Catégories
      _SectionLabel('Catégories'),
      const SizedBox(height: 4),
      const Text(
        'Sélectionnez les catégories qui correspondent à votre profil.',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      const SizedBox(height: 10),
      _CategoriesSelector(
        selected:  _categories,
        onToggle:  (cat) => setState(() {
          if (_categories.contains(cat)) {
            _categories.remove(cat);
          } else {
            _categories.add(cat);
          }
        }),
      ),

      const SizedBox(height: 18),

      // Localisation
      _SectionLabel('Localisation'),
      const SizedBox(height: 8),
      _LocalisationSelector(
        pays:      _pays,
        region:    _region,
        ville:     _ville,
        quartier:  _quartier,
        onPays:    (v) => setState(() { _pays = v; _syncRegion(); }),
        onRegion:  (v) => setState(() { _region = v; _syncVille(); }),
        onVille:   (v) => setState(() { _ville = v; _syncQuartier(); }),
        onQuartier: (v) => setState(() => _quartier = v),
      ),

      const SizedBox(height: 18),

      // Tarif
      _SectionLabel('Tarif (FCFA) — optionnel'),
      const SizedBox(height: 8),
      _FormField(
        controller: _tarifCtrl,
        hint:       'Ex: 25000',
        keyboard:   TextInputType.number,
      ),
    ];
  }

  Future<void> _ajouterImage() async {
    if (_imageBytesList.length >= 6) {
      _showError('Maximum 6 images par publication.');
      return;
    }
    final bytes = await ouvrirEditeurImage(context);
    if (bytes != null) {
      setState(() => _imageBytesList.add(bytes));
    }
  }

  Future<void> _modifierImage(int index) async {
    final bytes = await ouvrirEditeurImage(
      context,
      imageInitiale: _imageBytesList[index],
    );
    if (bytes != null) {
      setState(() => _imageBytesList[index] = bytes);
    }
  }
}

// ═══════════════════════════════════════════════════════
// SECTION IMAGES
// ═══════════════════════════════════════════════════════
class _ImagesSection extends StatelessWidget {
  final List<Uint8List> imageBytesList;
  final VoidCallback onAddImage;
  final void Function(int) onEditImage;
  final void Function(int) onRemove;

  const _ImagesSection({
    required this.imageBytesList,
    required this.onAddImage,
    required this.onEditImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Photos (max 6)'),
        const SizedBox(height: 4),
        const Text(
          'La première photo sera la vignette principale. Appuyez sur une photo pour la modifier.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: imageBytesList.length + (imageBytesList.length < 6 ? 1 : 0),
          itemBuilder: (_, i) {
            // Bouton "Ajouter"
            if (i == imageBytesList.length) {
              return GestureDetector(
                onTap: onAddImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPink.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate_rounded,
                          color: AppColors.primaryPink, size: 26),
                      SizedBox(height: 6),
                      Text('Ajouter',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }

            // Image existante
            return Stack(
              children: [
                // Image cliquable pour modification
                GestureDetector(
                  onTap: () => onEditImage(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytesList[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),

                // Badge "Cover" sur la première image
                if (i == 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Bouton Modifier
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: () => onEditImage(i),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),

                // Bouton Supprimer ← Corrigé ici
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// SÉLECTEUR DE CATÉGORIES (par groupes, expansible)
// ═══════════════════════════════════════════════════════
class _CategoriesSelector extends StatefulWidget {
  final Set<String>          selected;
  final void Function(String) onToggle;

  const _CategoriesSelector({
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_CategoriesSelector> createState() => _CategoriesSelectorState();
}

class _CategoriesSelectorState extends State<_CategoriesSelector> {
  final Set<String> _expandedGroups = {'Morphologie', 'Âge'};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categoriesParGroupe.map((groupe) {
        final isExpanded = _expandedGroups.contains(groupe.nom);
        final selectedInGroup = groupe.categories
            .where((c) => widget.selected.contains(c))
            .length;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(
              color: selectedInGroup > 0
                  ? AppColors.primaryPink.withOpacity(0.35)
                  : AppColors.divider,
            ),
          ),
          child: Column(children: [
            // En-tête groupe
            GestureDetector(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(groupe.nom);
                } else {
                  _expandedGroups.add(groupe.nom);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                child: Row(children: [
                  Text(groupe.nom,
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color: selectedInGroup > 0
                              ? AppColors.primaryPink
                              : AppColors.textPrimary)),
                  if (selectedInGroup > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:        AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$selectedInGroup',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size:  18,
                    color: AppColors.textMuted,
                  ),
                ]),
              ),
            ),

            // Chips catégories
            if (isExpanded) ...[
              const Divider(
                  color: AppColors.divider, height: 1,
                  indent: 14, endIndent: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Wrap(
                  spacing:     8,
                  runSpacing:  8,
                  children: groupe.categories.map((cat) {
                    final sel = widget.selected.contains(cat);
                    return GestureDetector(
                      onTap: () => widget.onToggle(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:        sel
                              ? AppColors.primaryPink.withOpacity(0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border:       Border.all(
                            color: sel
                                ? AppColors.primaryPink.withOpacity(0.5)
                                : AppColors.divider,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize:   12,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: sel
                                    ? AppColors.primaryPink
                                    : AppColors.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ]),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SÉLECTEUR DE LOCALISATION HIÉRARCHIQUE
// ═══════════════════════════════════════════════════════
class _LocalisationSelector extends StatelessWidget {
  final String  pays, region, ville, quartier;
  final void Function(String) onPays, onRegion, onVille, onQuartier;

  const _LocalisationSelector({
    required this.pays,
    required this.region,
    required this.ville,
    required this.quartier,
    required this.onPays,
    required this.onRegion,
    required this.onVille,
    required this.onQuartier,
  });

  @override
  Widget build(BuildContext context) {
    final paysList     = getPays();
    final regionsList  = getRegions(pays);
    final villesList   = getVilles(pays, region);
    final quartierList = getQuartiers(pays, region, ville);

    return Container(
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        // Pays + Région
        Row(children: [
          Expanded(child: _LocDropdown(
            label:    'Pays',
            value:    pays,
            items:    paysList,
            onChanged: onPays,
          )),
          const SizedBox(width: 10),
          Expanded(child: _LocDropdown(
            label:    'Région',
            value:    regionsList.contains(region) ? region : null,
            items:    regionsList,
            onChanged: onRegion,
          )),
        ]),
        const SizedBox(height: 10),
        // Ville + Quartier
        Row(children: [
          Expanded(child: _LocDropdown(
            label:    'Ville',
            value:    villesList.contains(ville) ? ville : null,
            items:    villesList,
            onChanged: onVille,
          )),
          const SizedBox(width: 10),
          Expanded(child: quartierList.isEmpty
              ? _LocDropdown(
                  label:    'Quartier',
                  value:    null,
                  items:    const [],
                  onChanged: (_) {},
                  disabled: true,
                )
              : _LocDropdown(
                  label:    'Quartier',
                  value:    quartierList.contains(quartier) ? quartier : null,
                  items:    quartierList,
                  onChanged: onQuartier,
                )),
        ]),
      ]),
    );
  }
}

class _LocDropdown extends StatelessWidget {
  final String       label;
  final String?      value;
  final List<String> items;
  final void Function(String) onChanged;
  final bool         disabled;

  const _LocDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value:        items.contains(value) ? value : null,
          onChanged:    disabled || items.isEmpty
              ? null
              : (v) { if (v != null) onChanged(v); },
          dropdownColor: AppColors.surface,
          isExpanded:    true,
          icon:          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.textMuted),
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 13),
          hint: Text(
            disabled ? '—' : (items.isEmpty ? 'N/A' : 'Choisir'),
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
          decoration: InputDecoration(
            filled:         true,
            fillColor:      disabled
                ? AppColors.surfaceElevated.withOpacity(0.5)
                : AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primaryPink, width: 1.5)),
          ),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          )).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// DISPONIBILITÉ TOGGLE
// ═══════════════════════════════════════════════════════
class _DisponibiliteToggle extends StatelessWidget {
  final bool                  value;
  final void Function(bool)   onChanged;

  const _DisponibiliteToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: value
              ? const Color(0xFF25D366).withOpacity(0.35)
              : AppColors.divider,
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF25D366).withOpacity(0.12)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            value
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size:  18,
            color: value
                ? const Color(0xFF25D366)
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Disponible maintenant',
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.textPrimary)),
            Text(
              value
                  ? 'Votre annonce sera marquée disponible'
                  : 'Votre annonce sera marquée indisponible',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ]),
        ),
        Switch(
          value:            value,
          onChanged:        onChanged,
          activeColor:      const Color(0xFF25D366),
          activeTrackColor: const Color(0xFF25D366).withOpacity(0.25),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.divider,
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize:   13,
        fontWeight: FontWeight.w600,
        color:      AppColors.textSecondary),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final int                        maxLines;
  final int?                       maxLength;
  final TextInputType              keyboard;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines  = 1,
    this.maxLength,
    this.keyboard  = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    maxLines:     maxLines,
    maxLength:    maxLength,
    keyboardType: keyboard,
    validator:    validator,
    style: const TextStyle(
        color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText:       hint,
      hintStyle:      const TextStyle(
          color: AppColors.textMuted, fontSize: 13),
      filled:         true,
      fillColor:      AppColors.surface,
      counterStyle:   const TextStyle(
          color: AppColors.textMuted, fontSize: 11),
      errorStyle:     const TextStyle(
          color: Color(0xFFFF5252), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.primaryPink, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF5252))),
    ),
  );
}