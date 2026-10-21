// lib/features/qr/presentation/widgets/qr_corner_painter.dart
import 'package:flutter/material.dart';

/// ============================================================================
/// COMPONENTE: QrCorner
/// ============================================================================
/// QUÉ HACE:
/// Traza con alta precisión geométrica una de las 4 esquinas del visor QR.
///
/// PARA QUÉ SIRVE:
/// Provee estética moderna y guía visual nítida sin recargar el pipeline de renderizado.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente responsable de renderizar esquinas vectoriales.
/// ============================================================================
class QrCorner extends StatelessWidget {
  final double side, bw, r;
  final Color color;
  final bool isTop, isLeft;

  const QrCorner({
    super.key,
    required this.side,
    required this.bw,
    required this.r,
    required this.color,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
        painter: _CornerPainter(color: color, strokeWidth: bw, radius: r, isTop: isTop, isLeft: isLeft),
      ),
    );
  }
}

/// CustomPainter altamente eficiente para trazar bordes de esquinas
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth, radius;
  final bool isTop, isLeft;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? radius : -radius;
    final dy = isTop ? radius : -radius;

    path.moveTo(x + dx, y);
    path.lineTo(x, y);
    path.lineTo(x, y + dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
