// ============================================================================
// ARCHIVO: app_theme.dart
// QUÉ HACE: Configuración temática Titanium Enterprise para Flutter (Modo Claro
//           Nieve #F5F7FA / Blanco y Modo Oscuro Grafito #101821 / #192431).
// CÓMO FUNCIONA: Construye `ThemeData` con botones con radio 12-14px, tarjetas 16px,
//                separadores metálicos y extensión `ThemeColorsX` reactiva.
// POR QUÉ: Satisface la identidad Titanium Enterprise con contraste óptimo,
//          accesibilidad y controles de al menos 48x48 dp (< 160 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';
export '../design_system/design_system.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(false);
  static ThemeData get darkTheme => _buildTheme(true);

  static ThemeData _buildTheme(bool isDark) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surf = isDark ? AppColors.darkSurface : AppColors.surface;
    final txt = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final txtSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final sep = isDark ? AppColors.darkBorder : AppColors.separator;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accentIndigo,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surf,
        onSurface: txt,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: _buildTextTheme(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: txt,
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
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
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          side: BorderSide(color: sep, width: DesignTokens.borderWidth),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButton)),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2B3A) : const Color(0xFFFFFFFF),
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
      displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: textColor),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textColor),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.45, color: textColor),
      headlineMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.38, color: textColor),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.34, color: textColor),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: textColor),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: textColor),
      bodyMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, letterSpacing: -0.2, color: textColor),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: -0.15, color: secondaryColor),
      labelLarge: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: secondaryColor),
    );
  }
}

extension ThemeColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cTextPrimary => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get cTextSecondary => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get cTextTertiary => isDark ? const Color(0xFF657486) : AppColors.textTertiary;
  Color get cSurface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get cBackground => isDark ? AppColors.darkBackground : AppColors.background;
  Color get cBackgroundSecondary => isDark ? const Color(0xFF192431) : AppColors.silver;
  Color get cBorder => isDark ? AppColors.darkBorder : AppColors.borderColor;
  Color get cGray => isDark ? AppColors.darkTextSecondary : AppColors.titanium;
  Color get cGray2 => isDark ? const Color(0xFF657486) : AppColors.systemGray2;
  Color get cGray4 => isDark ? AppColors.darkBorder : AppColors.systemGray4;
  Color get cGray5 => isDark ? const Color(0xFF1E2B3A) : AppColors.systemGray5;
  Color get cWhite => isDark ? const Color(0xFFE2ECF5) : Colors.white;

  LinearGradient get cGradientBackground => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [cBackground, cBackground],
      );
}