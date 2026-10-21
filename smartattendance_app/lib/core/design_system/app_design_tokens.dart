import 'package:flutter/material.dart';

/// ============================================================================
/// TOKENS DE DISEÑO DEL SISTEMA SMARTATTENDANCE
/// ============================================================================
/// Principios: Precisión, Consistencia, Claridad, Continuidad, Sobriedad y Accesibilidad.
/// Sigue Clean Architecture y SOLID: fuente única de verdad para métricas,
/// tipografía, espaciados, radios y tokens de movimiento.
abstract final class AppDesignTokens {
  // ── SISTEMA DE ESPACIADO (dp) ───────────────────────────────────────────
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  /// Padding horizontal estándar en pantallas móviles (16–20 dp)
  static const double mobileHorizontalPadding = 18.0;

  /// Separación entre secciones del dashboard (24 dp)
  static const double sectionSpacing = 24.0;

  /// Separación entre tarjetas de métricas y listas (12–16 dp)
  static const double cardSpacing = 14.0;

  // ── SISTEMA DE RADIOS (dp) ──────────────────────────────────────────────
  /// Radio de tarjetas (16 dp)
  static const double radiusCard = 16.0;

  /// Radio de botones e inputs (12 dp)
  static const double radiusButton = 12.0;

  /// Radio de paneles grandes y modales (20–24 dp)
  static const double radiusPanel = 20.0;
  static const double radiusPanelLarge = 24.0;

  /// Radio cápsula/píldora
  static const double radiusPill = 999.0;

  // ── BORDES Y ELEVACIÓN ──────────────────────────────────────────────────
  /// Ancho de bordes discretos (1.0 dp)
  static const double borderWidth = 1.0;

  /// Altura mínima de controles táctiles para accesibilidad (48 dp)
  static const double minTouchTargetSize = 48.0;

  // ── TIPOGRAFÍA EMPRESARIAL ──────────────────────────────────────────────
  // Usar cifras tabulares en horarios, indicadores y reportes.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Display: 30–32 sp, semibold
  static TextStyle display({required Color color, double fontSize = 31.0}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: color,
        height: 1.2,
      );

  /// Headline: 24 sp, semibold
  static TextStyle headline({required Color color, double fontSize = 24.0}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: color,
        height: 1.25,
      );

  /// Title: 18–20 sp, semibold
  static TextStyle title({required Color color, double fontSize = 19.0}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
        height: 1.3,
      );

  /// Subtitle: 16 sp, medium
  static TextStyle subtitle({required Color color, double fontSize = 16.0}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: color,
        height: 1.35,
      );

  /// Body: 14–16 sp, regular
  static TextStyle body({required Color color, double fontSize = 15.0}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.15,
        color: color,
        height: 1.45,
      );

  /// Caption: 12–13 sp
  static TextStyle caption({required Color color, double fontSize = 12.5}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: color,
        height: 1.35,
      );

  /// Labels: 12–14 sp, medium
  static TextStyle label({required Color color, double fontSize = 13.0}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color,
        height: 1.3,
      );

  /// Estilo numérico con cifras tabulares para indicadores, horas y reportes
  static TextStyle metricValue({
    required Color color,
    double fontSize = 28.0,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.5,
        color: color,
        height: 1.1,
        fontFeatures: tabularFigures,
      );

  // ── TOKENS DE MOVIMIENTO (Motion Tokens) ─────────────────────────────────
  /// Transición rápida (180–220 ms): tarjetas, microinteracciones
  static const Duration durationFast = Duration(milliseconds: 200);

  /// Transición media (250–350 ms): modales, cambios de filtro
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// Transición compleja o 3D (450–650 ms): flip de tarjeta, rotación perspectiva
  static const Duration durationFlip = Duration(milliseconds: 520);

  /// Transición de confirmación/éxito animado (300–450 ms)
  static const Duration durationSuccess = Duration(milliseconds: 400);

  // Curvas de animación física sobria
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveEntrance = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveFlip = Curves.easeInOutCubic;
  static const Curve curveBounce = Curves.easeOutBack;

  /// Resuelve la duración respetando las preferencias del sistema de reducción de movimiento.
  static Duration resolveDuration(BuildContext context, Duration baseDuration) {
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return baseDuration;
  }
}
