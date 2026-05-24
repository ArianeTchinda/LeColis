// lib/features/home/tabs/publications/screens/publication_detail_screen.dart
//
// Corrections v2 :
//  - Mobile/Tablette : image n'est plus collée en haut (padding SafeArea + coins arrondis)
//  - Carousel enveloppé dans un Container arrondi avec margin top
//  - Desktop inchangé (layout éditorial sticky)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/publication_model.dart';
import '../widgets/publication_card.dart';

// ── Breakpoints ──────────────────────────────────────────
// < 700    → mobile   (scroll pleine largeur)
// 700-1099 → tablette (image haut arrondie + contenu 2 col)
// ≥ 1100   → desktop  (image sticky 40% | scroll 60%)

class PublicationDetailScreen extends StatefulWidget {
  final PublicationModel publication;
  final List<PublicationModel> allPublications;

  const PublicationDetailScreen({
    super.key,
    required this.publication,
    required this.allPublications,
  });

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  late PublicationModel _pub;
  late List<PublicationModel> _similaires;
  late PageController _pageCtrl;
  int _currentPage = 0;

  // Header search state (tablette + desktop)
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  // Avis
  late List<AvisModel> _avis;

  @override
  void initState() {
    super.initState();
    _pub        = widget.publication;
    _similaires = _getSimilaires();
    _pageCtrl   = PageController();
    _avis       = mockAvis.where((a) => a.publicationId == _pub.id).toList();
    _searchCtrl.addListener(() {
      _searchQuery.value = _searchCtrl.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _searchCtrl.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  List<PublicationModel> _getSimilaires() {
    final same = widget.allPublications
        .where((p) => p.id != _pub.id && p.categorie == _pub.categorie && p.estActive)
        .toList();
    if (same.length < 4) {
      final autres = widget.allPublications
          .where((p) => p.id != _pub.id && p.categorie != _pub.categorie && p.estActive)
          .take(6 - same.length)
          .toList();
      same.addAll(autres);
    }
    return same.take(6).toList();
  }

  // ── Contacts ───────────────────────────────────────────
  Future<void> _appeler() async {
    final uri = Uri.parse('tel:${_pub.telephone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else _snack('Impossible d\'ouvrir le téléphone');
  }

  Future<void> _whatsapp() async {
    final n   = _pub.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$n');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Impossible d\'ouvrir WhatsApp');
    }
  }

  void _copier() {
    Clipboard.setData(ClipboardData(text: _pub.telephone));
    _snack('Numéro copié !');
  }

  // ← NOUVEAU : ouvrir le client mail
  Future<void> _email() async {
    final adresse = _pub.email;
    if (adresse == null || adresse.isEmpty) return;
    final uri = Uri.parse('mailto:$adresse');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('Impossible d\'ouvrir le client mail');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.surface,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:          const EdgeInsets.all(16),
      duration:        const Duration(seconds: 2),
    ));
  }

  void _ajouterAvis(int note, String message) {
    if (message.trim().isEmpty) return;
    setState(() {
      _avis.insert(0, AvisModel(
        id:            (_avis.length + 100).toString(),
        publicationId: _pub.id,
        note:          note,
        message:       message.trim(),
        createdAt:     DateTime.now(),
      ));
    });
    _snack('Votre avis a été publié');
  }

  void _signalerCompte(SignalementMotif motif, String detail) {
    // TODO: appel API signalement
    _snack('Signalement envoyé à l\'administration');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1100) return _DesktopLayout(screen: this);
    if (width >= 700)  return _TabletLayout(screen: this);
    return _MobileLayout(screen: this);
  }
}

// ═════════════════════════════════════════════════════════
// LAYOUT MOBILE  (<700px)
// ═════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final _PublicationDetailScreenState screen;
  const _MobileLayout({required this.screen});

  @override
  Widget build(BuildContext context) {
    final s      = screen;
    // Mobile : on laisse l'image dicter sa hauteur via BoxFit.contain
    // On donne un max de 70vh pour ne pas envahir tout l'écran
    final maxImgH = MediaQuery.of(context).size.height * 0.70;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _ContactBar(
        onAppel:    s._appeler,
        onWhatsapp: s._whatsapp,
        onEmail:    s._pub.email != null ? s._email : null,
        hasEmail:   s._pub.email != null && s._pub.email!.isNotEmpty,
      ),
      body: CustomScrollView(
        slivers: [
          // ── En-tête identique au HomeScreen (défile avec la page) ──
          SliverToBoxAdapter(child: _DetailHeader(screen: s, horizontalPadding: 15, safeAreaTop: true)),

          // ── Carousel avec marges et coins arrondis ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Stack(
                children: [
                  // Image arrondie — hauteur contrainte, fit contain
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxImgH),
                      child: _ImageCarousel(
                        pub:            s._pub,
                        pageCtrl:       s._pageCtrl,
                        currentPage:    s._currentPage,
                        // ignore: invalid_use_of_protected_member
                        onPageChanged: (i) => s.setState(() => s._currentPage = i),
                        showBottomGradient: false,
                        fitMode: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Bouton retour flottant (positionné dans le Stack, pas dans l'AppBar)
                  Positioned(
                    top: 12, left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color:  Colors.black.withOpacity(0.45),
                          shape:  BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // Badge plan flottant (haut droite)
                  Positioned(
                    top: 12, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:         s._pub.planType.color.withOpacity(0.88),
                        borderRadius:  BorderRadius.circular(20),
                      ),
                      child: Text(
                        s._pub.planType.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EscortHeader(pub: s._pub),
                  const SizedBox(height: 14),
                  _InfoRow(pub: s._pub),
                  const SizedBox(height: 20),
                  _SectionTitle(text: 'Description'),
                  const SizedBox(height: 10),
                  _DescriptionText(text: s._pub.description),
                  const SizedBox(height: 24),
                  _ContactCard(
                    pub:        s._pub,
                    onAppel:    s._appeler,
                    onWhatsapp: s._whatsapp,
                    onCopier:   s._copier,
                    onEmail:    s._email,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Avis + Signalement ──
          ..._avisSliver(s),

          // ── Similaires ──
          ..._similairesSliver(s, cols: 1),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// LAYOUT TABLETTE  (700-1099px)
// ═════════════════════════════════════════════════════════
class _TabletLayout extends StatelessWidget {
  final _PublicationDetailScreenState screen;
  const _TabletLayout({required this.screen});

  @override
  Widget build(BuildContext context) {
    final s   = screen;
    // Tablette : contain avec max 60vh
    final maxImgH = MediaQuery.of(context).size.height * 0.60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── En-tête identique au HomeScreen (défile avec la page) ──
          SliverToBoxAdapter(child: _DetailHeader(screen: s, horizontalPadding: 20)),

          // ── Carousel avec marges et coins arrondis ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxImgH),
                      child: _ImageCarousel(
                        pub:           s._pub,
                        pageCtrl:      s._pageCtrl,
                        currentPage:   s._currentPage,
                        // ignore: invalid_use_of_protected_member
                        onPageChanged: (i) => s.setState(() => s._currentPage = i),
                        showBottomGradient: false,
                        fitMode: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Bouton retour
                  Positioned(
                    top: 12, left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // Badge plan
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:        s._pub.planType.color.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s._pub.planType.label,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu 2 colonnes ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne gauche : infos
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EscortHeader(pub: s._pub),
                        const SizedBox(height: 14),
                        _InfoRow(pub: s._pub),
                        const SizedBox(height: 20),
                        _SectionTitle(text: 'Description'),
                        const SizedBox(height: 10),
                        _DescriptionText(text: s._pub.description),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Colonne droite : contact
                  SizedBox(
                    width: 260,
                    child: _ContactCard(
                      pub:        s._pub,
                      onAppel:    s._appeler,
                      onWhatsapp: s._whatsapp,
                      onCopier:   s._copier,
                      onEmail:    s._email,
                      compact:    true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Avis + Signalement ──
          ..._avisSliver(s),

          // ── Similaires ──
          ..._similairesSliver(s, cols: 2),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
// LAYOUT DESKTOP  (≥1100px)  — éditorial image sticky
// ═════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final _PublicationDetailScreenState screen;
  const _DesktopLayout({required this.screen});

  @override
  Widget build(BuildContext context) {
    final s     = screen;
    final width = MediaQuery.of(context).size.width;
    final imgW  = (width * 0.38).clamp(360.0, 520.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Colonne image sticky pleine hauteur ──
          SizedBox(
            width: imgW,
            child: Stack(
              children: [
                _ImageCarousel(
                  pub:           s._pub,
                  pageCtrl:      s._pageCtrl,
                  currentPage:   s._currentPage,
                  // ignore: invalid_use_of_protected_member
                  onPageChanged: (i) => s.setState(() => s._currentPage = i),
                  showBottomGradient: false,
                ),

                // Dégradé bas
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end:   Alignment.topCenter,
                        colors: [Color(0xF2060610), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Titre en bas de l'image
                Positioned(
                  bottom: 28, left: 20, right: 20,
                  child: Text(
                    s._pub.titre,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize:     26,
                      fontWeight:   FontWeight.w700,
                      color:        Colors.white,
                      height:       1.25,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 12),
                      ],
                    ),
                  ),
                ),

                // Bouton retour
                Positioned(
                  top:  MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Colonne droite scrollable ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── En-tête identique au HomeScreen (défile avec la page) ──
                SliverToBoxAdapter(child: _DetailHeader(screen: s)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(36, 8, 36, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _PlanBadgeLarge(planType: s._pub.planType),
                            const SizedBox(width: 10),
                            _CategoryPill(label: s._pub.categorie),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _EscortHeader(pub: s._pub),
                        const SizedBox(height: 18),
                        _InfoRow(pub: s._pub),
                        const SizedBox(height: 28),
                        _SectionTitle(text: 'Description'),
                        const SizedBox(height: 12),
                        _DescriptionText(text: s._pub.description),
                        const SizedBox(height: 32),
                        _ContactCard(
                          pub:        s._pub,
                          onAppel:    s._appeler,
                          onWhatsapp: s._whatsapp,
                          onCopier:   s._copier,
                          onEmail:    s._email,
                          compact:    true,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                ..._avisSliver(s),

                ..._similairesSliver(s, cols: 2),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CAROUSEL
// ─────────────────────────────────────────────────────────
class _ImageCarousel extends StatelessWidget {
  final PublicationModel  pub;
  final PageController    pageCtrl;
  final int               currentPage;
  final ValueChanged<int> onPageChanged;
  final bool              showBottomGradient;
  final BoxFit            fitMode;

  const _ImageCarousel({
    required this.pub,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.showBottomGradient,
    this.fitMode = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final images    = pub.imageUrls;
    final isContain = fitMode == BoxFit.contain;

    return Stack(
      // contain → loose pour que la hauteur s'adapte à l'image
      fit: isContain ? StackFit.loose : StackFit.expand,
      children: [
        // Fond sombre en mode contain (évite le blanc par défaut)
        if (isContain)
          Positioned.fill(
            child: Container(color: const Color(0xFF08080F)),
          ),

        // PageView
        PageView.builder(
          controller:    pageCtrl,
          itemCount:     images.length,
          onPageChanged: onPageChanged,
          itemBuilder:   (_, i) {
            Widget imgWidget = Image.network(
              images[i],
              fit:   fitMode,
              width: double.infinity,
              // contain : pas de height fixe, l'image choisit la sienne
              errorBuilder: (_, __, ___) => Container(
                height: 260,
                color:  AppColors.surfaceElevated,
                child:  const Icon(Icons.image_not_supported_rounded,
                    color: AppColors.textMuted, size: 48),
              ),
            );
            return i == 0
                ? Hero(tag: 'pub_hero_${pub.id}', child: imgWidget)
                : imgWidget;
          },
        ),

        // Dégradé haut
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [Color(0xAA060610), Colors.transparent],
              ),
            ),
          ),
        ),

        // Dégradé bas (optionnel)
        if (showBottomGradient)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 70,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [Color(0xFF06060F), Colors.transparent],
                ),
              ),
            ),
          ),

        // Badge catégorie — haut droite (décalé sous les boutons)
        Positioned(
          top: 52, right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color:        Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              pub.categorie,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),

        // Compteur images (si >1)
        if (images.length > 1)
          Positioned(
            top: 52, left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 11, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '${currentPage + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Flèches navigation (si >1 image)
        if (images.length > 1) ...[
          if (currentPage > 0)
            Positioned(
              left: 12, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve:    Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          if (currentPage < images.length - 1)
            Positioned(
              right: 12, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve:    Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
        ],

        // Dots indicateurs
        if (images.length > 1)
          Positioned(
            bottom: showBottomGradient ? 14 : 20,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// AVIS SLIVER
// ─────────────────────────────────────────────────────────
List<Widget> _avisSliver(_PublicationDetailScreenState s) {
  return [
    SliverToBoxAdapter(
      child: _AvisSection(
        avis:          s._avis,
        onAjouterAvis: s._ajouterAvis,
        onSignaler:    s._signalerCompte,
        pub:           s._pub,
      ),
    ),
  ];
}

// ─────────────────────────────────────────────────────────
// Similaires sliver
// ─────────────────────────────────────────────────────────
List<Widget> _similairesSliver(
    _PublicationDetailScreenState s, {required int cols}) {
  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          'Publications similaires',
          style: GoogleFonts.cormorantGaramond(
            fontSize:   22,
            fontWeight: FontWeight.w700,
            color:      AppColors.textPrimary,
          ),
        ),
      ),
    ),
    ValueListenableBuilder<String>(
      valueListenable: s._searchQuery,
      builder: (context, query, _) {
        final filtered = query.isEmpty
            ? s._similaires
            : s._similaires.where((p) {
                return p.titre.toLowerCase().contains(query) ||
                    p.categorie.toLowerCase().contains(query) ||
                    p.description.toLowerCase().contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                'Aucune publication similaire pour "$query".',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   cols,
              crossAxisSpacing: 12,
              mainAxisSpacing:  12,
              childAspectRatio: 3 / 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => PublicationCard(
                publication:     filtered[i],
                allPublications: s.widget.allPublications,
              ),
              childCount: filtered.length,
            ),
          ),
        );
      },
    ),
  ];
}

// ═════════════════════════════════════════════════════════
// WIDGETS PARTAGÉS
// ═════════════════════════════════════════════════════════

class _EscortHeader extends StatelessWidget {
  final PublicationModel pub;
  const _EscortHeader({required this.pub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            border: Border.all(color: pub.planType.color, width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              pub.escortImageProfil,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surface,
                child: const Icon(Icons.person, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(pub.escortPseudo,
                      style: const TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.textPrimary,
                      )),
                  if (pub.estVerifie) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF5DB8FF), size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _SmallBadge(
                    label: pub.planType.label,
                    bg:    pub.planType.bgColor,
                    fg:    pub.planType.color,
                  ),
                  const SizedBox(width: 8),
                  _SmallBadge(
                    label: pub.estDisponible ? 'Disponible' : 'Occupée',
                    bg: pub.estDisponible
                        ? const Color(0x2225D366)
                        : const Color(0x22FF5252),
                    fg: pub.estDisponible
                        ? const Color(0xFF25D366)
                        : const Color(0xFFFF5252),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            const Icon(Icons.visibility_outlined,
                color: AppColors.textMuted, size: 16),
            const SizedBox(height: 2),
            Text('${pub.vues}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final PublicationModel pub;
  const _InfoRow({required this.pub});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        _InfoChip(
          icon:  Icons.location_on_rounded,
          label: pub.quartier.isNotEmpty
              ? '${pub.ville} · ${pub.quartier}'
              : pub.ville,
          color: AppColors.accent,
        ),
        if (pub.tarif != null)
          _InfoChip(
            icon:  Icons.payments_outlined,
            label: '${pub.tarif!.toStringAsFixed(0)} FCFA',
            color: pub.planType.color,
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                fontSize:   12,
                color:      AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.cormorantGaramond(
        fontSize:   19,
        fontWeight: FontWeight.w700,
        color:      AppColors.textPrimary,
      ));
}

class _DescriptionText extends StatelessWidget {
  final String text;
  const _DescriptionText({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14, color: AppColors.textSecondary, height: 1.65));
}

class _ContactCard extends StatelessWidget {
  final PublicationModel pub;
  final VoidCallback     onAppel, onWhatsapp, onCopier, onEmail;
  final bool             compact;
  const _ContactCard({
    required this.pub,
    required this.onAppel,
    required this.onWhatsapp,
    required this.onCopier,
    required this.onEmail,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset:     const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.contact_phone_rounded,
                color: AppColors.primaryPink, size: 18),
            SizedBox(width: 8),
            Text('Contacter',
                style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),

          // Numéro + copie
          GestureDetector(
            onTap: onCopier,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color:        AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                const Icon(Icons.phone_outlined,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(pub.telephone,
                      style: const TextStyle(
                          fontSize:     14,
                          color:        AppColors.textPrimary,
                          fontWeight:   FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
                const Icon(Icons.copy_rounded,
                    size: 14, color: AppColors.textMuted),
              ]),
            ),
          ),
          // Email (si renseigné)
          if (pub.email != null && pub.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onEmail,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color:        AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppColors.divider),
                ),
                child: Row(children: [
                  const Icon(Icons.email_outlined, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(pub.email!,
                        style: const TextStyle(
                            fontSize:     13,
                            color:        AppColors.textPrimary,
                            fontWeight:   FontWeight.w500,
                            letterSpacing: 0.3)),
                  ),
                  const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.textMuted),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (compact)
            Column(children: [
              // Appeler + WhatsApp sur une ligne
              Row(children: [
                Expanded(child: _ContactButton(
                    icon: Icons.phone_rounded,
                    label: 'Appeler',
                    color: const Color(0xFF5DB8FF),
                    onTap: onAppel,
                    compact: true)),
                const SizedBox(width: 10),
                Expanded(child: _ContactButton(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: onWhatsapp,
                    compact: true)),
              ]),
              // Email seul en dessous (pleine largeur, évite tout débordement)
              if (pub.email != null && pub.email!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: _ContactButton(
                      icon:  Icons.email_rounded,
                      label: 'Email',
                      color: const Color(0xFFB68DFF),
                      onTap: onEmail,
                      compact: true),
                ),
              ],
            ])
          else ...[
            _ContactButton(
                icon:  Icons.phone_rounded,
                label: 'Appeler maintenant',
                color: const Color(0xFF5DB8FF),
                onTap: onAppel),
            const SizedBox(height: 10),
            _ContactButton(
                icon:  Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: onWhatsapp),
            if (pub.email != null && pub.email!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ContactButton(
                  icon:  Icons.email_rounded,
                  label: 'Envoyer un email',
                  color: const Color(0xFFB68DFF),
                  onTap: onEmail),
            ],
          ],
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  final VoidCallback  onAppel, onWhatsapp;
  final VoidCallback? onEmail;   // ← NOUVEAU (optionnel, null si pas d'email)
  final bool          hasEmail;  // ← NOUVEAU
  const _ContactBar({
    required this.onAppel,
    required this.onWhatsapp,
    this.onEmail,
    this.hasEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: [
        Expanded(
          child: _ContactButton(
              icon:  Icons.phone_rounded,
              label: 'Appeler',
              color: const Color(0xFF5DB8FF),
              onTap: onAppel),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ContactButton(
              icon:  Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: onWhatsapp),
        ),
        if (hasEmail && onEmail != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ContactButton(
                icon:  Icons.email_rounded,
                label: 'Email',
                color: const Color(0xFFB68DFF),
                onTap: onEmail!),
          ),
        ],
      ]),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  final bool         compact;
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 9 : 13),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 15 : 17, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.w700,
                    fontSize:   compact ? 12 : 14)),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color  bg, fg;
  const _SmallBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)));
}

class _PlanBadgeLarge extends StatelessWidget {
  final PlanType planType;
  const _PlanBadgeLarge({required this.planType});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        planType.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: planType.color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (planType == PlanType.premium)
          Icon(Icons.star_rounded, color: planType.color, size: 13),
        if (planType == PlanType.premium) const SizedBox(width: 4),
        Text(planType.label,
            style: TextStyle(
                color:      planType.color,
                fontSize:   12,
                fontWeight: FontWeight.w700)),
      ]));
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Text(label,
          style: const TextStyle(
              color:      AppColors.textSecondary,
              fontSize:   12,
              fontWeight: FontWeight.w500)));
}

// ─────────────────────────────────────────────────────────
// SECTION AVIS
// ─────────────────────────────────────────────────────────
class _AvisSection extends StatefulWidget {
  final List<AvisModel>                          avis;
  final void Function(int note, String message)  onAjouterAvis;
  final void Function(SignalementMotif, String)  onSignaler;
  final PublicationModel                         pub;

  const _AvisSection({
    required this.avis,
    required this.onAjouterAvis,
    required this.onSignaler,
    required this.pub,
  });

  @override
  State<_AvisSection> createState() => _AvisSectionState();
}

class _AvisSectionState extends State<_AvisSection> {
  bool _showForm = false;

  double get _moyenneNote {
    if (widget.avis.isEmpty) return 0;
    return widget.avis.fold(0.0, (s, a) => s + a.note) / widget.avis.length;
  }

  @override
  Widget build(BuildContext context) {
    final moy = _moyenneNote;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête section ──
          Row(children: [
            Text('Avis',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 19, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 10),
            if (widget.avis.isNotEmpty) ...[
              _StarRow(note: moy.round(), size: 14),
              const SizedBox(width: 6),
              Text('${moy.toStringAsFixed(1)} · ${widget.avis.length} avis',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
            const Spacer(),
            // Bouton Signaler discret
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _SignalerSheet(
                  pub:       widget.pub,
                  onSignaler: widget.onSignaler,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 13, color: Colors.red),
                    SizedBox(width: 5),
                    Text('Signaler',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Avis existants ──
          if (widget.avis.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Aucun avis pour l\'instant.',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            )
          else
            ...widget.avis.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AvisCard(avis: a),
            )),

          const SizedBox(height: 4),

          // ── Bouton / Formulaire ajout avis ──
          if (!_showForm)
            GestureDetector(
              onTap: () => setState(() => _showForm = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 15, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text('Laisser un avis',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )
          else
            _AjouterAvisForm(
              onSubmit: (note, msg) {
                widget.onAjouterAvis(note, msg);
                setState(() => _showForm = false);
              },
              onCancel: () => setState(() => _showForm = false),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AvisCard extends StatelessWidget {
  final AvisModel avis;
  const _AvisCard({required this.avis});

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    return 'Il y a $diff jours';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:  AppColors.surfaceElevated,
                shape:  BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 16, color: AppColors.textMuted),
            ),
            const SizedBox(width: 10),
            const Text('Anonyme',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            _StarRow(note: avis.note, size: 13),
            const SizedBox(width: 8),
            Text(_formatDate(avis.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 8),
          Text(avis.message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _AjouterAvisForm extends StatefulWidget {
  final void Function(int note, String message) onSubmit;
  final VoidCallback                            onCancel;
  const _AjouterAvisForm({required this.onSubmit, required this.onCancel});

  @override
  State<_AjouterAvisForm> createState() => _AjouterAvisFormState();
}

class _AjouterAvisFormState extends State<_AjouterAvisForm> {
  int    _note = 5;
  final  TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Votre note',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _note = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  i < _note ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: i < _note
                      ? const Color(0xFFFFB800)
                      : AppColors.textMuted,
                ),
              ),
            )),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color:        AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines:   3,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText:     'Partagez votre expérience...',
                hintStyle:    TextStyle(color: AppColors.textMuted, fontSize: 13),
                border:       InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:        AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Text('Annuler',
                        style: TextStyle(fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onSubmit(_note, _ctrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:        AppColors.primaryPink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(
                        color: AppColors.primaryPink.withOpacity(0.35)),
                  ),
                  child: const Center(
                    child: Text('Publier',
                        style: TextStyle(
                            fontSize: 13,
                            color:      AppColors.primaryPink,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int    note;
  final double size;
  const _StarRow({required this.note, required this.size});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      i < note ? Icons.star_rounded : Icons.star_outline_rounded,
      size:  size,
      color: i < note ? const Color(0xFFFFB800) : AppColors.textMuted,
    )),
  );
}

// ─────────────────────────────────────────────────────────
// BOTTOM SHEET SIGNALEMENT
// ─────────────────────────────────────────────────────────
class _SignalerSheet extends StatefulWidget {
  final PublicationModel                        pub;
  final void Function(SignalementMotif, String) onSignaler;
  const _SignalerSheet({required this.pub, required this.onSignaler});

  @override
  State<_SignalerSheet> createState() => _SignalerSheetState();
}

class _SignalerSheetState extends State<_SignalerSheet> {
  SignalementMotif?          _motif;
  final TextEditingController _detailCtrl = TextEditingController();

  @override
  void dispose() { _detailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize:        MainAxisSize.min,
        crossAxisAlignment:  CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.flag_rounded, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Text('Signaler ce profil',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 6),
          Text('Votre signalement sera traité de façon anonyme par l\'administration.',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 16),

          // Motifs
          ...SignalementMotif.values.map((m) => GestureDetector(
            onTap: () => setState(() => _motif = m),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color:  _motif == m
                    ? Colors.red.withOpacity(0.10)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _motif == m
                      ? Colors.red.withOpacity(0.4)
                      : AppColors.divider,
                ),
              ),
              child: Row(children: [
                Icon(
                  _motif == m
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: _motif == m ? Colors.red : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(m.label,
                    style: TextStyle(
                        fontSize: 13,
                        color: _motif == m
                            ? Colors.red
                            : AppColors.textSecondary,
                        fontWeight: _motif == m
                            ? FontWeight.w600
                            : FontWeight.w400)),
              ]),
            ),
          )),

          const SizedBox(height: 8),

          // Détail optionnel
          Container(
            decoration: BoxDecoration(
              color:        AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _detailCtrl,
              maxLines:   2,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText:       'Détails supplémentaires (optionnel)...',
                hintStyle:      TextStyle(color: AppColors.textMuted, fontSize: 13),
                border:         InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              if (_motif == null) return;
              widget.onSignaler(_motif!, _detailCtrl.text);
              Navigator.pop(context);
            },
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color:        _motif != null
                    ? Colors.red.withOpacity(0.12)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(
                  color: _motif != null
                      ? Colors.red.withOpacity(0.35)
                      : AppColors.divider,
                ),
              ),
              child: Center(
                child: Text('Envoyer le signalement',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _motif != null
                            ? Colors.red
                            : AppColors.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// En-tête partagé (tablette + desktop) — identique HomeScreen
// ─────────────────────────────────────────────────────────
class _DetailHeader extends StatelessWidget {
  final _PublicationDetailScreenState screen;
  final double horizontalPadding;
  final bool safeAreaTop;

  const _DetailHeader({
    required this.screen,
    this.horizontalPadding = 30,
    this.safeAreaTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = screen;
    return Container(
      height: safeAreaTop
          ? 90 + MediaQuery.of(context).padding.top
          : 120,
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: safeAreaTop ? MediaQuery.of(context).padding.top : 0,
      ),
      color: AppColors.background,
      child: Row(
          children: [
            if (s._searchOpen)
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        // ignore: invalid_use_of_protected_member
                        s.setState(() {
                          s._searchOpen = false;
                          s._searchCtrl.clear();
                        });
                      },
                    ),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: s._searchCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: "Rechercher...",
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.primaryPink),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              SizedBox(
                height: 100,
                width: 300,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: Transform.scale(
                    scale: 2.5,
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                      'assets/logos/lecolis_logo.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // ignore: invalid_use_of_protected_member
                  s.setState(() => s._searchOpen = true);
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.search_rounded,
                    size: 24, color: AppColors.textPrimary),
              ),
            ],
          ],
        ),
      );
  }
}