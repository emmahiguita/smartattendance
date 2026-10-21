// lib/core/design_system/ios_glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// ============================================================================
/// COMPONENTE: IosGlassCard (Efecto Glassmorphism / Frosted Glass Apple HIG)
/// ============================================================================
/// QUÉ HACE:
/// Contenedor translúcido estilo iOS con desenfoque gaussiano de fondo ([BackdropFilter]),
/// bordes hairline de 0.5dp con brillo sutil y esquinas redondeadas continuas.
///
/// CÓMO FUNCIONA:
/// Aplica [ImageFilter.blur] con sigma 12.0 y una capa de color con opacidad adaptativa
/// según el modo de color (claro u oscuro), garantizando legibilidad tipográfica.
///
/// POR QUÉ:
/// Ofrece la estética nativa de iOS / iPadOS (Liquid Glass / Frosted Glass)
/// eliminando componentes planos o saturados tipo vibecoder.
/// ============================================================================
class IosGlassCard extends StatelessWidget {
  const IosGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 14,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFE5E5EA).withValues(alpha: 0.8),
      width: 0.5,
    );

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? defaultBorder,
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
