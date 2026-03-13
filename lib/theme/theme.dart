import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color background     = Color(0xFF0C0C0E);
  static const Color surface        = Color(0xFF161618);
  static const Color border         = Color(0xFF2A2820);
  static const Color navigateGold   = Color(0xFFE8A020);
  static const Color watchGold      = Color(0xFFC8A850);
  static const Color safeGreen      = Color(0xFF4CAF50);
  static const Color alertRed       = Color(0xFFE53935);
  static const Color textPrimary    = Color(0xFFF0ECE4);
  static const Color textSecondary  = Color(0xFF706860);

  // Panel gradient stops (mode_select_screen)
  static const Color navigatorPanelDark  = Color(0xFF1A1208); // warm dark gold tint
  static const Color companionPanelDark  = Color(0xFF100E18); // cool dark purple tint

}

// ─────────────────────────────────────────────
// TEXT STYLES
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get vidurWordmark => GoogleFonts.cormorantGaramond(
        fontWeight: FontWeight.w600,
        fontSize: 48,
        color: AppColors.textPrimary,
        letterSpacing: 8,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.textPrimary,
      );

  static TextStyle get statusText => GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.navigateGold,
      );

  static TextStyle get pinDisplay => GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w700,
        fontSize: 40,
        color: AppColors.navigateGold,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      );
}

// ─────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  // Padding
  static const double paddingS  = 8.0;
  static const double paddingM  = 16.0;
  static const double paddingL  = 24.0;
  static const double paddingXL = 40.0;

  // Border radius
  static const double radiusS  = 8.0;
  static const double radiusM  = 16.0;
  static const double radiusL  = 24.0;
  static const double radiusXL = 48.0;
}

// ─────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get appTheme => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.navigateGold,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
      );
}
