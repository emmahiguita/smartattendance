// lib/features/qr/presentation/widgets/qr_scanner_window.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'qr_corner_painter.dart';

/// ============================================================================
/// COMPONENTE: QrScannerWindow
/// ============================================================================
/// QUÉ HACE:
/// Dibuja el marco de enfoque visual con esquinas redondeadas y una línea láser
/// animada que sube y baja emulando la lectura óptica del sensor.
///
/// PARA QUÉ SIRVE:
/// Delimita el área objetivo donde el empleado debe encuadrar el código QR.
/// Se adapta perfectamente a modo horizontal (landscape) y pantallas pequeñas.
///
/// CONTROL DE RECURSOS (ZOMBIE PROCESS PREVENTION):
/// - El AnimationController se crea en initState y se libera en dispose().
/// ============================================================================
class QrScannerWindow extends StatefulWidget {
  final bool isProcessing;

  const QrScannerWindow({super.key, required this.isProcessing});

  @override
  State<QrScannerWindow> createState() => _QrScannerWindowState();
}

class _QrScannerWindowState extends State<QrScannerWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _laserAnim;

  @override
  void initState() {
    super.initState();
    // Animación continua de vaivén de 2.5 segundos
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _laserAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    // Destrucción limpia del controlador para evitar procesos zombi de renderizado
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // En modo horizontal nos limitamos por la altura disponible; en vertical por el ancho
    final isLandscape = media.orientation == Orientation.landscape;
    final availableSize = isLandscape
        ? media.size.height * 0.52
        : math.min(media.size.width * 0.70, 280.0);

    return SizedBox(
      width: availableSize,
      height: availableSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cuatro esquinas de precisión con QrCorner
          ..._buildCorners(availableSize),

          // Centro transparente recortado
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: availableSize - 8,
              height: availableSize - 8,
              color: Colors.transparent,
            ),
          ),

          // Indicador de carga o línea láser activa
          if (widget.isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else
            _LaserLine(animation: _laserAnim),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(double size) {
    const side = 32.0;
    const strokeWidth = 3.5;
    const radius = 10.0;
    const color = AppColors.primary;

    return const [
      Positioned(top: 0, left: 0, child: QrCorner(side: side, bw: strokeWidth, r: radius, color: color, isTop: true, isLeft: true)),
      Positioned(top: 0, right: 0, child: QrCorner(side: side, bw: strokeWidth, r: radius, color: color, isTop: true, isLeft: false)),
      Positioned(bottom: 0, left: 0, child: QrCorner(side: side, bw: strokeWidth, r: radius, color: color, isTop: false, isLeft: true)),
      Positioned(bottom: 0, right: 0, child: QrCorner(side: side, bw: strokeWidth, r: radius, color: color, isTop: false, isLeft: false)),
    ];
  }
}

/// Línea láser luminosa animada verticalmente
class _LaserLine extends StatelessWidget {
  final Animation<double> animation;

  const _LaserLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Positioned(
            top: animation.value * (constraints.maxHeight - 4),
            left: 8,
            right: 8,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Colors.transparent, AppColors.primary, Colors.transparent],
                ),
                boxShadow: const [
                  BoxShadow(color: AppColors.primary, blurRadius: 10, spreadRadius: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
