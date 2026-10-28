// ============================================================================
// ARCHIVO: app_colors.dart
// QUÉ HACE: Paleta cromática y tokens del sistema de diseño Titanium Enterprise
//           con Modo Oscuro 100% Apple iOS Liquid Glass Transparente Profesional.
// CÓMO FUNCIONA: Define constantes semánticas de color, superficies translúcidas
//                de cristal esmerilado y bordes especulares para modo oscuro.
// POR QUÉ: Materializa un modo oscuro 100% iOS transparente profesional con
//          máxima legibilidad y estética ejecutiva (< 140 líneas).
// ============================================================================

import 'package:flutter/material.dart';

// ignore_for_file: non_constant_identifier_names

abstract final class AppColors {
  // ── Núcleo Metálico Serviciudad Titanium Enterprise ──
  static const Color primary = Color(0xFF005A9C); // Azul Serviciudad oficial
  static const Color primaryDark = Color(0xFF0A84FF); // Azul iOS Dark Mode luminoso
  static const Color accent = Color(0xFF1598D3); // Celeste agua institucional
  static const Color graphite = Color(0xFF263445); // Grafito / Titanio oscuro
  static const Color silver = Color(0xFFDCE2E9); // Plata satinada
  static const Color titanium = Color(0xFF8C9BAB); // Titanio neutro
  static const Color snow = Color(0xFFF5F7FA); // Nieve (Fondo claro)

  // ── Semántica de Negocio y Estados ──
  static const Color success = Color(0xFF18794E); // Verde empresarial
  static const Color successDark = Color(0xFF30D158); // Verde iOS Dark Mode
  static const Color warning = Color(0xFFA66414); // Ámbar supervisión
  static const Color error = Color(0xFFB93838); // Rojo alerta
  static const Color errorDark = Color(0xFFFF453A); // Rojo iOS Dark Mode
  static const Color systemGreen = success;
  static const Color systemGreenDark = successDark;
  static const Color systemRed = error;
  static const Color systemRedDark = errorDark;
  static const Color systemOrange = warning;
  static const Color systemBlue = primary;
  static const Color accentIndigo = Color(0xFF2A4D6E);
  static const Color accentIndigoDark = Color(0xFF1E3A56);

  // ── Superficies y Fondos Modo Claro ──
  static const Color background = Color(0xFFF6F8FB); // Hielo titanio claro
  static const Color backgroundSecondary = silver; // #DCE2E9
  static const Color surface = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE2E8F0); // Borde metálico sutil
  static const Color separator = Color(0xFFE2E8F0);

  // ── Tipografía Modo Claro ──
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 alta legibilidad
  static const Color textSecondary = Color(0xFF475569); // Slate 600 sobrio
  static const Color textTertiary = Color(0xFF64748B); // Slate 500

  // ── Modo Oscuro 100% iOS Liquid Glass Transparente Profesional ──
  static const Color darkBackground = Color(0xFF050A14); // Obsidiana iOS OLED profunda
  static const Color darkSurface = Color(0xFF101E33); // Cristal oscuro translúcido base
  static const Color darkBorder = Color(0x2EFFFFFF); // Borde especular cristal iOS (18% blanco)
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Blanco cristal iOS
  static const Color darkTextSecondary = Color(0xFFB0C0D4); // Plata translúcido legible

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
    colors: [primary, Color(0xFF234462)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient silverSheenGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), silver],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient gradientAttendance = metallicSteelGradient;
  static const LinearGradient gradientQR = LinearGradient(
    colors: [primary, accentIndigo],
  );
  static const LinearGradient gradientHistory = LinearGradient(
    colors: [success, Color(0xFF125C3B)],
  );
}

abstract final class DesignTokens {
  static const double radiusXS = 6.0;
  static const double radiusSmall = 8.0;
  static const double radiusButton = 12.0;
  static const double radiusMedium = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusPanel = 16.0;
  static const double radiusLarge = 18.0;
  static const double radiusXL = 22.0;
  static const double radiusPanelLarge = 22.0;
  static const double radiusPill = 999.0;

  static const double borderWidth = 0.8;
  static const double buttonHeight = 52.0;
  static const double minTouchTargetSize = 48.0;

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
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static List<BoxShadow> get cardShadow => const [];
  static List<BoxShadow> cardShadowColored(Color color) => const [];
}
