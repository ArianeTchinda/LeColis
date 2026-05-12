import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'widgets/custom_bottom_nav.dart';
import 'tabs/publications/publications_tab.dart';
import 'tabs/abonnements/abonnements_tab.dart';
import 'tabs/profil/profil_tab.dart';
import '../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  bool _ageVerified = false; // Pour éviter d'afficher plusieurs fois
  
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

    // ← NOUVEAU : Affichage de la popup d'âge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgeVerificationDialog();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    _searchQuery.dispose();
    super.dispose();
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
          // Bouton MOINS DE 18 ANS → Ferme la HomeScreen
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();           // Ferme la popup
              Navigator.of(context).pop();           // Ferme la HomeScreen
            },
            child: const Text("J'ai moins de 18 ans", 
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ),

          // Bouton PLUS DE 18 ANS → Reste sur l'application
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() => _ageVerified = true);
              Navigator.pop(context); // Ferme uniquement la popup
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
        _searchOpen = false; // Ferme la recherche au changement d'onglet
      });
      _fadeCtrl.forward();
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

  // --- STRUCTURE DESKTOP ---
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

  // --- STRUCTURE MOBILE ---
  Widget _buildMobileLayout() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: _buildScrollableContent(false),
    );
  }

  // --- ZONE DE CONTENU ---
  Widget _buildScrollableContent(bool isDesktop) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverToBoxAdapter(child: _buildHeader(isDesktop)),
      ],
      body: _buildTab(_currentIndex),
    );
  }

  // --- HEADER (MODIFIÉ : Cloche supprimée) ---
  Widget _buildHeader(bool isDesktop) {
    double logoHeight = isDesktop ? 100 : 70; 
    double headerHeight = isDesktop ? 120 : 90;

    return Container(
      height: headerHeight,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 30 : 15),
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        top: !isDesktop, 
        child: Row(
          children: [
            // Logo toujours visible
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
                    child: SvgPicture.asset(
                      'assets/logos/lecolis_logo.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
            // Barre de recherche (uniquement hors tab Profil)
            if (_searchOpen && _currentIndex != 2)
              Expanded(child: _buildSearchBar()),
            const Spacer(),
            // Bouton recherche masqué sur le tab Profil
            if (_currentIndex != 2)
              _HeaderAction(
                icon: Icons.search_rounded,
                onTap: () => setState(() => _searchOpen = true),
              ),
          ],
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
      case 1: return AbonnementsTab(searchQuery: _searchQuery);
      case 2: return const ProfilTab();
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