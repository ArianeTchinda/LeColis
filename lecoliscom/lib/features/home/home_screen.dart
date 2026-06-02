import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'widgets/custom_bottom_nav.dart';
import 'tabs/publications/publications_tab.dart';
import 'tabs/abonnements/abonnements_tab.dart';
import 'tabs/profil/profil_tab.dart';
import 'dart:async'; // Nécessaire pour le Timer
import '../../core/constants/app_colors.dart';
import '/core/models/escort_model.dart'; // ← NOUVEAU : pour écouter la session

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _abonnementTabIndex = 0; // index de l'onglet interne d'AbonnementsTab à ouvrir
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  bool _ageVerified = false;

  // Variables pour le "Glitch" Admin
  int _glitchTaps = 0;
  bool _isWaitingForFinalTap = false;
  bool _isTimerRunning = false;
 Timer? _glitchTimer;

  // ← NOUVEAU : session globale pour l'avatar dans le header
  final SessionManager _session = SessionManager();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _searchCtrl.addListener(() {
      _searchQuery.value = _searchCtrl.text.trim();
    });

    // ← NOUVEAU : reconstruire le header à chaque changement de session
    _session.addListener(_onSessionChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgeVerificationDialog();
    });
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChange);
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  void _onSessionChange() {
    if (mounted) setState(() {});
  }

  void _showAgeVerificationDialog() {
    if (_ageVerified) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmation d'âge",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_rounded, size: 60, color: AppColors.primaryPink),
            SizedBox(height: 16),
            Text(
              "LeColis.com est un espace réservé aux adultes.\n\n"
              "Vous devez avoir 18 ans ou plus pour accéder à cette application.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("J'ai moins de 18 ans",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() => _ageVerified = true);
              Navigator.pop(context);
            },
            child: const Text("J'ai plus de 18 ans",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    _fadeCtrl.reverse().then((_) {
      setState(() {
        _currentIndex = index;
        _searchOpen = false;
      });
      _fadeCtrl.forward();
    });
  }

  void _handleLogoTap() {
  // Si on est déjà prêt pour le clic final
  if (_isWaitingForFinalTap) {
    _resetGlitch();
    // Accès à l'écran admin
    Navigator.pushNamed(context, '/lecolis-admin-2025');
    return;
  }

  // Si on clique pendant qu'on est censé attendre 3s -> on réinitialise (échec)
  if (_isTimerRunning) {
    _resetGlitch();
    return;
  }

  setState(() {
    _glitchTaps++;
  });

  // Si on atteint les 5 clics
  if (_glitchTaps == 5) {
    setState(() {
      _isTimerRunning = true;
    });

    // On lance le timer d'attente de 3 secondes
    _glitchTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isTimerRunning = false;
          _isWaitingForFinalTap = true;
        });
        
        // Fenêtre de tir de 2 secondes pour faire le clic final, 
        // sinon ça expire pour plus de sécurité
        _glitchTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _isWaitingForFinalTap) {
            _resetGlitch();
          }
        });
      }
    });
  }
}

void _resetGlitch() {
  _glitchTimer?.cancel();
  setState(() {
    _glitchTaps = 0;
    _isTimerRunning = false;
    _isWaitingForFinalTap = false;
  });
}

  // Basculer sur l'onglet Profil (index 2)
  void _goToProfilTab() {
    _onTabTap(2);
  }

  // Basculer sur l'onglet Abonnements (index 1) + ouvrir un onglet interne
void _goToAbonnement(int tabIndex) {
  setState(() {
    _currentIndex = 1;          // Change l'onglet principal vers "Abonnements"
    _abonnementTabIndex = tabIndex; // 0 pour Plans, 1 pour Mon Abonnement
  });
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      bottomNavigationBar: !isDesktop
          ? CustomBottomNav(currentIndex: _currentIndex, onTap: _onTabTap)
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        CustomBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTap,
        ),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: _buildScrollableContent(true),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: _buildScrollableContent(false),
    );
  }

  Widget _buildScrollableContent(bool isDesktop) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverToBoxAdapter(child: _buildHeader(isDesktop)),
      ],
      body: _buildTab(_currentIndex),
    );
  }

  // ── HEADER — logo + recherche + avatar de profil ─────────────
  Widget _buildHeader(bool isDesktop) {
    double logoHeight  = isDesktop ? 100 : 70;
    double headerHeight = isDesktop ? 120 : 90;

    // ← NOUVEAU : est-ce que l'utilisateur est connecté ?
    final bool connecte = _session.estConnecte;

    return Container(
      height: headerHeight,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 30 : 15),
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        top: !isDesktop,
        child: Row(
          children: [
            // Logo
            // Dans _buildHeader...
if (!_searchOpen || _currentIndex == 2)
  SizedBox(
    height: logoHeight,
    width: isDesktop ? 300 : 200,
    child: OverflowBox(
      maxWidth: double.infinity,
      alignment: Alignment.centerLeft,
      child: Transform.scale(
        scale: 2.5,
        alignment: Alignment.centerLeft,
        // ENTOURER LE LOGO ICI
        child: GestureDetector(
          onTap: _handleLogoTap, // Appel de notre logique
          behavior: HitTestBehavior.opaque, // Pour bien capturer le clic
          child: SvgPicture.asset(
            'assets/logos/lecolis_logo.svg',
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    ),
  ),

            // Barre de recherche (hors tab Profil)
            if (_searchOpen && _currentIndex != 2)
              Expanded(child: _buildSearchBar()),

            const Spacer(),

            // ── Bouton recherche (hors tab Profil)
            if (_currentIndex != 2)
              _HeaderAction(
                icon: Icons.search_rounded,
                onTap: () => setState(() => _searchOpen = true),
              ),

            // ── NOUVEAU : avatar / icône profil quand connecté (hors tab Profil)
            if (connecte && _currentIndex != 2) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _onTabTap(2), // ouvre le tab Profil
                child: _buildAvatarChip(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ← NOUVEAU : petit avatar circulaire avec photo ou initiale
  Widget _buildAvatarChip() {
    final escort = _session.escort;
    final String initiale = (escort?.pseudo.isNotEmpty == true)
        ? escort!.pseudo[0].toUpperCase()
        : '?';

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryPink, width: 2),
        color: AppColors.surfaceElevated,
      ),
      child: ClipOval(
        child: (escort?.photoUrl != null && escort!.photoUrl!.isNotEmpty)
            ? Image.network(
                escort.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialeWidget(initiale),
              )
            : _initialeWidget(initiale),
      ),
    );
  }

  Widget _initialeWidget(String initiale) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initiale,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => setState(() => _searchOpen = false),
        ),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0: return PublicationsTab(searchQuery: _searchQuery);
      // ← MODIFIÉ : on passe onGoToLogin au tab Abonnements
      case 1: return AbonnementsTab(
          key: ValueKey(_abonnementTabIndex), // force rebuild si index change
          searchQuery: _searchQuery,
          onGoToLogin: _goToProfilTab,
          initialTabIndex: _abonnementTabIndex,
        );
      case 2: return ProfilTab(
          onGoToAbonnement: _goToAbonnement,
        );
      default: return const SizedBox.shrink();
    }
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 24, color: AppColors.textPrimary),
    );
  }
}