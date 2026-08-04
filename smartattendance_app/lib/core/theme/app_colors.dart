// lib/core/theme/app_colors.dart
//
// FUENTE ÚNICA DE VERDAD para todos los colores de la aplicación.
// Paleta corporativa SmartAttendance — basada en la especificación del PDF.
//
// ANTES: 2 sistemas paralelos (app_colors + enterprise_colors) → 3 azules distintos.
// AHORA: 1 sistema único. enterprise_colors.dart se conserva como referencia histórica.
import 'package:flutter/material.dart';

// ignore_for_file: non_constant_identifier_names

abstract final class AppColors {
  // ══════════════════════════════════════════════════════════════════
  //  COLORES PRIMARIOS — Paleta corporativa (PDF spec)
  // ══════════════════════════════════════════════════════════════════

  /// Azul corporativo principal — Blue 600 (#2563EB)
  /// Uso: botones primarios, iconos activos, links, bordes de foco.
  static const Color primary = Color(0xFF2563EB);

  /// Azul corporativo oscuro — Blue 700 (#1D4ED8)
  /// Uso: gradiente del botón "Marcar Asistencia", estados pressed.
  static const Color primaryDark = Color(0xFF1D4ED8);

  /// Índigo premium — Indigo 500 (#6366F1)
  /// Uso: tarjeta "Escanear QR", accents secundarios.
  static const Color accentIndigo = Color(0xFF6366F1);

  /// Índigo oscuro — Indigo 600 (#4F46E5)
  /// Uso: gradiente de tarjeta QR (estado pressed).
  static const Color accentIndigoDark = Color(0xFF4F46E5);

  // ══════════════════════════════════════════════════════════════════
  //  COLORES SEMÁNTICOS — Estados del sistema (PDF spec)
  // ══════════════════════════════════════════════════════════════════

  /// Verde Emerald 500 — Éxito, entrada registrada, historial.
  static const Color systemGreen = Color(0xFF10B981);

  /// Verde Emerald 600 — Gradiente oscuro de tarjeta Historial.
  static const Color systemGreenDark = Color(0xFF059669);

  /// Rojo Red 500 — Error, salida registrada, destructive actions.
  static const Color systemRed = Color(0xFFEF4444);

  /// Rojo Red 600 — Estado pressed de acciones destructivas.
  static const Color systemRedDark = Color(0xFFDC2626);

  /// Ámbar Amber 500 — Advertencias, inicio/fin de almuerzo.
  static const Color systemOrange = Color(0xFFF59E0B);

  /// Alias semántico: systemBlue == primary (un único azul en toda la app).
  static const Color systemBlue = primary;

  // ══════════════════════════════════════════════════════════════════
  //  GRISES DEL SISTEMA — Jerarquía visual (Slate de Tailwind)
  // ══════════════════════════════════════════════════════════════════

  /// Slate 500 — Texto secundario, iconos inactivos.
  static const Color systemGray = Color(0xFF64748B);

  /// Slate 400 — Placeholders, timestamps.
  static const Color systemGray2 = Color(0xFF94A3B8);

  /// Slate 300 — Bordes sutiles, separadores.
  static const Color systemGray3 = Color(0xFFCBD5E1);

  /// Slate 200 — Bordes de cards, dividers.
  static const Color systemGray4 = Color(0xFFE2E8F0);

  /// Slate 100 — Fondo de chips inactivos.
  static const Color systemGray5 = Color(0xFFF1F5F9);

  /// Slate 50 — Fondo de sección agrupada.
  static const Color systemGray6 = Color(0xFFF8FAFC);

  // ══════════════════════════════════════════════════════════════════
  //  FONDOS Y SUPERFICIES
  // ══════════════════════════════════════════════════════════════════

  /// Fondo principal — Light Slate (#F8FAFC).
  static const Color background = Color(0xFFF8FAFC);

  /// Fondo secundario (secciones agrupadas) — Slate 100.
  static const Color backgroundSecondary = Color(0xFFF1F5F9);

  /// Superficie de cards y modales — Blanco puro.
  static const Color surface = Color(0xFFFFFFFF);

  /// Borde de card/input — Slate 200.
  static const Color borderColor = Color(0xFFE2E8F0);

  // ══════════════════════════════════════════════════════════════════
  //  TIPOGRAFÍA
  // ══════════════════════════════════════════════════════════════════

  /// Texto principal — Slate 900 (#0F172A).
  static const Color textPrimary = Color(0xFF0F172A);

  /// Texto secundario — Slate 600 (#475569).
  static const Color textSecondary = Color(0xFF475569);

  /// Texto terciario — Slate 500 (#64748B).
  static const Color textTertiary = Color(0xFF64748B);

  // ══════════════════════════════════════════════════════════════════
  //  SEPARADORES
  // ══════════════════════════════════════════════════════════════════

  /// Separador estándar — Slate 200.
  static const Color separator = Color(0xFFE2E8F0);

  // ══════════════════════════════════════════════════════════════════
  //  ALIAS DE COMPATIBILIDAD (nombres legacy que usaba el código existente)
  // ══════════════════════════════════════════════════════════════════

  static const Color secondary = accentIndigo;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;
  static const Color outline = borderColor;
  static const Color outlineVariant = systemGray4;
  static const Color error = systemRed;
  static const Color surfaceContainerLow = surface;
  static const Color surfaceContainerHighest = systemGray6;
  static const Color primaryFixed = Color(0xFFEFF6FF); // Blue 50
  static const Color secondaryContainer = Color(0xFFEFF6FF);
  static const Color errorContainer = Color(0xFFFEF2F2); // Red 50

  // ══════════════════════════════════════════════════════════════════
  //  GRADIENTES PREDEFINIDOS (constantes reutilizables en toda la app)
  // ══════════════════════════════════════════════════════════════════

  /// Gradiente de la tarjeta "Escanear QR" — Índigo.
  static const LinearGradient gradientQR = LinearGradient(
    colors: [accentIndigo, accentIndigoDark],
  );

  /// Gradiente de la tarjeta "Marcar Asistencia" — Azul corporativo.
  static const LinearGradient gradientAttendance = LinearGradient(
    colors: [primary, primaryDark],
  );

  /// Gradiente de la tarjeta "Historial" — Emerald.
  static const LinearGradient gradientHistory = LinearGradient(
    colors: [systemGreen, systemGreenDark],
  );

  /// Gradiente de fondo del Dashboard.
  static const LinearGradient gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, Color(0xFFEEF4FF)],
  );
}

// ══════════════════════════════════════════════════════════════════════
//  TOKENS DE DISEÑO — Radios, espaciado y sombras
// ══════════════════════════════════════════════════════════════════════

abstract final class DesignTokens {
  // ── Border Radius ──
  static const double radiusXS = 8.0;
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 24.0;

  // ── Spacing ──
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // ── Padding estándar ──
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  // ── Sombras ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> cardShadowColored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
