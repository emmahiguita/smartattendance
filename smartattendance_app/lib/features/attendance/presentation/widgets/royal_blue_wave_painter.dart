// ============================================================================
// ARCHIVO: royal_blue_wave_painter.dart
// QUÉ HACE: Dibuja por código vectorial (`CustomPainter`) las olas azules
//           superiores (`RoyalBlueWavePainter`) y las olas azules inferiores
//           (`RoyalBlueBottomWavePainter`) del mismo tono azul real, limpias y
//           sin bordes ni trazos neón que causen desorientación de color.
// CÓMO FUNCIONA:
// 1. `RoyalBlueWavePainter` extiende el relleno azul desde `y = -240` hasta
//    `waveHeight` para que al deslizar nunca aparezca blanco arriba.
// 2. `RoyalBlueBottomWavePainter` dibuja olas azules de ancho completo ancladas
//    al borde inferior (`bottom: 0`) para que al subir nunca se vea blanco.
// POR QUÉ: Cumple acabado limpio sin bordes distorsionados (< 155 líneas).
// ============================================================================

import 'package:flutter/material.dart';

class RoyalBlueWavePainter extends CustomPainter {
  const RoyalBlueWavePainter({required this.waveHeight});
  final double waveHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = waveHeight;
    const topOverhang = -240.0;
    final topRect = Rect.fromLTRB(0, topOverhang, w, h + 20);

    // 1. Cinta de ola azul real secundaria (mismo tono azul, sin bordes neón)
    final secondaryWave = Path()
      ..moveTo(0, topOverhang)
      ..lineTo(w, topOverhang)
      ..lineTo(w, h * 0.68)
      ..cubicTo(w * 0.94, h * 0.78, w * 0.86, h * 0.88, w * 0.74, h * 0.94)
      ..cubicTo(w * 0.50, h * 1.05, w * 0.24, h * 0.82, 0, h * 0.91)
      ..close();

    canvas.drawPath(
      secondaryWave.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xFF003B8E).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      secondaryWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF003885),
            Color(0xFF0052B8),
            Color(0xFF0066DD),
            Color(0xFF1A78F2),
          ],
          stops: [0.0, 0.45, 0.80, 1.0],
        ).createShader(topRect),
    );

    // 2. Ola azul real profunda principal (sin trazos ni bordes que desorienten)
    final primaryWave = Path()
      ..moveTo(0, topOverhang)
      ..lineTo(w, topOverhang)
      ..lineTo(w, h * 0.46)
      ..cubicTo(w * 0.90, h * 0.68, w * 0.74, h * 0.94, w * 0.48, h * 0.90)
      ..cubicTo(w * 0.24, h * 0.85, w * 0.10, h * 0.82, 0, h * 0.90)
      ..close();

    canvas.drawPath(
      primaryWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF011638),
            Color(0xFF002868),
            Color(0xFF003F94),
            Color(0xFF0055C4),
          ],
          stops: [0.0, 0.38, 0.75, 1.0],
        ).createShader(topRect),
    );
  }

  @override
  bool shouldRepaint(covariant RoyalBlueWavePainter oldDelegate) =>
      oldDelegate.waveHeight != waveHeight;
}

class RoyalBlueBottomWavePainter extends CustomPainter {
  const RoyalBlueBottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Ola azul trasera de ancho completo (cubre 100% la base inferior)
    final backWave = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.34)
      ..cubicTo(w * 0.26, h * 0.08, w * 0.56, h * 0.62, w, h * 0.22)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      backWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF003F94),
            Color(0xFF005AC8),
            Color(0xFF1A78F2),
            Color(0xFF0047AB),
          ],
        ).createShader(rect),
    );

    // 2. Ola azul profunda frontal de ancho completo (cero espacios blancos al subir)
    final frontWave = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.52)
      ..cubicTo(w * 0.32, h * 0.78, w * 0.66, h * 0.24, w, h * 0.46)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      frontWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF011638),
            Color(0xFF002868),
            Color(0xFF003F94),
            Color(0xFF0052B8),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RoyalBlueBottomWavePainter oldDelegate) => false;
}
