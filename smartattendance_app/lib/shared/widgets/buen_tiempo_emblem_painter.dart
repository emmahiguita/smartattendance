// lib/shared/widgets/buen_tiempo_emblem_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/buen_tiempo_colors.dart';

/// ============================================================================
/// PINTOR VECTORIAL: BuenTiempoEmblemPainter
/// ============================================================================
/// QUÉ HACE:
/// Dibuja vectorialmente el imagotipo oficial de "BuenTiempo":
/// 1. Sol matutino con rayos dorados (simboliza inicio de turno y puntualidad).
/// 2. Esfera de reloj en azul marino con marcas horarias a las 12, 3, 6 y 9.
/// 3. Checkmark central en verde azulado (simboliza registro exitoso y verificado).
///
/// CÓMO FUNCIONA:
/// Usa el Canvas nativo de Flutter mediante operaciones geométricas puras con
/// `Paint` preconfigurados con `StrokeCap.round` y `PaintingStyle.stroke`.
///
/// POR QUÉ:
/// Al ser vectorial matemático puro en lugar de PNG rasterizado:
/// - No se pixela en ninguna resolución ni densidad de pantalla (1x a 4x).
/// - Pesa 0 bytes de assets adicionales en el APK final.
/// - Retorna `shouldRepaint => false`, permitiendo a Flutter almacenar en caché
///   la lista de comandos de la GPU (DisplayList) eliminando lags y cuellos de botella.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente calcula y dibuja la geometría del logo.
/// ============================================================================
class BuenTiempoEmblemPainter extends CustomPainter {
  const BuenTiempoEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.46, size.height * 0.54);
    final clockRadius = size.width * 0.38;
    final strokeWidth = size.width * 0.082;

    // -------------------------------------------------------------------------
    // 1. SOL MATUTINO (Amanecer / Buen Tiempo)
    // -------------------------------------------------------------------------
    final sunCenter = Offset(size.width * 0.65, size.height * 0.28);
    final sunRadius = size.width * 0.22;

    final sunFillPaint = Paint()
      ..color = BuenTiempoColors.sunAmber
      ..style = PaintingStyle.fill;

    // Dibuja el semicírculo del sol naciente detrás del borde superior derecho
    canvas.drawArc(
      Rect.fromCircle(center: sunCenter, radius: sunRadius),
      -math.pi * 0.95,
      math.pi * 0.85,
      true,
      sunFillPaint,
    );

    // Rayos del sol radiantes con extremos redondeados
    final sunRayPaint = Paint()
      ..color = BuenTiempoColors.sunAmber
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * 0.65;

    final rayAngles = [-math.pi * 0.80, -math.pi * 0.50, -math.pi * 0.20];
    for (final angle in rayAngles) {
      final p1 = Offset(
        sunCenter.dx + (sunRadius + strokeWidth * 0.35) * math.cos(angle),
        sunCenter.dy + (sunRadius + strokeWidth * 0.35) * math.sin(angle),
      );
      final p2 = Offset(
        sunCenter.dx + (sunRadius + strokeWidth * 0.95) * math.cos(angle),
        sunCenter.dy + (sunRadius + strokeWidth * 0.95) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, sunRayPaint);
    }

    // -------------------------------------------------------------------------
    // 2. DIAL DEL RELOJ (Azul Marino Corporativo)
    // -------------------------------------------------------------------------
    final clockPaint = Paint()
      ..color = BuenTiempoColors.navy
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Aro principal del reloj (con sutil apertura para integrar el sol)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: clockRadius),
      -math.pi * 0.20,
      math.pi * 1.85,
      false,
      clockPaint,
    );

    // Marcas horarias interiores (12, 3, 6, 9)
    final tickPaint = Paint()
      ..color = BuenTiempoColors.navy
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * 0.70;

    final tickLength = strokeWidth * 0.95;
    // Marca a las 12 (vertical arriba)
    canvas.drawLine(
      Offset(center.dx, center.dy - clockRadius + strokeWidth * 0.6),
      Offset(center.dx, center.dy - clockRadius + strokeWidth * 0.6 + tickLength),
      tickPaint,
    );
    // Marca a las 6 (vertical abajo)
    canvas.drawLine(
      Offset(center.dx, center.dy + clockRadius - strokeWidth * 0.6 - tickLength),
      Offset(center.dx, center.dy + clockRadius - strokeWidth * 0.6),
      tickPaint,
    );
    // Marca a las 9 (horizontal izquierda)
    canvas.drawLine(
      Offset(center.dx - clockRadius + strokeWidth * 0.6, center.dy),
      Offset(center.dx - clockRadius + strokeWidth * 0.6 + tickLength, center.dy),
      tickPaint,
    );
    // Marca a las 3 (horizontal derecha)
    canvas.drawLine(
      Offset(center.dx + clockRadius - strokeWidth * 0.6 - tickLength, center.dy),
      Offset(center.dx + clockRadius - strokeWidth * 0.6, center.dy),
      tickPaint,
    );

    // -------------------------------------------------------------------------
    // 3. CHECKMARK CENTRAL (Verde Azulado / Asistencia a Tiempo)
    // -------------------------------------------------------------------------
    final checkPaint = Paint()
      ..color = BuenTiempoColors.teal
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 1.25;

    final checkPath = Path()
      ..moveTo(center.dx - clockRadius * 0.44, center.dy - clockRadius * 0.05)
      ..lineTo(center.dx - clockRadius * 0.08, center.dy + clockRadius * 0.35)
      ..lineTo(center.dx + clockRadius * 0.50, center.dy - clockRadius * 0.35);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
