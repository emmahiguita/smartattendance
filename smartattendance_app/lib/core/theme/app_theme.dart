// ============================================================================
// ARCHIVO: app_theme.dart
// QUÉ HACE: Configura tipografía, contraste, controles Material 3 / Cupertino y
//           transiciones de página nativas estilo Apple iOS en toda la app.
// CÓMO FUNCIONA: Define temas claro y oscuro (#000000 OLED) con botones, campos,
//                divisores de 0.5px y `CupertinoPageTransitionsBuilder` global.
// POR QUÉ: Garantiza estética y física de navegación iOS profesional sin cambiar
//          colores, íconos ni jerarquía visual (< 200 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
export '../design_system/design_system.dart';
export 'theme_colors.dart';

class AppTheme {
  static const String? fontSans = null;
  static const String? editorialSerif = null;
  static const List<String> iosFontFallbacks = [
    '-apple-system',
    'BlinkMacSystemFont',
    'SF Pro Text',
    'SF Pro Display',
    'Roboto',
    'sans-serif',
  ];
  static const List<String> editorialFallbacks = iosFontFallbacks;
  static const List<FontFeature> editorialFeatures = [
    FontFeature.enable('kern'),
    FontFeature.enable('liga'),
    FontFeature.tabularFigures(),
  ];

  // QUÉ HACE: Aplica transición horizontal con paralaje estilo iOS en todas las plataformas.
  // CÓMO: Mapea cada TargetPlatform a CupertinoPageTransitionsBuilder.
  // POR QUÉ: Unifica el desplazamiento lateral fluido y gesto de retroceso estilo iPhone.
  static const PageTransitionsTheme _iosPageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme => _buildTheme(false);
  static ThemeData get darkTheme => _buildTheme(true);

  static ThemeData _buildTheme(bool isDark) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surf = isDark ? AppColors.darkSurface : AppColors.surface;
    final txt = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final txtSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final sep = isDark ? AppColors.darkBorder : AppColors.separator;
    final primary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final onPrimary = isDark ? Colors.black : Colors.white;

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _iosPageTransitions,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: primary,
        scaffoldBackgroundColor: bg,
        barBackgroundColor: bg,
      ),
      iconTheme: IconThemeData(color: txt),
      listTileTheme: ListTileThemeData(iconColor: txtSec, textColor: txt),
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamilyFallback: editorialFallbacks,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        onSecondary: onPrimary,
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
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: txt),
        titleTextStyle: TextStyle(
          fontFamilyFallback: iosFontFallbacks,
          fontFeatures: editorialFeatures,
          color: txt,
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            fontFeatures: editorialFeatures,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            fontFeatures: editorialFeatures,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: txt,
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          side: BorderSide(color: sep, width: DesignTokens.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            fontFeatures: editorialFeatures,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          borderSide: BorderSide(color: sep, width: DesignTokens.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          borderSide: BorderSide(color: sep, width: DesignTokens.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          borderSide: BorderSide(color: primary, width: 1.0),
        ),
        hintStyle: TextStyle(color: txtSec, fontSize: 13),
        labelStyle: TextStyle(color: txtSec, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: sep,
        thickness: 0.5,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool dark) {
    final primary = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondary =
        dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    TextStyle style(double size, FontWeight weight, {bool muted = false}) =>
        TextStyle(
          fontFamilyFallback: iosFontFallbacks,
          fontFeatures: editorialFeatures,
          fontSize: size,
          fontWeight: weight,
          height: 1.35,
          color: muted ? secondary : primary,
        );
    return TextTheme(
      displayLarge: style(28, FontWeight.w700),
      displayMedium: style(24, FontWeight.w700),
      headlineLarge: style(20, FontWeight.w700),
      headlineMedium: style(18, FontWeight.w600),
      titleLarge: style(17, FontWeight.w600),
      titleMedium: style(15, FontWeight.w600),
      bodyLarge: style(15, FontWeight.w400),
      bodyMedium: style(13.5, FontWeight.w400),
      bodySmall: style(12, FontWeight.w400, muted: true),
      labelLarge: style(13.5, FontWeight.w600),
      labelSmall: style(11.5, FontWeight.w600, muted: true),
    );
  }
}
