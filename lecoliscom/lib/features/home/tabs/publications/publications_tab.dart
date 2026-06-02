// lib/features/home/tabs/publications_tab.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/publication_model.dart';
import '../../../../core/data/location_data.dart';
import '../../../../core/data/categories_data.dart';
import '../../../../core/services/publication_service.dart';
import 'widgets/publication_card.dart';
import './screens/publication_detail_screen.dart';

class PublicationsTab extends StatefulWidget {
  final ValueNotifier<String>? searchQuery;
  const PublicationsTab({super.key, this.searchQuery});

  @override
  State<PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends State<PublicationsTab> {
  // ── Données API ────────────────────────────────────────
  List<PublicationModel> _publications = [];
  bool    _loading = false;
  bool    _hasMore = false;
  String? _erreur;
  int     _page   = 1;
  // Snapshot stable de la grille — recalculé UNIQUEMENT après un chargement API
  // pour éviter que le shuffle se relance à chaque setState (tick timer, etc.)
  List<PublicationModel> _gridSnapshot = [];

  // ── Filtres ────────────────────────────────────────────
  String _filtreCategorie = 'Toutes';
  String _filtrePays      = 'Toutes';
  String _filtreRegion    = 'Toutes';
  String _filtreVille     = 'Toutes';
  String _filtreQuartier  = 'Toutes';

 // ── Variables Carrousel ─────────────────────────────────────
final PageController _carouselCtrl = PageController(viewportFraction: 0.78);
int _carouselPage = 0;
Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    widget.searchQuery?.addListener(_onSearchChanged);

    // Charger les données puis démarrer l'autoscroll
    // (attendre les données pour que le carousel ait des items)
    _charger(reset: true).then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll();
        });
      }
    });
  }

  @override
  void dispose() {
    _stopAutoScroll();
    widget.searchQuery?.removeListener(_onSearchChanged);
    _carouselCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  // ── Chargement API ─────────────────────────────────────
  Future<void> _charger({bool reset = false}) async {
    if (_loading) return;
    if (reset) { _page = 1; _publications = []; }
    setState(() { _loading = true; _erreur = null; });
    try {
      final filtre = FiltrePublication(
        categorie: _filtreCategorie == 'Toutes' ? null : _filtreCategorie,
        pays:      _filtrePays      == 'Toutes' ? null : _filtrePays,
        region:    _filtreRegion    == 'Toutes' ? null : _filtreRegion,
        ville:     _filtreVille     == 'Toutes' ? null : _filtreVille,
        page:      _page,
        limite:    20,
      );
      final resultat = await PublicationService.lister(filtre: filtre);
      setState(() {
        _publications = reset
            ? resultat.publications
            : [..._publications, ...resultat.publications];
        _hasMore = resultat.hasMore;
        _page    = _page + 1;
        _loading = false;
        // Recalculer le snapshot de grille UNE SEULE FOIS après chargement
        _gridSnapshot = _buildWeightedShuffledFrom(_publications);
      });
    } catch (e) {
      setState(() { _erreur = 'Impossible de charger les publications.'; _loading = false; });
    }
  }

  /// Nouvelles publications : compte vérifié + expire dans <= 7j
  /// (= créée depuis moins de 7 jours, visible max 7j dans le carrousel)
  // ── CARROUSEL NOUVEAUTÉS — Logique intelligente ─────────────────────
List<PublicationModel> get _nouvelles {
  final now = DateTime.now();

  int _dureeNouveaute(PublicationModel p) {
    final verifie = p.estVerifie;
    switch (p.planType) {
      case PlanType.basique:  return verifie ? 7 : 3;
      case PlanType.standard: return verifie ? 10 : 5;
      case PlanType.premium:  return verifie ? 15 : 7;
      default: return 5;
    }
  }

  return _publications.where((p) {
    if (!p.estActive) return false;

    final dureeNouveaute = _dureeNouveaute(p);

    if (p.createdAt != null) {
      final joursDepuisCreation = now.difference(p.createdAt!).inDays;
      return joursDepuisCreation >= 0 && joursDepuisCreation <= dureeNouveaute;
    }

    // Fallback
    final joursRestants = p.dateExpiration.difference(now).inDays;
    final dureePlan = _dureePlan(p.planType);
    final joursDepuisCreationEstimee = dureePlan - joursRestants;

    return joursDepuisCreationEstimee >= 0 && joursDepuisCreationEstimee <= dureeNouveaute;
  }).take(10).toList();
}

int _dureePlan(PlanType type) {
  switch (type) {
    case PlanType.basique:  return 7;
    case PlanType.standard: return 30;
    case PlanType.premium:  return 30;
    default: return 30;
  }
}

// ── CARROUSEL ISOLÉ (Solution robuste) ─────────────────────
Widget _buildCarousel(List<PublicationModel> items) {
  if (items.isEmpty) return const SizedBox.shrink();

  return SizedBox(
    height: 280,
    child: AbsorbPointer(           // ← Bloque les gestes vers le parent
      absorbing: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Empêche complètement la propagation du scroll
          if (notification is ScrollUpdateNotification) {
            return true; // bloque la propagation
          }
          if (notification is ScrollEndNotification) {
            _resetAutoScroll();
          }
          return false;
        },
        child: PageView.builder(
          controller: _carouselCtrl,
          physics: const BouncingScrollPhysics(), // ou ClampingScrollPhysics()
          itemCount: items.length,
          onPageChanged: (index) {
            setState(() => _carouselPage = index);
            _resetAutoScroll();
          },
          itemBuilder: (_, i) {
            final pub = items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _CarouselCard(
                publication: pub,
                onTap: () => _openDetail(pub),
              ),
            );
          },
        ),
      ),
    ),
  );
}

// ── Dots ───────────────────────────────────────────────
Widget _buildCarouselDots(int count) {
  if (count <= 1) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final sel = i == _carouselPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: sel ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: sel ? AppColors.primaryPink : AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    ),
  );
}

// ── Démarrage / Arrêt du timer ─────────────────────────────
void _startAutoScroll() {
  _autoScrollTimer?.cancel();
  _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
    if (!mounted) return;
    // Ne rien faire si le controller n'est pas encore attaché à un widget
    if (!_carouselCtrl.hasClients) return;

    final itemCount = _nouvelles.isNotEmpty ? _nouvelles.length : _verifies.length;
    if (itemCount <= 1) return;

    final nextPage = (_carouselPage + 1) % itemCount;
    setState(() => _carouselPage = nextPage);

    _carouselCtrl.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOutCubic,
    );
  });
}

void _stopAutoScroll() {
  _autoScrollTimer?.cancel();
}

void _resetAutoScroll() {
  _startAutoScroll();
}



/// Fallback : comptes vérifiés aléatoires (quand il n'y a pas de nouveautés)
List<PublicationModel> get _verifies {
  final uniques = <String, PublicationModel>{};
  for (final p in _publications) {
    if (p.estVerifie && p.estActive) {
      uniques.putIfAbsent(p.escortPseudo, () => p);
    }
  }
  final liste = uniques.values.toList()..shuffle(Random());
  return liste.take(8).toList();
}

  // ── Tri pondéré ────────────────────────────────────────
  // Construit un ordre pondéré et mélangé à partir d'une liste donnée.
  // Appelé UNE SEULE FOIS après chaque chargement API → résultat mis en cache dans _gridSnapshot.
  List<PublicationModel> _buildWeightedShuffledFrom(List<PublicationModel> source) {
    final pool = <PublicationModel>[];
    for (final pub in source) {
      for (int i = 0; i < pub.poidsAffichage; i++) pool.add(pub);
    }
    pool.shuffle(Random());
    final seen   = <String>{};
    final result = <PublicationModel>[];
    for (final pub in pool) { if (seen.add(pub.id)) result.add(pub); }
    return result;
  }

  List<PublicationModel> get _filtered {
    final q    = widget.searchQuery?.value.toLowerCase() ?? '';
    // Utiliser le snapshot stable (calculé une fois après chaque chargement API)
    final base = _gridSnapshot.isEmpty ? _publications : _gridSnapshot;
    if (q.isEmpty) return base;
    return base.where((p) =>
      p.titre.toLowerCase().contains(q)       ||
      p.escortPseudo.toLowerCase().contains(q)||
      p.description.toLowerCase().contains(q) ||
      p.categorie.toLowerCase().contains(q)   ||
      p.ville.toLowerCase().contains(q)       ||
      p.quartier.toLowerCase().contains(q),
    ).toList();
  }

  bool get _hasActiveFilter =>
      _filtreCategorie != 'Toutes' || _filtrePays    != 'Toutes' ||
      _filtreRegion    != 'Toutes' || _filtreVille   != 'Toutes' ||
      _filtreQuartier  != 'Toutes';

  int _columnCount(double width) {
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 650)  return 2;
    return 1;
  }

  void _refresh() {
    // Réinitialiser la page du carrousel avant le rebuild
    // pour éviter que le PageController pointe vers une page inexistante
    _stopAutoScroll();
    _carouselCtrl.jumpToPage(0);
    setState(() {
      _carouselPage    = 0;
      _filtreCategorie = 'Toutes';
      _filtrePays      = 'Toutes';
      _filtreRegion    = 'Toutes';
      _filtreVille     = 'Toutes';
      _filtreQuartier  = 'Toutes';
    });
    _charger(reset: true).then((_) {
      // Relancer l'autoscroll APRÈS que les données sont chargées
      if (mounted) _startAutoScroll();
    });
  }

  void _applyFilter(String cat, String pays, String region, String ville, String quartier) {
    _stopAutoScroll();
    if (_carouselCtrl.hasClients) _carouselCtrl.jumpToPage(0);
    setState(() {
      _carouselPage    = 0;
      _filtreCategorie = cat;
      _filtrePays      = pays;
      _filtreRegion    = region;
      _filtreVille     = ville;
      _filtreQuartier  = quartier;
    });
    _charger(reset: true).then((_) {
      if (mounted) _startAutoScroll();
    });
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

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final width  = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final cols   = _columnCount(width);
    final filtered  = _filtered;
    final nouvelles = _nouvelles;
    final List<PublicationModel> itemsCarrousel = nouvelles.isNotEmpty ? nouvelles : _verifies;

    return CustomScrollView(
      slivers: [
        // ── En-tête titre + refresh ──
        SliverToBoxAdapter(child: _buildHeader(filtered)),

        // ── Filtre permanent ──
        SliverToBoxAdapter(child: _FilterBar(
          selectedCategorie: _filtreCategorie,
          selectedPays:      _filtrePays,
          selectedRegion:    _filtreRegion,
          selectedVille:     _filtreVille,
          selectedQuartier:  _filtreQuartier,
          onApply:           _applyFilter,
          onReset:           _refresh,
          hasActiveFilter:   _hasActiveFilter,
          publications:      _publications,
        )),

        if (itemsCarrousel.isNotEmpty) ...[
  SliverToBoxAdapter(
    child: nouvelles.isNotEmpty
        ? _buildNouveautesHeader(nouvelles.length)
        : _buildVerifiesHeader(_verifies.length),
  ),
  SliverToBoxAdapter(child: _buildCarousel(itemsCarrousel)),
  SliverToBoxAdapter(child: _buildCarouselDots(itemsCarrousel.length)),
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Toutes les annonces',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ]),
    ),
  ),
],

        // ── Grille principale ──
        _buildGridSliver(filtered, cols),
      ],
    );
  }

  // ── En-tête ────────────────────────────────────────────
  Widget _buildHeader(List<PublicationModel> filtered) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Publications',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: 0.5)),
              Text('${filtered.length} annonce${filtered.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _refresh,
          child: _HeaderBtn(icon: Icons.refresh_rounded, active: false),
        ),
      ]),
    );
  }

  // ── Chips filtres actifs ───────────────────────────────
  Widget _buildActiveChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(spacing: 8, children: [
        if (_filtreCategorie != 'Toutes')
          _ActiveFilterChip(label: _filtreCategorie,
            onRemove: () { setState(() => _filtreCategorie = 'Toutes'); _charger(reset: true); }),
        if (_filtrePays != 'Toutes')
          _ActiveFilterChip(label: _filtrePays,
            onRemove: () { setState(() { _filtrePays = 'Toutes'; _filtreRegion = 'Toutes'; _filtreVille = 'Toutes'; _filtreQuartier = 'Toutes'; }); _charger(reset: true); }),
        if (_filtreRegion != 'Toutes')
          _ActiveFilterChip(label: _filtreRegion,
            onRemove: () { setState(() { _filtreRegion = 'Toutes'; _filtreVille = 'Toutes'; _filtreQuartier = 'Toutes'; }); _charger(reset: true); }),
        if (_filtreVille != 'Toutes')
          _ActiveFilterChip(label: _filtreVille,
            onRemove: () { setState(() { _filtreVille = 'Toutes'; _filtreQuartier = 'Toutes'; }); _charger(reset: true); }),
        if (_filtreQuartier != 'Toutes')
          _ActiveFilterChip(label: _filtreQuartier,
            onRemove: () { setState(() => _filtreQuartier = 'Toutes'); _charger(reset: true); }),
      ]),
    );
  }

  // ── Header Nouveautés ─────────────────────────────────
Widget _buildNouveautesHeader(int count) {
  return GestureDetector(
    onTap: () {
      _stopAutoScroll();                    // Pause le défilement
      // Reprend automatiquement après 8 secondes
      Future.delayed(const Duration(seconds: 8), _startAutoScroll);
    },
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryPink, Color(0xFFB68DFF)]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('NEW',
            style: TextStyle(color: Colors.white, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
        const SizedBox(width: 10),
        Text('Nouveautés',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text('· $count',
          style: const TextStyle(fontSize: 13,
            color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ── Header Comptes Vérifiés ─────────────────────────────
Widget _buildVerifiesHeader(int count) {
  return GestureDetector(
    onTap: () {
      _stopAutoScroll();
      Future.delayed(const Duration(seconds: 8), _startAutoScroll);
    },
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5DB8FF), Color(0xFFB68DFF)]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('✓ VERIFIED',
            style: TextStyle(color: Colors.white, fontSize: 9,
              fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
        const SizedBox(width: 10),
        Text('Comptes vérifiés',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text('· $count',
          style: const TextStyle(fontSize: 13,
            color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}


  // ── Grille / liste ─────────────────────────────────────
  Widget _buildGridSliver(List<PublicationModel> filtered, int cols) {
    if (_loading && _publications.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(
          strokeWidth: 2, color: AppColors.primaryPink)));
    }
    if (_erreur != null && _publications.isEmpty) {
      return SliverFillRemaining(child: Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(_erreur!, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _charger(reset: true),
            child: const Text('Réessayer',
              style: TextStyle(color: AppColors.primaryPink,
                fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      )));
    }
    if (filtered.isEmpty) {
      return SliverFillRemaining(child: Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Aucune publication trouvée',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _refresh,
            child: const Text('Réinitialiser les filtres',
              style: TextStyle(color: AppColors.primaryPink,
                fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      )));
    }

    final padding = EdgeInsets.fromLTRB(16, 16, 16, cols == 1 ? 120 : 40);
    final itemCount = filtered.length + (_hasMore ? 1 : 0);

    if (cols == 1) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i == filtered.length) return _buildLoadMoreButton();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PublicationCard(
                  publication: filtered[i],
                  allPublications: _publications,
                  onTap: () => _openDetail(filtered[i]),
                ),
              );
            },
            childCount: itemCount,
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
          (_, i) {
            if (i == filtered.length) return _buildLoadMoreButton();
            return PublicationCard(
              publication: filtered[i],
              allPublications: _publications,
              onTap: () => _openDetail(filtered[i]),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryPink))
            : GestureDetector(
                onTap: () => _charger(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Text('Charger plus',
                    style: TextStyle(color: AppColors.textSecondary,
                      fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CARTE CARROUSEL NOUVEAUTÉ
// ═══════════════════════════════════════════════════════
class _CarouselCard extends StatelessWidget {
  final PublicationModel publication;
  final VoidCallback     onTap;
  const _CarouselCard({required this.publication, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pub = publication;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          // Image
          Positioned.fill(
            child: Hero(
              tag: 'pub_hero_${pub.id}',
              child: Image.network(
                pub.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.image_not_supported_rounded,
                    color: AppColors.textMuted, size: 40)),
              ),
            ),
          ),

          // Dégradé bas
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [Color(0xF2060610), Color(0x00060610)],
                ),
              ),
            ),
          ),

          // Badge NEW haut gauche
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPink, Color(0xFFB68DFF)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.5),
                  blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Text('✦ NEW',
                style: TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
          ),

          // Badge plan haut droite
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: pub.planColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(
                  color: pub.planColor.withOpacity(0.4),
                  blurRadius: 8)],
              ),
              child: Text(pub.planType.label,
                style: const TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            ),
          ),

          // Contenu bas
          Positioned(
            bottom: 14, left: 14, right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pub.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, height: 1.3,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 6)])),
                const SizedBox(height: 8),
                Row(children: [
                  // Avatar
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: pub.planColor, width: 2)),
                    child: ClipOval(child: Image.network(
                      pub.escortImageProfil, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.person, size: 14, color: Colors.white)),
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Row(children: [
                    Flexible(child: Text(pub.escortPseudo,
                      style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                      overflow: TextOverflow.ellipsis)),
                    if (pub.estVerifie) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                        color: Color(0xFF5DB8FF), size: 13),
                    ],
                  ])),
                  if (pub.tarif != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10)),
                      child: Text('${pub.tarif!.toStringAsFixed(0)} F',
                        style: TextStyle(color: pub.planColor, fontSize: 11,
                          fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(width: 6),
                  // Localisation
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded,
                      size: 11, color: Colors.white60),
                    const SizedBox(width: 2),
                    Text(pub.localisationLabel,
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                  ]),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BARRE DE FILTRE PERMANENTE
// ═══════════════════════════════════════════════════════
class _FilterBar extends StatefulWidget {
  final String selectedCategorie;
  final String selectedPays;
  final String selectedRegion;
  final String selectedVille;
  final String selectedQuartier;
  final void Function(String, String, String, String, String) onApply;
  final VoidCallback onReset;
  final bool hasActiveFilter;
  final List<PublicationModel> publications;

  const _FilterBar({
    required this.selectedCategorie,
    required this.selectedPays,
    required this.selectedRegion,
    required this.selectedVille,
    required this.selectedQuartier,
    required this.onApply,
    required this.onReset,
    required this.hasActiveFilter,
    required this.publications,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String? _groupeCatOuvert;

  // ── Compteurs ─────────────────────────────────────────
  int _countLoc({String? pays, String? region, String? ville, String? quartier}) =>
      widget.publications.where((p) {
        if (pays     != null && pays     != 'Toutes' && p.pays     != pays)     return false;
        if (region   != null && region   != 'Toutes' && p.region   != region)   return false;
        if (ville    != null && ville    != 'Toutes' && p.ville    != ville)    return false;
        if (quartier != null && quartier != 'Toutes' && p.quartier != quartier) return false;
        return true;
      }).length;

  int _countCat(String cat) => cat == 'Toutes'
      ? widget.publications.length
      : widget.publications.where((p) =>
          p.categories.contains(cat) || p.categorie == cat).length;

  int _countGroupe(List<String> cats) {
    final ids = <String>{};
    for (final cat in cats)
      for (final p in widget.publications)
        if (p.categories.contains(cat) || p.categorie == cat) ids.add(p.id);
    return ids.length;
  }

  // ── Listes localisation ───────────────────────────────
  List<String> get _paysList => locationData.map((p) => p.nom).toList();

  List<String> _regionsList(String pays) {
    if (pays == 'Toutes' || pays.isEmpty) return [];
    final p = locationData.firstWhere((p) => p.nom == pays,
        orElse: () => const Pays(id: '', nom: '', drapeau: ''));
    return p.regions.map((r) => r.nom).toList();
  }

  List<String> _villesList(String pays, String region) {
    if (pays.isEmpty || pays == 'Toutes') return [];
    final p = locationData.firstWhere((p) => p.nom == pays,
        orElse: () => const Pays(id: '', nom: '', drapeau: ''));
    if (region.isEmpty || region == 'Toutes')
      return p.regions.expand((r) => r.villes.map((v) => v.nom)).toList();
    final r = p.regions.firstWhere((r) => r.nom == region,
        orElse: () => Region(id: '', nom: '', villes: []));
    return r.villes.map((v) => v.nom).toList();
  }

  List<String> _quartiersList(String ville) {
    if (ville.isEmpty || ville == 'Toutes') return [];
    for (final p in locationData)
      for (final r in p.regions)
        for (final v in r.villes)
          if (v.nom == ville) return v.quartiers.map((q) => q.nom).toList();
    return [];
  }

  // ── Bottom sheet localisation ─────────────────────────
  Future<void> _ouvrirLocSheet(
    BuildContext context, {
    required String            label,
    required List<String>      options,
    required String            valeurActuelle,
    required int Function(String) counter,
    required void Function(String) onSelect,
  }) async {
    if (options.isEmpty) return;
    final choix = await showModalBottomSheet<String>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _LocSheet(
        label:          label,
        options:        options,
        valeurActuelle: valeurActuelle,
        counter:        counter,
      ),
    );
    if (choix != null) onSelect(choix);
  }

  @override
  Widget build(BuildContext context) {
    final pays     = widget.selectedPays;
    final region   = widget.selectedRegion;
    final ville    = widget.selectedVille;
    final quartier = widget.selectedQuartier;
    final cat      = widget.selectedCategorie;

    final regions   = _regionsList(pays);
    final villes    = _villesList(pays, region);
    final quartiers = _quartiersList(ville);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ══ BLOC LOCALISATION 2×2 ═══════════════════════════
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Column(children: [
            Row(children: [
              // Pays
              Expanded(child: _LocField(
                label:   'Pays',
                valeur:  pays == 'Toutes' ? '' : pays,
                hint:    'Tous les pays',
                enabled: true,
                count:   pays == 'Toutes' ? null : _countLoc(pays: pays),
                onTap: () => _ouvrirLocSheet(context,
                  label:          'Pays',
                  options:        _paysList,
                  valeurActuelle: pays,
                  counter:        (v) => _countLoc(pays: v),
                  onSelect:       (v) => widget.onApply(cat, v, 'Toutes', 'Toutes', 'Toutes'),
                ),
              )),
              const SizedBox(width: 10),
              // Région
              Expanded(child: _LocField(
                label:   'Région',
                valeur:  region == 'Toutes' ? '' : region,
                hint:    pays == 'Toutes' ? '— pays d\'abord' : 'Toutes les régions',
                enabled: pays != 'Toutes' && regions.isNotEmpty,
                count:   region == 'Toutes' ? null : _countLoc(pays: pays, region: region),
                onTap: () => _ouvrirLocSheet(context,
                  label:          'Région',
                  options:        regions,
                  valeurActuelle: region,
                  counter:        (v) => _countLoc(pays: pays, region: v),
                  onSelect:       (v) => widget.onApply(cat, pays, v, 'Toutes', 'Toutes'),
                ),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              // Ville
              Expanded(child: _LocField(
                label:   'Ville',
                valeur:  ville == 'Toutes' ? '' : ville,
                hint:    region == 'Toutes' ? '— région d\'abord' : 'Toutes les villes',
                enabled: pays != 'Toutes' && villes.isNotEmpty,
                count:   ville == 'Toutes' ? null : _countLoc(pays: pays, region: region, ville: ville),
                onTap: () => _ouvrirLocSheet(context,
                  label:          'Ville',
                  options:        villes,
                  valeurActuelle: ville,
                  counter:        (v) => _countLoc(pays: pays, region: region, ville: v),
                  onSelect:       (v) => widget.onApply(cat, pays, region, v, 'Toutes'),
                ),
              )),
              const SizedBox(width: 10),
              // Quartier
              Expanded(child: _LocField(
                label:   'Quartier',
                valeur:  quartier == 'Toutes' ? '' : quartier,
                hint:    ville == 'Toutes' ? '— ville d\'abord' : 'Optionnel',
                enabled: ville != 'Toutes' && quartiers.isNotEmpty,
                count:   quartier == 'Toutes' ? null
                    : _countLoc(pays: pays, region: region, ville: ville, quartier: quartier),
                onTap: () => _ouvrirLocSheet(context,
                  label:          'Quartier',
                  options:        quartiers,
                  valeurActuelle: quartier,
                  counter:        (v) => _countLoc(pays: pays, region: region, ville: ville, quartier: v),
                  onSelect:       (v) => widget.onApply(cat, pays, region, ville, v),
                ),
              )),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // ══ GROUPES CATÉGORIES — ligne horizontale ═══════════
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categoriesParGroupe.map((groupe) {
              final ouvert    = _groupeCatOuvert == groupe.nom;
              final grpCount  = _countGroupe(groupe.categories);
              final hasActive = groupe.categories.contains(cat);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() =>
                      _groupeCatOuvert = ouvert ? null : groupe.nom),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (ouvert || hasActive)
                          ? AppColors.primaryPink.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (ouvert || hasActive)
                            ? AppColors.primaryPink.withOpacity(0.4)
                            : AppColors.divider,
                        width: (ouvert || hasActive) ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(groupe.nom, style: TextStyle(
                        fontSize: 12,
                        fontWeight: (ouvert || hasActive) ? FontWeight.w600 : FontWeight.w400,
                        color: (ouvert || hasActive)
                            ? AppColors.primaryPink
                            : AppColors.textSecondary,
                      )),
                      if (grpCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: (ouvert || hasActive)
                                ? AppColors.primaryPink.withOpacity(0.15)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$grpCount', style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: (ouvert || hasActive)
                                ? AppColors.primaryPink : AppColors.textMuted,
                          )),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        ouvert ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 13,
                        color: (ouvert || hasActive)
                            ? AppColors.primaryPink : AppColors.textMuted,
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Catégories du groupe ouvert
        if (_groupeCatOuvert != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryPink.withOpacity(0.2)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: () {
                final groupe = categoriesParGroupe.firstWhere(
                  (g) => g.nom == _groupeCatOuvert,
                  orElse: () => CategorieGroupe(nom: '', categories: []),
                );
                return groupe.categories.map((c) {
                  final n   = _countCat(c);
                  final sel = c == cat;
                  return GestureDetector(
                    onTap: () {
                      widget.onApply(
                          sel ? 'Toutes' : c, pays, region, ville, quartier);
                      if (sel) setState(() => _groupeCatOuvert = null);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primaryPink.withOpacity(0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppColors.primaryPink.withOpacity(0.5)
                              : AppColors.divider),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c, style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppColors.primaryPinkSoft : AppColors.textSecondary,
                        )),
                        if (n > 0) ...[
                          const SizedBox(width: 4),
                          Text('($n)', style: TextStyle(
                            fontSize: 10,
                            color: sel
                                ? AppColors.primaryPink.withOpacity(0.7)
                                : AppColors.textMuted,
                          )),
                        ],
                      ]),
                    ),
                  );
                }).toList();
              }(),
            ),
          ),
        ],

        // ── Reset + chips actifs ──────────────────────────
        if (widget.hasActiveFilter) ...[
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: widget.onReset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.close_rounded, size: 12, color: AppColors.primaryPink),
                  SizedBox(width: 4),
                  Text('Réinitialiser', style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: AppColors.primaryPink)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  if (cat      != 'Toutes') _ActiveFilterChip(label: cat,
                    onRemove: () => widget.onApply('Toutes', pays, region, ville, quartier)),
                  if (pays     != 'Toutes') _ActiveFilterChip(label: pays,
                    onRemove: () => widget.onApply(cat, 'Toutes', 'Toutes', 'Toutes', 'Toutes')),
                  if (region   != 'Toutes') _ActiveFilterChip(label: region,
                    onRemove: () => widget.onApply(cat, pays, 'Toutes', 'Toutes', 'Toutes')),
                  if (ville    != 'Toutes') _ActiveFilterChip(label: ville,
                    onRemove: () => widget.onApply(cat, pays, region, 'Toutes', 'Toutes')),
                  if (quartier != 'Toutes') _ActiveFilterChip(label: quartier,
                    onRemove: () => widget.onApply(cat, pays, region, ville, 'Toutes')),
                ]),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CHAMP LOCALISATION — style publication_form_screen
// ═══════════════════════════════════════════════════════
class _LocField extends StatelessWidget {
  final String    label;
  final String    valeur;
  final String    hint;
  final bool      enabled;
  final int?      count;
  final VoidCallback onTap;

  const _LocField({
    required this.label,
    required this.valeur,
    required this.hint,
    required this.enabled,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = valeur.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary)),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.surfaceElevated
                : AppColors.surfaceElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasValue
                  ? AppColors.primaryPink.withOpacity(0.45)
                  : AppColors.divider,
              width: hasValue ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Expanded(child: Text(
              hasValue ? valeur : hint,
              style: TextStyle(
                fontSize: 12,
                color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            )),
            if (hasValue && count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count', style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: AppColors.primaryPink)),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              enabled ? Icons.expand_more_rounded : Icons.lock_outline_rounded,
              size: 14,
              color: hasValue ? AppColors.primaryPink : AppColors.textMuted,
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════
// BOTTOM SHEET SÉLECTION LOCALISATION avec compteurs
// ═══════════════════════════════════════════════════════
class _LocSheet extends StatefulWidget {
  final String              label;
  final List<String>        options;
  final String              valeurActuelle;
  final int Function(String) counter;

  const _LocSheet({
    required this.label,
    required this.options,
    required this.valeurActuelle,
    required this.counter,
  });

  @override
  State<_LocSheet> createState() => _LocSheetState();
}

class _LocSheetState extends State<_LocSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.options);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? List.from(widget.options)
            : widget.options.where((o) => o.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Poignée
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
        ),
        // Titre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Text(widget.label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted)),
          ]),
        ),
        // Barre recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus:  true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher ${widget.label.toLowerCase()}…',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),
        // Option "Toutes"
        InkWell(
          onTap: () => Navigator.pop(context, 'Toutes'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              const Icon(Icons.select_all_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 12),
              const Expanded(child: Text('Toutes', style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
              _CountBadge(count: widget.counter('Toutes')),
            ]),
          ),
        ),
        Divider(color: AppColors.divider.withOpacity(0.5), height: 1),
        // Liste options
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final opt = _filtered[i];
              final n   = widget.counter(opt);
              final sel = opt == widget.valeurActuelle;
              return InkWell(
                onTap: () => Navigator.pop(context, opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  color: sel
                      ? AppColors.primaryPink.withOpacity(0.07)
                      : Colors.transparent,
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Text(opt, style: TextStyle(
                      fontSize: 13,
                      color:      sel ? AppColors.primaryPink : AppColors.textPrimary,
                      fontWeight: sel ? FontWeight.w600       : FontWeight.w400,
                    ))),
                    _CountBadge(count: n, selected: sel),
                    if (sel) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.primaryPink),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }
}

// Badge compteur réutilisable
class _CountBadge extends StatelessWidget {
  final int  count;
  final bool selected;
  const _CountBadge({required this.count, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryPink.withOpacity(0.12)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8)),
      child: Text('$count', style: TextStyle(
        fontSize: 11,
        color:      selected ? AppColors.primaryPink : AppColors.textMuted,
        fontWeight: FontWeight.w500)),
    );
  }
}


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
              : AppColors.divider),
      ),
      child: Text(label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.primaryPinkSoft : AppColors.textSecondary,
        )),
    );
  }
}

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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
          style: const TextStyle(color: AppColors.primaryPinkSoft,
            fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 13,
            color: AppColors.primaryPinkSoft)),
      ]),
    );
  }
}

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