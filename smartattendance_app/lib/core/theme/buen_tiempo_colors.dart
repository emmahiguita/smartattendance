// lib/core/theme/buen_tiempo_colors.dart
import 'package:flutter/material.dart';

/// ============================================================================
/// PALETA DE COLORES OFICIAL: BUENTIEMPO
/// ============================================================================
/// QUÉ HACE:
/// Define los tokens de color corporativos de la marca "BuenTiempo" extraídos
/// de la identidad visual oficial (reloj, sol matutino y checkmark).
///
/// CÓMO FUNCIONA:
/// Provee constantes inmutables para que ningún componente tenga colores "mágicos"
/// dispersos en el código, facilitando el mantenimiento y cambio de marca.
///
/// POR QUÉ:
/// Garantiza consistencia en modo claro y oscuro, respetando accesibilidad WCAG AA
/// en contrastes tipográficos y evitando colores estridentes o inconsistencias.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Única fuente de verdad cromática de BuenTiempo.
/// - O (Open/Closed): Extensible con nuevas tonalidades sin modificar las existentes.
/// ============================================================================
abstract final class BuenTiempoColors {
  /// Azul marino profundo: base del dial del reloj y palabra "Buen"
  static const Color navy = Color(0xFF0A2540);

  /// Verde esmeralda / cerceta: checkmark de asistencia y palabra "Tiempo"
  static const Color teal = Color(0xFF00838F);

  /// Ámbar solar: semicírculo y rayos del amanecer (primer turno del día)
  static const Color sunAmber = Color(0xFFF7A622);

  /// Fondo crema suave para material POP e ícono iOS
  static const Color popCream = Color(0xFFFAF8F5);

  /// Fondo de tarjeta publicitaria y bordes sutiles
  static const Color borderLight = Color(0xFFE2E8F0);

  /// Azul marino translúcido para sombras suaves sin causar lag en GPU
  static final Color navyShadow = navy.withValues(alpha: 0.12);

  /// Verde esmeralda suave para fondos de etiquetas activas
  static final Color tealSoft = teal.withValues(alpha: 0.10);
}
