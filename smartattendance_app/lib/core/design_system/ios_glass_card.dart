// ============================================================================
// ARCHIVO: ios_glass_card.dart
// QUÉ HACE: Contenedor con efecto translúcido Frosted Liquid Glass 100% iOS
//           utilizando `BackdropFilter` con desenfoque gaussiano y borde especular.
// CÓMO FUNCIONA: Aplica `ImageFilter.blur(sigmaX: 22, sigmaY: 22)`, fondo de
//                cristal translúcido (`0.42` en modo oscuro con reflejo especular
//                superior) y borde cristalino de 0.9dp.
// POR QUÉ: Materializa la directiva "el modo oscuro debe ser 100% ios
//          trasparente profesional" (< 85 líneas).
// ============================================================================

import 'dart:ui';
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
      color: isDark ? Colors.white.withValues(alpha: 0.18) : context.cBorder.withValues(alpha: 0.85),
      width: 0.9,
    );

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E1C30).withValues(alpha: 0.44) : context.cSurface.withValues(alpha: 0.92),
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      const Color(0xFF0E1C30).withValues(alpha: 0.38),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? defaultBorder,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
