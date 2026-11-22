// ============================================================================
// ARCHIVO: app_colors.dart
// QUÉ HACE: Define la paleta neutra de alto contraste estilo Apple iOS Pro.
// CÓMO FUNCIONA: Usa negro puro (#000000) para fondo oscuro y tonos metálicos
//                claros/legibles para controles y estados semánticos.
// POR QUÉ: Evita textos oscuros ilegibles sobre fondo negro y elimina bordes
//          azules chillones o franjas amarillas (< 140 líneas).
// ============================================================================

import 'package:flutter/material.dart';

// ignore_for_file: non_constant_identifier_names

abstract final class AppColors {
  // ── Núcleo Metálico BuenTiempo Titanium Enterprise ──
  // Gris platino legible tanto en modo oscuro (#000000) como claro (#FFFFFF)
  // cuando un widget legado referencia AppColors.primary directamente.
  static const Color primary = Color(0xFF94A3B8);
  static const Color primaryDark = Color(0xFFF8FAFC);
  static const Color accent = Color(0xFF94A3B8);
  static const Color graphite = Color(0xFF263445);
  static const Color silver = Color(0xFFDCE2E9);
  static const Color titanium = Color(0xFF8C9BAB);
  static const Color snow = Color(0xFFF5F7FA);

  // ── Semántica de Negocio y Estados (Legibles en Modo Oscuro y Claro) ──
  static const Color success = Color(0xFF34C759); // Verde iOS legible
  static const Color successDark = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A); // Ámbar iOS legible
  static const Color error = Color(0xFFFF3B30);
  static const Color errorDark = Color(0xFFFF453A);
  static const Color systemGreen = success;
  static const Color systemGreenDark = successDark;
  static const Color systemRed = error;
  static const Color systemRedDark = errorDark;
  static const Color systemOrange = warning;
  static const Color systemBlue = primary;
  static const Color accentIndigo = Color(0xFF94A3B8);
  static const Color accentIndigoDark = Color(0xFFE2E8F0);

  // ── Superficies y Fondos Modo Claro ──
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = silver;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color separator = Color(0xFFE2E8F0);

  // ── Tipografía Modo Claro ──
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);

  // ── Modo Oscuro 100% iOS OLED Profesional (#000000) ──
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkBorder = Color(0x2EFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);

  // ── Grises Auxiliares y Compatibilidad ──
  static const Color systemGray = titanium;
  static const Color systemGray2 = Color(0xFF7E8D9D);
  static const Color systemGray3 = Color(0xFFA5B2BF);
  static const Color systemGray4 = Color(0xFFC8D1DC);
  static const Color systemGray5 = Color(0xFFE3E8EE);
  static const Color systemGray6 = Color(0xFFF0F3F7);
  static const Color secondary = accentIndigo;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;
  static const Color outline = borderColor;
  static const Color outlineVariant = systemGray4;
  static const Color surfaceContainerLow = surface;
  static const Color surfaceContainerHighest = systemGray6;
  static const Color primaryFixed = Color(0xFFE2ECF5);
  static const Color secondaryContainer = Color(0xFFE2ECF5);
  static const Color errorContainer = Color(0xFFFDE8E8);

  // ── Gradientes Metálicos Sutiles ──
  static const LinearGradient metallicSteelGradient = LinearGradient(
    colors: [Color(0xFF334155), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient silverSheenGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), silver],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient gradientAttendance = metallicSteelGradient;
  static const LinearGradient gradientQR = metallicSteelGradient;
  static const LinearGradient gradientHistory = LinearGradient(
    colors: [success, Color(0xFF15803D)],
  );
}

abstract final class DesignTokens {
  static const double radiusXS = 6.0;
  static const double radiusSmall = 8.0;
  static const double radiusButton = 10.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 12.0;
  static const double radiusPanel = 14.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusPanelLarge = 20.0;
  static const double radiusPill = 999.0;

  static const double borderWidth = 0.5;
  static const double buttonHeight = 46.0;
  static const double minTouchTargetSize = 44.0;

  static const double spaceXS = 4.0;
  static const double space4 = 4.0;
  static const double spaceS = 8.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double spaceM = 16.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double spaceL = 24.0;
  static const double space24 = 24.0;
  static const double spaceXL = 32.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double spaceXXL = 48.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);

  static List<BoxShadow> get cardShadow => const [];
  static List<BoxShadow> cardShadowColored(Color color) => const [];
}
