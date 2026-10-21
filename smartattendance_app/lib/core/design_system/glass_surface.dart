import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: GlassSurface
/// ============================================================================
/// Superficie translúcida de precisión con desenfoque Gaussiano controlado,
/// borde semitransparente discreto y fallback sólido para accesibilidad.
///
/// Características técnicas:
/// - Blur configurable (sigmaX, sigmaY).
/// - Opacidad adaptable según el brillo del tema (claro/oscuro).
/// - Borde semitransparente de 1 dp.
/// - Radio consistente (por defecto 16 dp).
/// - Elevación sutil mediante sombra suave.
/// - Alternativa sólida inmediata cuando el usuario activa alto contraste
///   o cuando se reduce la transparencia del sistema.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blurSigmaX;
  final double blurSigmaY;
  final double? opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final BoxBorder? customBorder;
  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigmaX = 12.0,
    this.blurSigmaY = 12.0,
    this.opacity,
    this.borderRadius,
    this.padding,
    this.margin,
    this.tintColor,
    this.borderColor,
    this.width,
    this.height,
    this.customBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final media = MediaQuery.of(context);
    final reduceTransparency = media.highContrast || media.disableAnimations;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppDesignTokens.radiusCard);

    // Color base y opacidad sobria
    final defaultOpacity = isDark ? 0.78 : 0.84;
    final effectiveOpacity = opacity ?? defaultOpacity;

    final baseTint = tintColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF));
    final surfaceColor = reduceTransparency
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF))
        : baseTint.withValues(alpha: effectiveOpacity);

    final effectiveBorderColor = borderColor ??
        (isDark
            ? const Color(0xFF334155).withValues(alpha: 0.65)
            : const Color(0xFFCBD5E1).withValues(alpha: 0.7));

    final effectiveBorder = customBorder ??
        Border.all(
          color: effectiveBorderColor,
          width: AppDesignTokens.borderWidth,
        );

    final decoration = BoxDecoration(
      color: surfaceColor,
      borderRadius: effectiveRadius,
      border: effectiveBorder,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: content,
      );
    }

    // Fallback sólido cuando la accesibilidad exige alto contraste
    if (reduceTransparency) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: effectiveRadius,
              border: effectiveBorder,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
