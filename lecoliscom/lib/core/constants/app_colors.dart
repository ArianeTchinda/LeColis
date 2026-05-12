import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background     = Color(0xFF06060F); // Noir cosmique profond
  static const Color backgroundMid  = Color(0xFF0E0E20); // Couche intermédiaire
  static const Color surface        = Color(0xFF12122A); // Surface carte
  static const Color surfaceElevated= Color(0xFF1C1C3A); // Surface surélevée

  // Brand
  static const Color primaryPink    = Color(0xFFFF5DA8); // Rose vibrant
  static const Color primaryPinkSoft= Color(0xFFFF8FC8); // Rose doux (texte)
  static const Color primaryPinkDim = Color(0x33FF5DA8); // Rose transparent (glow)
  static const Color accent         = Color(0xFFB68DFF); // Violet accent
  static const Color accentDim      = Color(0x22B68DFF); // Violet transparent

  // Text
  static const Color textPrimary    = Color(0xFFF0EEFF); // Blanc chaud
  static const Color textSecondary  = Color(0xFFADACC8); // Gris lavande
  static const Color textMuted      = Color(0xFF6B6A8A); // Gris discret

  // Utility
  static const Color divider        = Color(0xFF1E1E3C);
  static const Color white          = Colors.white;
  static const Color transparent    = Colors.transparent;

  // Gradients prédéfinis
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06060F), Color(0xFF0E0E2A), Color(0xFF06060F)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient pinkGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5DA8), Color(0xFFB68DFF)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A3A), Color(0xFF0E0E22)],
  );
}