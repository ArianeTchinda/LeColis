import 'package:flutter/material.dart';
import 'dart:math';

// Étoile individuelle avec animation de scintillement
class _Star {
  final double x;       // 0..1 relatif à la largeur
  final double y;       // 0..1 relatif à la hauteur
  final double size;
  final double opacity;
  final Duration delay;
  final Duration duration;

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.delay,
    required this.duration,
  });
}

class StarryBackground extends StatefulWidget {
  final int starCount;
  final bool animated;

  const StarryBackground({
    super.key,
    this.starCount = 120,
    this.animated = true,
  });

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with TickerProviderStateMixin {
  late final List<_Star> _stars;
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    final rng = Random(42); // seed fixe = positions stables

    _stars = List.generate(widget.starCount, (i) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.9,
        size: rng.nextDouble() * 2.2 + 0.4,
        opacity: rng.nextDouble() * 0.5 + 0.3,
        delay: Duration(milliseconds: rng.nextInt(4000)),
        duration: Duration(milliseconds: 1800 + rng.nextInt(2400)),
      );
    });

    if (widget.animated) {
      _controllers = _stars.map((s) {
        return AnimationController(vsync: this, duration: s.duration)
          ..repeat(reverse: true);
      }).toList();

      _opacityAnims = List.generate(_stars.length, (i) {
        return Tween<double>(begin: _stars[i].opacity * 0.3, end: _stars[i].opacity)
            .animate(CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut));
      });

      // Décalage des animations
      for (int i = 0; i < _controllers.length; i++) {
        Future.delayed(_stars[i].delay, () {
          if (mounted) _controllers[i].forward();
        });
      }
    } else {
      _controllers = [];
      _opacityAnims = [];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        children: [
          // Gradient de fond cosmique
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.4,
                colors: [
                  Color(0xFF120D2B), // centre violet profond
                  Color(0xFF0A0A1F), // bleu nuit
                  Color(0xFF06060F), // noir absolu
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Nébuleuse rose subtile — coin haut gauche
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5DA8).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Nébuleuse violette — coin bas droit
          Positioned(
            bottom: -60,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFB68DFF).withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Étoiles
          ...List.generate(_stars.length, (i) {
            final star = _stars[i];

            Widget dot = Container(
              width: star.size,
              height: star.size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            );

            if (widget.animated && _opacityAnims.isNotEmpty) {
              dot = AnimatedBuilder(
                animation: _opacityAnims[i],
                builder: (_, child) => Opacity(
                  opacity: _opacityAnims[i].value.clamp(0.0, 1.0),
                  child: child,
                ),
                child: dot,
              );
            } else {
              dot = Opacity(opacity: star.opacity, child: dot);
            }

            return Positioned(
              left: star.x * w,
              top: star.y * h,
              child: dot,
            );
          }),
        ],
      );
    });
  }
}