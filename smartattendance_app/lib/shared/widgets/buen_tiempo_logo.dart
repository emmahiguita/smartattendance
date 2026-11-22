// lib/shared/widgets/buen_tiempo_logo.dart
import 'package:flutter/material.dart';
import '../../core/theme/buen_tiempo_colors.dart';
import 'buen_tiempo_emblem_painter.dart';

/// ============================================================================
/// COMPONENTE: BuenTiempoLogo (Identidad Visual Oficial)
/// ============================================================================
/// QUÉ HACE:
/// Despliega el logotipo oficial corporativo "BuenTiempo", combinando el imagotipo
/// vectorial de alta precisión con la tipografía bicolor (Buen en Azul, Tiempo en Verde).
///
/// CÓMO FUNCIONA:
/// 1. Aísla el dibujo en un [RepaintBoundary] para evitar que el renderizado
///    se repita cuando los widgets padre se re-dibujen, eliminando lags de CPU/GPU.
/// 2. Soporta 4 variantes de visualización:
///    - `horizontal`: Emblema a la izquierda + texto a la derecha (Barras de navegación).
///    - `vertical`: Emblema arriba + texto centrado (Splash y pantallas de inicio de sesión).
///    - `iconOnly`: Solo el isotipo vectorial.
///    - `iosSquircle`: Ícono de aplicación con fondo crema y bordes redondeados estilo Apple.
///
/// POR QUÉ:
/// Centraliza la identidad de la marca. Cualquier cambio de tamaño o estilo se
/// propaga instantáneamente y de forma reactiva sin duplicar código en pantallas.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Responsabilidad única de renderizar el logo BuenTiempo.
/// - O (Open/Closed): Configurable vía parámetros de tamaño y orientación sin alterar su núcleo.
/// ============================================================================
class BuenTiempoLogo extends StatelessWidget {
  final double size;
  final double? titleSize;
  final bool isHorizontal;
  final bool iconOnly;
  final bool iosSquircle;
  final bool hasBorder;
  final bool showSubtitle;
  final String? subtitleText;

  const BuenTiempoLogo({
    super.key,
    this.size = 36,
    this.titleSize,
    this.isHorizontal = true,
    this.iconOnly = false,
    this.iosSquircle = false,
    this.hasBorder = true,
    this.showSubtitle = false,
    this.subtitleText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // QUÉ HACE: Adapta los colores del emblema y la marca al modo oscuro o claro.
    // CÓMO: Si lleva squircle crema conserva navy/teal; sin squircle en oscuro usa blanco/teal brillante.
    // POR QUÉ: Garantiza contraste WCAG AA en fondos oscuros OLED y claros iOS.
    final emblem = RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: BuenTiempoEmblemPainter(
          clockColor: (!iosSquircle && isDark)
              ? const Color(0xFFF1F5F9)
              : BuenTiempoColors.navy,
          checkColor: (!iosSquircle && isDark)
              ? const Color(0xFF2DD4BF)
              : BuenTiempoColors.teal,
        ),
      ),
    );

    // Si se solicita estilo ícono de iOS (Squircle 3D con volumen y doble sombra)
    final emblemWrapped = iosSquircle
        ? Container(
            width: size * 1.35,
            height: size * 1.35,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  BuenTiempoColors.popCream,
                  Color(0xFFEDE8DF),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(size * 0.36),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.95),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : const Color(0xFF0F172A).withValues(alpha: 0.16),
                  blurRadius: size * 0.42,
                  spreadRadius: -0.5,
                  offset: Offset(0, size * 0.15),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: size * 0.14,
                  offset: Offset(0, size * 0.05),
                ),
              ],
            ),
            child: Center(child: emblem),
          )
        : emblem;

    if (iconOnly) {
      return emblemWrapped;
    }

    // 2. Tipografía Bicolor "BuenTiempo" adaptativa a modo claro/oscuro con relieve 3D sutil
    final titleFontSize =
        titleSize ?? (size * 0.54).clamp(13.5, 34.0).toDouble();
    final textStyle = TextStyle(
      fontSize: titleFontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.1,
      shadows: [
        Shadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.55)
              : const Color(0xFF0F172A).withValues(alpha: 0.12),
          offset: const Offset(0, 1.5),
          blurRadius: 3.5,
        ),
      ],
    );

    final titleSpan = RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Buen',
            style: textStyle.copyWith(
              color: isDark ? const Color(0xFFF8FAFC) : BuenTiempoColors.navy,
            ),
          ),
          TextSpan(
            text: 'Tiempo',
            style: textStyle.copyWith(
              color: isDark ? const Color(0xFF2DD4BF) : BuenTiempoColors.teal,
            ),
          ),
        ],
      ),
    );

    // 3. Subtítulo corporativo opcional con altura legible
    final subtitleFontSize = (size * 0.22).clamp(10.0, 12.5).toDouble();
    final subtitleWidget = showSubtitle
        ? Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Text(
              subtitleText ?? 'CONTROL DE ASISTENCIA Y JORNADAS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: isHorizontal ? 0.1 : 0.7,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.65)
                    : BuenTiempoColors.navy.withValues(alpha: 0.65),
              ),
            ),
          )
        : const SizedBox.shrink();

    // 4. Disposición Horizontal
    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblemWrapped,
          SizedBox(width: (size * 0.32).clamp(8.0, 14.0)),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSpan,
                if (showSubtitle) subtitleWidget,
              ],
            ),
          ),
        ],
      );
    }

    // 5. Disposición Vertical
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblemWrapped,
        SizedBox(height: (size * 0.24).clamp(8.0, 16.0)),
        titleSpan,
        if (showSubtitle) subtitleWidget,
      ],
    );
  }
}
