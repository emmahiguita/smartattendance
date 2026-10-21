import 'package:flutter/material.dart';
import 'app_colors.dart';
export '../design_system/design_system.dart';

// enterprise_colors.dart se conserva como referencia histórica.
// AppTheme ahora usa AppColors (fuente única de verdad).

/// Tema de la aplicación: Light + Dark mode
/// Paleta corporativa SmartAttendance — unificada con AppColors.
class AppTheme {
  // ── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentIndigo,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.systemRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(false),
      appBarTheme: _buildAppBarTheme(false),
      elevatedButtonTheme: _buildElevatedButtonTheme(false),
      outlinedButtonTheme: _buildOutlinedButtonTheme(false),
      inputDecorationTheme: _buildInputDecorationTheme(false),
      // Navegación inferior (Inicio/Perfil): iconos 24dp coloreados por
      // estado — seleccionado en primary, inactivo en gris. Funciona en
      // light y dark (los colores vienen del colorScheme del tema).
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF94A3B8),
        selectedIconTheme: IconThemeData(size: 24, color: AppColors.primary),
        unselectedIconTheme: IconThemeData(size: 24, color: Color(0xFF94A3B8)),
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      // Separadores profesionales: un solo divisor sutil para todos los
      // Divider sin color explícito (evita líneas claras "horribles").
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ── DARK THEME ───────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentIndigo,
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        error: AppColors.systemRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: _buildTextTheme(true),
      appBarTheme: _buildAppBarTheme(true),
      elevatedButtonTheme: _buildElevatedButtonTheme(true),
      outlinedButtonTheme: _buildOutlinedButtonTheme(true),
      inputDecorationTheme: _buildInputDecorationTheme(true),
      // Navegación inferior en dark: iconos claros inactivos sobre superficie
      // oscura (mismo mapeo que light, colores adaptados al brillo).
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF64748B),
        selectedIconTheme: IconThemeData(size: 24, color: AppColors.primary),
        unselectedIconTheme: IconThemeData(size: 24, color: Color(0xFF64748B)),
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      // Separadores profesionales en dark: gris pizarra, nunca blanco.
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ── TYPOGRAPHY ───────────────────────────────────────────────
  static TextTheme _buildTextTheme(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor =
        isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.56,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.48,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.36,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.28,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.12,
        color: secondaryColor,
      ),
    );
  }

  // ── APP BAR THEME ────────────────────────────────────────────
  static AppBarTheme _buildAppBarTheme(bool isDark) {
    return AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        // Bug fix: antes ambos ramos del ternario eran iguales (textPrimary),
        // lo que dejaba el título invisible en dark mode.
        color: isDark ? const Color(0xFFF1F5F9) : AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.36,
      ),
      surfaceTintColor: Colors.transparent,
    );
  }

  // ── BUTTON THEMES ────────────────────────────────────────────
  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.32,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.32,
        ),
      ),
    );
  }

  // ── INPUT DECORATION ─────────────────────────────────────────
  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      // Bug fix: antes usaba backgroundSecondary (gris claro) también en dark.
      fillColor: isDark ? const Color(0xFF0F172A) : AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        borderSide: const BorderSide(color: AppColors.systemRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        borderSide: const BorderSide(color: AppColors.systemRed, width: 2),
      ),
      // Bug fix: hint y label usaban el mismo color en ambos modos.
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : AppColors.textTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Colores CONTEXTUALES de la aplicación — resuelven según el brillo activo.
///
/// Los widgets deben usar `context.cTextPrimary` (etc.) en vez de las
/// constantes de [AppColors] para texto y fondos: así el dark mode es real
/// y no hay texto oscuro sobre fondo oscuro. [AppColors] queda para colores
/// de marca y semánticos (primary, verde/rojo/ámbar), que sirven en ambos modos.
extension ThemeColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cTextPrimary =>
      isDark ? const Color(0xFFF1F5F9) : AppColors.textPrimary;
  Color get cTextSecondary =>
      isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
  Color get cTextTertiary =>
      isDark ? const Color(0xFF64748B) : AppColors.textTertiary;
  Color get cSurface => isDark ? const Color(0xFF1E293B) : AppColors.surface;
  Color get cBackground =>
      isDark ? const Color(0xFF0F172A) : AppColors.background;
  Color get cBackgroundSecondary =>
      isDark ? const Color(0xFF1E293B) : AppColors.backgroundSecondary;
  Color get cBorder => isDark ? const Color(0xFF334155) : AppColors.borderColor;
  Color get cGray => isDark ? const Color(0xFF94A3B8) : AppColors.systemGray;
  Color get cGray2 => isDark ? const Color(0xFF64748B) : AppColors.systemGray2;
  Color get cGray4 => isDark ? const Color(0xFF334155) : AppColors.systemGray4;
  Color get cGray5 => isDark ? const Color(0xFF1E293B) : AppColors.systemGray5;
  Color get cWhite => isDark ? const Color(0xFFF8FAFC) : Colors.white;

  /// Gradiente de fondo del dashboard — versión oscura en dark mode
  /// (AppColors.gradientBackground es claro fijo y rompía el contraste).
  LinearGradient get cGradientBackground => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        )
      : AppColors.gradientBackground;
}
