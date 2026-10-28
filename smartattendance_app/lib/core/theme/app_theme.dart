// ============================================================================
// ARCHIVO: app_theme.dart
// QUÉ HACE: Sistema tipográfico Editorial Profesional + Arquitectura de Modo
//           Oscuro Avanzado (iOS 26 Liquid Glass + Jerarquía de Luminancia).
// CÓMO FUNCIONA:
// 1. `colorScheme.surface` conserva base sólida (`#0B1526`) en modo oscuro para
//    que menús desplegables nativos (`DropdownButton`, `DatePicker`) sean 100%
//    legibles sin superposición de texto.
// 2. `cSurface`, `cGlassSheen` y `cBorder` proveen las 4 capas físicas de
//    Liquid Glass (tinte oscuro, reflejo especular cenital y borde tallado).
// POR QUÉ: Implementa las mejores prácticas avanzadas de Flutter Dark Mode
//          manteniendo < 155 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';
export '../design_system/design_system.dart';

class AppTheme {
  static const String editorialSerif = 'serif';
  static const List<String> editorialFallbacks = ['Georgia', 'Noto Serif', 'Times New Roman', 'serif'];
  static const List<FontFeature> editorialFeatures = [
    FontFeature.enable('kern'),
    FontFeature.enable('liga'),
    FontFeature.tabularFigures(),
  ];

  static ThemeData get lightTheme => _buildTheme(false);
  static ThemeData get darkTheme => _buildTheme(true);

  static ThemeData _buildTheme(bool isDark) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surf = isDark ? const Color(0xFF0B1526) : AppColors.surface;
    final txt = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final txtSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final sep = isDark ? AppColors.darkBorder : AppColors.separator;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamilyFallback: editorialFallbacks,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: isDark ? AppColors.errorDark : AppColors.error,
        onError: Colors.white,
        surface: surf,
        onSurface: txt,
      ),
      scaffoldBackgroundColor: bg,
      canvasColor: surf,
      cardColor: surf,
      textTheme: _buildTextTheme(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF050A14).withValues(alpha: 0.50) : bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          fontFamily: editorialSerif,
          fontFamilyFallback: editorialFallbacks,
          fontFeatures: editorialFeatures,
          color: txt,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.15, fontFeatures: editorialFeatures),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          side: BorderSide(color: sep, width: DesignTokens.borderWidth),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.15, fontFeatures: editorialFeatures),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton), borderSide: BorderSide(color: sep, width: DesignTokens.borderWidth)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton), borderSide: BorderSide(color: sep, width: DesignTokens.borderWidth)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton), borderSide: BorderSide(color: primary, width: 1.4)),
        hintStyle: TextStyle(color: txtSec, fontSize: 13.5),
      ),
      dividerTheme: DividerThemeData(color: sep, thickness: DesignTokens.borderWidth, space: 1),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return TextTheme(
      displayLarge: TextStyle(fontFamily: editorialSerif, fontFamilyFallback: editorialFallbacks, fontFeatures: editorialFeatures, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textColor),
      displayMedium: TextStyle(fontFamily: editorialSerif, fontFamilyFallback: editorialFallbacks, fontFeatures: editorialFeatures, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: textColor),
      headlineLarge: TextStyle(fontFamily: editorialSerif, fontFamilyFallback: editorialFallbacks, fontFeatures: editorialFeatures, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.35, color: textColor),
      headlineMedium: TextStyle(fontFamily: editorialSerif, fontFamilyFallback: editorialFallbacks, fontFeatures: editorialFeatures, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: textColor),
      titleLarge: TextStyle(fontFamily: editorialSerif, fontFamilyFallback: editorialFallbacks, fontFeatures: editorialFeatures, fontSize: 17.5, fontWeight: FontWeight.w700, letterSpacing: -0.25, color: textColor),
      titleMedium: TextStyle(fontFeatures: editorialFeatures, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: textColor),
      bodyLarge: TextStyle(fontFeatures: editorialFeatures, fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.15, height: 1.45, color: textColor),
      bodyMedium: TextStyle(fontFeatures: editorialFeatures, fontSize: 13.5, fontWeight: FontWeight.w400, letterSpacing: -0.1, height: 1.42, color: textColor),
      bodySmall: TextStyle(fontFeatures: editorialFeatures, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: -0.05, height: 1.38, color: secondaryColor),
      labelLarge: TextStyle(fontFeatures: editorialFeatures, fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: textColor),
      labelSmall: TextStyle(fontFeatures: editorialFeatures, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: secondaryColor),
    );
  }
}

extension ThemeColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cPrimary => isDark ? AppColors.primaryDark : AppColors.primary;
  Color get cTextPrimary => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get cTextSecondary => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get cTextTertiary => isDark ? const Color(0xFF7E92AA) : AppColors.textTertiary;
  Color get cSurface => isDark ? const Color(0xFF0C182B).withValues(alpha: 0.52) : AppColors.surface;
  Color get cBackground => isDark ? AppColors.darkBackground : AppColors.background;
  Color get cBackgroundSecondary => isDark ? const Color(0xFF0D1829).withValues(alpha: 0.65) : AppColors.silver;
  Color get cBorder => isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.borderColor;
  Color get cGray => isDark ? AppColors.darkTextSecondary : AppColors.titanium;
  Color get cGray2 => isDark ? const Color(0xFF7E92AA) : AppColors.systemGray2;
  Color get cGray4 => isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.systemGray4;
  Color get cGray5 => isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.systemGray5;
  Color get cWhite => isDark ? const Color(0xFFE2ECF5) : Colors.white;
  LinearGradient get cGradientBackground => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08162B), Color(0xFF040812), Color(0xFF071224)],
        )
      : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cBackground, cBackground]);
}
