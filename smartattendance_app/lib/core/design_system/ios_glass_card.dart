// ============================================================================
// ARCHIVO: ios_glass_card.dart
// QUÉ HACE: Contenedor Liquid Glass de 4 capas ópticas (Apple iOS 26 / Flutter
//           Impeller): RepaintBoundary + Lente Gaussiano + Reflejo Especular
//           Cenital (`stops: [0.0, 0.65]`) + Borde de Cristal Tallado (`1.0px`).
// CÓMO FUNCIONA: Aísla el `BackdropFilter` en un `RepaintBoundary` para 120Hz
//                e incluye fallback automático de accesibilidad (`highContrast`).
// POR QUÉ: Implementa la especificación más avanzada de Liquid Glass en Flutter
//          para Modo Oscuro (< 95 líneas).
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
    final highContrast = MediaQuery.highContrastOf(context);
    final defaultBorder = Border.all(
      color: isDark ? Colors.white.withValues(alpha: 0.16) : context.cBorder.withValues(alpha: 0.85),
      width: 0.95,
    );

    final decoration = BoxDecoration(
      color: highContrast
          ? (isDark ? const Color(0xFF0C182B) : Colors.white)
          : (isDark ? const Color(0xFF07101E).withValues(alpha: 0.46) : context.cSurface.withValues(alpha: 0.92)),
      gradient: (!highContrast && isDark)
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.015),
              ],
              stops: const [0.0, 0.65],
            )
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? defaultBorder,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.04),
          blurRadius: 18,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ],
    );

    final cardContent = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: highContrast
            ? Container(padding: padding, decoration: decoration, child: child)
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(padding: padding, decoration: decoration, child: child),
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
