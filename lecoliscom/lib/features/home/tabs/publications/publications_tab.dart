// lib/features/home/tabs/publications_tab.dart
//
// Grille responsive de publications avec :
//  - Tri aléatoire pondéré (Premium > Standard > Basique)
//  - Re-shuffle à chaque chargement
//  - Recherche temps réel (depuis AppBar via ValueNotifier)
//  - Filtre catégorie + ville :
//      • Mobile  → bottom sheet
//      • Desktop → panneau latéral inline (plus de bottom sheet bizarre)
//  - 1 col mobile / 2 tablette / 3-4 web
//  - Publications actives uniquement

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/publication_model.dart';
import '../../../../core/data/location_data.dart';
import '../../../../core/data/categories_data.dart';
import 'widgets/publication_card.dart';
import './screens/publication_detail_screen.dart';

class PublicationsTab extends StatefulWidget {
  /// Query de recherche partagée depuis HomeScreen
  final ValueNotifier<String>? searchQuery;

  const PublicationsTab({super.key, this.searchQuery});

  @override
  State<PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends State<PublicationsTab> {
  late List<PublicationModel> _publications;
  String _filtreCategorie = 'Toutes';
  String _filtrePays      = 'Toutes';
  String _filtreVille     = 'Toutes';

  // Panneau filtre desktop ouvert/fermé
  bool _desktopFilterOpen = false;

  @override
  void initState() {
    super.initState();
    _publications = _buildWeightedShuffled();
    widget.searchQuery?.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchQuery?.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  // ── Tri aléatoire pondéré ──────────────────────────────
  List<PublicationModel> _buildWeightedShuffled() {
    final actives = mockPublications.where((p) => p.estActive).toList();
    final pool    = <PublicationModel>[];
    for (final pub in actives) {
      for (int i = 0; i < pub.poidsAffichage; i++) {
        pool.add(pub);
      }
    }
    pool.shuffle(Random());
    final seen   = <String>{};
    final result = <PublicationModel>[];
    for (final pub in pool) {
      if (seen.add(pub.id)) result.add(pub);
    }
    return result;
  }

  // ── Publications filtrées + recherche ─────────────────
  List<PublicationModel> get _filtered {
    final q = widget.searchQuery?.value.toLowerCase() ?? '';
    return _publications.where((p) {
      final catOk   = _filtreCategorie == 'Toutes' || p.categorie == _filtreCategorie;
      final paysOk  = _filtrePays      == 'Toutes' || p.pays      == _filtrePays;
      final villeOk = _filtreVille     == 'Toutes' || p.ville     == _filtreVille;
      final searchOk = q.isEmpty ||
          p.titre.toLowerCase().contains(q) ||
          p.escortPseudo.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.categorie.toLowerCase().contains(q) ||
          p.pays.toLowerCase().contains(q) ||
          p.ville.toLowerCase().contains(q) ||
          p.quartier.toLowerCase().contains(q);
      return catOk && paysOk && villeOk && searchOk;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _filtreCategorie != 'Toutes' || _filtrePays != 'Toutes' || _filtreVille != 'Toutes';

  int _columnCount(double width) {
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 650)  return 2;
    return 1;
  }

  void _refresh() => setState(() {
        _filtreCategorie = 'Toutes';
        _filtrePays      = 'Toutes';
        _filtreVille     = 'Toutes';
        _publications    = _buildWeightedShuffled();
      });

  void _applyFilter(String cat, String pays, String ville) =>
      setState(() {
        _filtreCategorie = cat;
        _filtrePays      = pays;
        _filtreVille     = ville;
      });

  // ── Ouvrir filtre (mobile = bottom sheet, desktop = inline) ──
  void _openFiltreMobile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FiltreSheet(
        selectedCategorie: _filtreCategorie,
        selectedPays:      _filtrePays,
        selectedVille:     _filtreVille,
        onApply:           _applyFilter,
      ),
    );
  }

  void _openDetail(PublicationModel pub) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => PublicationDetailScreen(
          publication: pub,
          allPublications: _publications,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width  = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    return isWide ? _buildDesktopLayout(width) : _buildMobileLayout();
  }

  // ═══════════════════════════════════════════════════════
  // LAYOUT DESKTOP : grille + panneau filtre latéral
  // ═══════════════════════════════════════════════════════
  Widget _buildDesktopLayout(double width) {
    final filtered = _filtered;
    final cols     = _columnCount(_desktopFilterOpen ? width - 280 : width);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Panneau filtre latéral ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: _desktopFilterOpen ? 260 : 0,
          child: _desktopFilterOpen
              ? _DesktopFilterPanel(
                  selectedCategorie: _filtreCategorie,
                  selectedPays:      _filtrePays,
                  selectedVille:     _filtreVille,
                  onApply:           _applyFilter,
                  onClose: () => setState(() => _desktopFilterOpen = false),
                )
              : const SizedBox.shrink(),
        ),

        // ── Contenu principal ──
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isWide: true, filtered: filtered)),
              if (_hasActiveFilter)
                SliverToBoxAdapter(child: _buildActiveChips()),
              _buildGridSliver(filtered, cols, isWide: true),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // LAYOUT MOBILE
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    final filtered = _filtered;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(isWide: false, filtered: filtered)),
        if (_hasActiveFilter)
          SliverToBoxAdapter(child: _buildActiveChips()),
        _buildGridSliver(filtered, 1, isWide: false),
      ],
    );
  }

  // ── En-tête ────────────────────────────────────────────
  Widget _buildHeader({required bool isWide, required List<PublicationModel> filtered}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          // Titre + compteur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publications',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize:   28,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${filtered.length} annonce${filtered.length > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Bouton refresh
          GestureDetector(
            onTap: _refresh,
            child: _HeaderBtn(
              icon: Icons.refresh_rounded,
              active: false,
            ),
          ),
          const SizedBox(width: 8),

          // Bouton filtre
          GestureDetector(
            onTap: isWide
                ? () => setState(() => _desktopFilterOpen = !_desktopFilterOpen)
                : _openFiltreMobile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _hasActiveFilter || (isWide && _desktopFilterOpen)
                    ? AppColors.primaryPink.withOpacity(0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasActiveFilter || (isWide && _desktopFilterOpen)
                      ? AppColors.primaryPink.withOpacity(0.4)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size:  15,
                    color: _hasActiveFilter || (isWide && _desktopFilterOpen)
                        ? AppColors.primaryPink
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isWide && _desktopFilterOpen ? 'Fermer' : 'Filtrer',
                    style: TextStyle(
                      fontSize:   12,
                      color:      _hasActiveFilter || (isWide && _desktopFilterOpen)
                          ? AppColors.primaryPink
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_hasActiveFilter) ...[
                    const SizedBox(width: 5),
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chips filtres actifs ───────────────────────────────
  Widget _buildActiveChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Wrap(
        spacing: 8,
        children: [
          if (_filtreCategorie != 'Toutes')
            _ActiveFilterChip(
              label:    _filtreCategorie,
              onRemove: () => setState(() => _filtreCategorie = 'Toutes'),
            ),
          if (_filtreVille != 'Toutes')
            _ActiveFilterChip(
              label:    _filtreVille,
              onRemove: () => setState(() => _filtreVille = 'Toutes'),
            ),
        ],
      ),
    );
  }

  // ── Grille / liste ─────────────────────────────────────
  Widget _buildGridSliver(
    List<PublicationModel> filtered,
    int cols, {
    required bool isWide,
  }) {
    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Aucune publication trouvée',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _refresh,
                child: Text(
                  'Réinitialiser les filtres',
                  style: TextStyle(
                    color:      AppColors.primaryPink,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final padding = EdgeInsets.fromLTRB(
      16, 16, 16,
      cols == 1 ? 120 : 40,
    );

    if (cols == 1) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PublicationCard(
                publication: filtered[i],
                allPublications: _publications,
                onTap: () => _openDetail(filtered[i]),
              ),
            ),
            childCount: filtered.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   cols,
          crossAxisSpacing: 14,
          mainAxisSpacing:  14,
          childAspectRatio: 3 / 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => PublicationCard(
            publication: filtered[i],
            allPublications: _publications,
            onTap: () => _openDetail(filtered[i]),
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Panneau filtre DESKTOP (latéral, inline)
// ═══════════════════════════════════════════════════════
class _DesktopFilterPanel extends StatefulWidget {
  final String selectedCategorie;
  final String selectedPays;
  final String selectedVille;
  final void Function(String, String, String) onApply;
  final VoidCallback onClose;

  const _DesktopFilterPanel({
    required this.selectedCategorie,
    required this.selectedPays,
    required this.selectedVille,
    required this.onApply,
    required this.onClose,
  });

  @override
  State<_DesktopFilterPanel> createState() => _DesktopFilterPanelState();
}

class _DesktopFilterPanelState extends State<_DesktopFilterPanel> {
  late String _cat;
  late String _pays;
  late String _ville;

  // Catégorie groupe sélectionné pour affichage groupé
  String? _groupeOuvert;

  @override
  void initState() {
    super.initState();
    _cat   = widget.selectedCategorie;
    _pays  = widget.selectedPays;
    _ville = widget.selectedVille;
  }

  List<String> get _villesDisponibles {
    if (_pays == 'Toutes') return ['Toutes'];
    final paysObj = locationData.firstWhere(
      (p) => p.nom == _pays,
      orElse: () => const Pays(id: '', nom: '', drapeau: ''),
    );
    final villes = paysObj.regions
        .expand((r) => r.villes)
        .map((v) => v.nom)
        .toList();
    return ['Toutes', ...villes];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──
            Row(children: [
              Text('Filtres', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() { _cat = 'Toutes'; _pays = 'Toutes'; _ville = 'Toutes'; });
                  widget.onApply('Toutes', 'Toutes', 'Toutes');
                },
                child: Text('Réinitialiser', style: TextStyle(
                  fontSize: 11, color: AppColors.primaryPink, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              ),
            ]),
            Divider(color: AppColors.divider, height: 20),

            // ── PAYS ──
            _label('Pays'),
            const SizedBox(height: 8),
            _LocationDropdown(
              value: _pays,
              items: ['Toutes', ...locationData.map((p) => '${p.drapeau} ${p.nom}')
                  .map((s) => s)
                  .toList()],
              // On affiche juste le nom sans emoji pour la valeur interne
              itemsRaw: ['Toutes', ...locationData.map((p) => p.nom)],
              onChanged: (v) {
                setState(() { _pays = v ?? 'Toutes'; _ville = 'Toutes'; });
                widget.onApply(_cat, _pays, _ville);
              },
            ),

            const SizedBox(height: 14),

            // ── VILLE ──
            _label('Ville'),
            const SizedBox(height: 8),
            _LocationDropdown(
              value: _ville,
              items: _villesDisponibles,
              itemsRaw: _villesDisponibles,
              onChanged: (v) {
                setState(() => _ville = v ?? 'Toutes');
                widget.onApply(_cat, _pays, _ville);
              },
            ),

            const SizedBox(height: 18),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 14),

            // ── CATÉGORIES PAR GROUPE ──
            _label('Catégorie'),
            const SizedBox(height: 10),

            // Chip "Toutes"
            GestureDetector(
              onTap: () {
                setState(() => _cat = 'Toutes');
                widget.onApply(_cat, _pays, _ville);
              },
              child: _FilterChipItem(label: 'Toutes', selected: _cat == 'Toutes'),
            ),

            const SizedBox(height: 10),

            // Groupes accordéon
            ...categoriesParGroupe.map((groupe) {
              final ouvert = _groupeOuvert == groupe.nom;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() =>
                        _groupeOuvert = ouvert ? null : groupe.nom),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Text(groupe.nom, style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.textMuted, letterSpacing: 0.5)),
                        const Spacer(),
                        Icon(
                          ouvert ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 16, color: AppColors.textMuted),
                      ]),
                    ),
                  ),
                  if (ouvert)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 5, runSpacing: 5,
                        children: groupe.categories.map((cat) {
                          final sel = _cat == cat;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _cat = cat);
                              widget.onApply(_cat, _pays, _ville);
                            },
                            child: _FilterChipItem(label: cat, selected: sel),
                          );
                        }).toList(),
                      ),
                    ),
                  Divider(color: AppColors.divider.withOpacity(0.4), height: 1),
                ],
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.6));
}

// ═══════════════════════════════════════════════════════
// Bottom sheet filtre MOBILE
// ═══════════════════════════════════════════════════════
class _FiltreSheet extends StatefulWidget {
  final String selectedCategorie;
  final String selectedPays;
  final String selectedVille;
  final void Function(String, String, String) onApply;

  const _FiltreSheet({
    required this.selectedCategorie,
    required this.selectedPays,
    required this.selectedVille,
    required this.onApply,
  });

  @override
  State<_FiltreSheet> createState() => _FiltreSheetState();
}

class _FiltreSheetState extends State<_FiltreSheet> {
  late String _cat;
  late String _pays;
  late String _ville;
  String? _groupeOuvert;

  @override
  void initState() {
    super.initState();
    _cat   = widget.selectedCategorie;
    _pays  = widget.selectedPays;
    _ville = widget.selectedVille;
  }

  List<String> get _villesDisponibles {
    if (_pays == 'Toutes') return ['Toutes'];
    final paysObj = locationData.firstWhere(
      (p) => p.nom == _pays,
      orElse: () => const Pays(id: '', nom: '', drapeau: ''),
    );
    final villes = paysObj.regions
        .expand((r) => r.villes)
        .map((v) => v.nom)
        .toList();
    return ['Toutes', ...villes];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
          )),
          const SizedBox(height: 16),

          // En-tête fixe
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Filtrer', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _cat = 'Toutes'; _pays = 'Toutes'; _ville = 'Toutes';
                }),
                child: Text('Réinitialiser', style: TextStyle(
                  fontSize: 13, color: AppColors.primaryPink,
                  fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
          Divider(color: AppColors.divider, height: 20, indent: 20, endIndent: 20),

          // Contenu scrollable
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // ── PAYS ──
                _sheetLabel('Pays'),
                const SizedBox(height: 8),
                _LocationDropdown(
                  value: _pays,
                  items: ['Toutes', ...locationData.map((p) => '${p.drapeau} ${p.nom}')],
                  itemsRaw: ['Toutes', ...locationData.map((p) => p.nom)],
                  onChanged: (v) => setState(() {
                    _pays = v ?? 'Toutes'; _ville = 'Toutes';
                  }),
                ),

                const SizedBox(height: 16),

                // ── VILLE ──
                _sheetLabel('Ville'),
                const SizedBox(height: 8),
                _LocationDropdown(
                  value: _ville,
                  items: _villesDisponibles,
                  itemsRaw: _villesDisponibles,
                  onChanged: (v) => setState(() => _ville = v ?? 'Toutes'),
                ),

                const SizedBox(height: 20),
                Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                // ── CATÉGORIES ──
                _sheetLabel('Catégorie'),
                const SizedBox(height: 10),

                // Chip "Toutes"
                GestureDetector(
                  onTap: () => setState(() => _cat = 'Toutes'),
                  child: _FilterChipItem(label: 'Toutes', selected: _cat == 'Toutes'),
                ),
                const SizedBox(height: 10),

                // Groupes accordéon
                ...categoriesParGroupe.map((groupe) {
                  final ouvert = _groupeOuvert == groupe.nom;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() =>
                            _groupeOuvert = ouvert ? null : groupe.nom),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(children: [
                            Text(groupe.nom, style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                            const Spacer(),
                            Icon(
                              ouvert ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              size: 18, color: AppColors.textMuted),
                          ]),
                        ),
                      ),
                      if (ouvert)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: groupe.categories.map((cat) {
                              final sel = _cat == cat;
                              return GestureDetector(
                                onTap: () => setState(() => _cat = cat),
                                child: _FilterChipItem(label: cat, selected: sel),
                              );
                            }).toList(),
                          ),
                        ),
                      Divider(color: AppColors.divider.withOpacity(0.4), height: 1),
                    ],
                  );
                }),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bouton Appliquer fixe en bas
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: () {
                widget.onApply(_cat, _pays, _ville);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryPink, Color(0xFFB68DFF)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Text('Appliquer', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(text, style: const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.5));
}

// ─────────────────────────────────────────────────────────
// Dropdown localisation réutilisable
// ─────────────────────────────────────────────────────────
class _LocationDropdown extends StatelessWidget {
  final String                value;
  final List<String>          items;      // labels affichés (avec emoji)
  final List<String>          itemsRaw;   // valeurs internes (sans emoji)
  final ValueChanged<String?> onChanged;

  const _LocationDropdown({
    required this.value,
    required this.items,
    required this.itemsRaw,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Trouver l'index de la valeur courante dans itemsRaw
    final idx = itemsRaw.indexOf(value);
    final displayValue = idx >= 0 ? items[idx] : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color:        AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.divider),
      ),
      child: DropdownButton<String>(
        value:            displayValue,
        isExpanded:       true,
        underline:        const SizedBox.shrink(),
        dropdownColor:    AppColors.surface,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        icon: const Icon(Icons.expand_more_rounded,
            size: 18, color: AppColors.textMuted),
        items: items.map((label) => DropdownMenuItem(
          value: label,
          child: Text(label,
            style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (label) {
          if (label == null) return;
          final i = items.indexOf(label);
          onChanged(i >= 0 ? itemsRaw[i] : null);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Chip filtre réutilisable (desktop + mobile)
// ─────────────────────────────────────────────────────────
class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool   selected;

  const _FilterChipItem({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryPink.withOpacity(0.15)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.primaryPink.withOpacity(0.5)
              : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected
              ? AppColors.primaryPinkSoft
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Chip filtre actif (tag supprimable)
// ─────────────────────────────────────────────────────────
class _ActiveFilterChip extends StatelessWidget {
  final String       label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        AppColors.primaryPink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color:      AppColors.primaryPinkSoft,
              fontSize:   12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size:  13,
              color: AppColors.primaryPinkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bouton header (refresh, etc.)
// ─────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool     active;

  const _HeaderBtn({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color:        active
            ? AppColors.primaryPink.withOpacity(0.15)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    );
  }
}