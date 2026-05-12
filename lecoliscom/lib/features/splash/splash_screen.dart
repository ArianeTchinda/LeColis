import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/starry_background.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _taglineController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Logo — bounce subtil
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await _exitController.forward();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    // ── Taille du logo splash ────────────────────────────────────────────
    // On veut un logo imposant : ~65 % de la largeur sur mobile, 320dp max.
    // Sur tablette/web on monte à 340dp.
    // La contrainte min garantit qu'il reste lisible sur petits écrans (≥220dp).
    final logoSize = isWide
        ? 340.0
        : (size.width * 0.65).clamp(220.0, 320.0);
    // ────────────────────────────────────────────────────────────────────

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) =>
          Opacity(opacity: _exitOpacity.value, child: child),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Fond étoilé animé
            const StarryBackground(starCount: 130, animated: true),

            // Contenu centré
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ──
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width:  logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:       AppColors.primaryPink.withOpacity(0.35),
                            blurRadius:  80,
                            spreadRadius: 20,
                          ),
                          BoxShadow(
                            color:       AppColors.accent.withOpacity(0.15),
                            blurRadius:  120,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/logos/lecolis_logo.svg',
                        width:  logoSize,
                        height: logoSize,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Nom de la marque ──
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, child) => FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(position: _textSlide, child: child),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.pinkGlow.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'LeColis',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize:   isWide ? 56 : 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Tagline ──
                  AnimatedBuilder(
                    animation: _taglineController,
                    builder: (_, child) =>
                        FadeTransition(opacity: _taglineOpacity, child: child),
                    child: Text(
                      'lecolis.com',
                      style: GoogleFonts.dmSans(
                        fontSize:   isWide ? 15 : 13,
                        fontWeight: FontWeight.w400,
                        color:      AppColors.textMuted,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Indicateur de chargement discret en bas
            Positioned(
              bottom: 48,
              left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _taglineController,
                builder: (_, __) => Opacity(
                  opacity: _taglineOpacity.value,
                  child: Center(
                    child: SizedBox(
                      width: 32, height: 2,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primaryPink),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}