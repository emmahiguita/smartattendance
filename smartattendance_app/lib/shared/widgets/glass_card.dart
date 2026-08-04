import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Tarjeta principal de la aplicación.
/// Refactorizada para usar el estilo iOS Flat Card en lugar del Glassmorphism previo.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: context
            .cSurface, // Fondo contextual (blanco en light, oscuro en dark)
        borderRadius: BorderRadius.circular(16), // Curvatura iOS estándar
        border: Border.all(
          color: context.cBorder.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.03), // Sombra extremadamente sutil
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
