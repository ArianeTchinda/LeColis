import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    // Typographies
    final displayFont  = GoogleFonts.cormorantGaramond;
    final bodyFont     = GoogleFonts.dmSans;

    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryPink,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primaryPink,
        secondary: AppColors.accent,
        surface:   AppColors.surface,
        background: AppColors.background,
        onPrimary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: displayFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
      ),

      // Textes
      textTheme: TextTheme(
        displayLarge: displayFont(
          fontSize: 48, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: displayFont(
          fontSize: 36, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        displaySmall: displayFont(
          fontSize: 28, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        headlineLarge: displayFont(
          fontSize: 24, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: 0.5,
        ),
        headlineMedium: displayFont(
          fontSize: 20, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleLarge: bodyFont(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: bodyFont(
          fontSize: 15, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: bodyFont(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.6,
        ),
        bodyMedium: bodyFont(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.5,
        ),
        labelLarge: bodyFont(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: 0.8,
        ),
        labelSmall: bodyFont(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.textMuted, letterSpacing: 0.5,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),
    );
  }
}