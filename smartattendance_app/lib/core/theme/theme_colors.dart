// ============================================================================
// ARCHIVO: theme_colors.dart
// QUÉ HACE: Extensiones de contexto para resolver colores neutros según el tema.
// CÓMO FUNCIONA: Expone getters adaptativos para texto, fondos, bordes y acentos
//                garantizando contraste blanco sobre #000000 en modo oscuro.
// POR QUÉ: Centraliza tokens semánticos evitando colores oscuros sobre negro.
// ============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';

extension ThemeColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cPrimary =>
      isDark ? AppColors.primaryDark : const Color(0xFF0F172A);
  Color get cTextPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get cTextSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get cTextTertiary =>
      isDark ? const Color(0xFFB0B0B0) : AppColors.textTertiary;
  Color get cSurface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get cBackground =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get cBackgroundSecondary =>
      isDark ? const Color(0xFF181818) : AppColors.silver;
  Color get cBorder =>
      isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.borderColor;
  Color get cGray => isDark ? AppColors.darkTextSecondary : AppColors.titanium;
  Color get cGray2 => isDark ? const Color(0xFFB0B0B0) : AppColors.systemGray2;
  Color get cGray4 =>
      isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.systemGray4;
  Color get cGray5 =>
      isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.systemGray5;
  Color get cWhite => isDark ? const Color(0xFFE2ECF5) : Colors.white;
  LinearGradient get cGradientBackground => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Colors.black],
        )
      : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cBackground, cBackground],
        );
}
