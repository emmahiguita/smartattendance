// ============================================================================
// ARCHIVO: ios_glass_card.dart
// QUÉ HACE: Tarjeta translúcida iOS Liquid Glass con BackdropFilter Gaussiano,
//           borde ultra-fino y esquinas redondeadas profesionales.
// CÓMO FUNCIONA: BackdropFilter + ClipRRect + BoxDecoration con border 0.8px.
//               Si borderRadius==0 cae en modo separador plano (retrocompat).
// POR QUÉ: SRP — encapsula la superficie glass reutilizable < 60 líneas.
// ============================================================================
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IosGlassCard extends StatelessWidget {
  const IosGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.borderRadius = 0,
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
    // QUÉ HACE: Modo plano (separador) cuando borderRadius == 0 — retro-compat.
    if (borderRadius == 0) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: padding, child: child),
            const Divider(height: 1),
          ]),
        ),
      );
    }

    // QUÉ HACE: Tarjeta Liquid Glass con desenfoque 16px y borde 0.8px.
    // CÓMO: ClipRRect + BackdropFilter rodean el contenido; BoxDecoration
    //       añade el borde semitransparente y el tint de color de superficie.
    final radius = BorderRadius.circular(borderRadius);
    final effectiveBorder = border ??
        Border.all(
          color: context.cBorder.withValues(alpha: context.isDark ? 0.45 : 0.55),
          width: 0.8,
        );

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.cSurface.withValues(alpha: context.isDark ? 0.52 : 0.72),
            borderRadius: radius,
            border: effectiveBorder,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
