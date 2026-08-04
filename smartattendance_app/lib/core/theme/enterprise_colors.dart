// lib/core/theme/enterprise_colors.dart
//
// COMPATIBILITY LAYER: esta clase existió como paleta paralela a AppColors.
// Ahora TODOS los valores delegan en AppColors (fuente única de verdad) para
// que no existan dos azules/textos divergentes. Mantiene la API anterior para
// no tocar los widgets que la usan; el código nuevo debe usar AppColors o la
// extensión ThemeColorsX (colores contextuales por brightness).
import 'package:flutter/material.dart';
import 'app_colors.dart';

class EnterpriseColors {
  // ── Light Mode (Primary) ──────────────────────────────────────
  static const Color bgPrimary = AppColors.background;
  static const Color bgSecondary = AppColors.backgroundSecondary;
  static const Color cardBg = AppColors.surface;
  static const Color borderColor = AppColors.borderColor;

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textTertiary = AppColors.textTertiary;

  // ── Accents ───────────────────────────────────────────────────
  static const Color accentBlue = AppColors.primary;
  static const Color accentBlueDark = AppColors.primaryDark;
  static const Color accentIndigo = AppColors.accentIndigo;
  static const Color accentIndigoDark = AppColors.accentIndigoDark;

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = AppColors.systemGreen;
  static const Color successDark = AppColors.systemGreenDark;
  static const Color warning = AppColors.systemOrange;
  static const Color warningDark = AppColors.systemOrange;
  static const Color error = AppColors.systemRed;
  static const Color errorDark = AppColors.systemRedDark;
  static const Color info = AppColors.systemBlue;

  // ── Light Mode Fallback (sin uso activo; conservado por compatibilidad) ──
  static const Color lightBgPrimary = AppColors.background;
  static const Color lightBgSecondary = AppColors.backgroundSecondary;
  static const Color lightCardBg = AppColors.surface;
  static const Color lightBorder = AppColors.borderColor;
  static const Color lightTextPrimary = AppColors.textPrimary;
  static const Color lightTextSecondary = AppColors.textSecondary;
}
