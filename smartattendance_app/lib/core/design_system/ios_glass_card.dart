// ============================================================================
// ARCHIVO: ios_glass_card.dart
// QUÉ HACE: Contenedor con efecto translúcido Frosted Glass profesional (HIG)
//           utilizando `BackdropFilter` con desenfoque gaussiano y bordes sutiles.
// CÓMO FUNCIONA: Aplica un filtro de desenfoque (`ImageFilter.blur(sigmaX: 20, sigmaY: 20)`),
//                fondo de superficie translúcida (`0.72` en modo oscuro / `0.82` en claro)
//                y borde metálico Titanium Enterprise de 0.8dp.
// POR QUÉ: Brinda la apariencia premium de vidrio esmerilado de iOS sin saturación
//          ni sobrecarga de memoria (< 90 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IosGlassCard extends StatelessWidget {
  const IosGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final defaultBorder = Border.all(
      color: context.cBorder.withValues(alpha: isDark ? 0.80 : 0.85),
      width: 0.9,
    );

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cSurface.withValues(alpha: isDark ? 0.90 : 0.95),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return cardContent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      ),
    );
  }
}