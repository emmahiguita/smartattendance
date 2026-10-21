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
  final bool isHorizontal;
  final bool iconOnly;
  final bool iosSquircle;
  final bool showSubtitle;
  final String? subtitleText;

  const BuenTiempoLogo({
    super.key,
    this.size = 36,
    this.isHorizontal = true,
    this.iconOnly = false,
    this.iosSquircle = false,
    this.showSubtitle = false,
    this.subtitleText,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Emblema vectorial puro aislado para máxima fluidez a 120 FPS
    final emblem = RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: const BuenTiempoEmblemPainter(),
      ),
    );

    // Si se solicita estilo ícono de iOS (Squircle con fondo crema suave)
    final emblemWrapped = iosSquircle
        ? Container(
            width: size * 1.35,
            height: size * 1.35,
            decoration: BoxDecoration(
              color: BuenTiempoColors.popCream,
              borderRadius: BorderRadius.circular(size * 0.38),
              border: Border.all(color: BuenTiempoColors.borderLight, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: BuenTiempoColors.navyShadow,
                  blurRadius: size * 0.30,
                  offset: Offset(0, size * 0.10),
                ),
              ],
            ),
            child: Center(child: emblem),
          )
        : emblem;

    if (iconOnly) {
      return emblemWrapped;
    }

    // 2. Tipografía Bicolor "BuenTiempo"
    final textStyle = TextStyle(
      fontSize: size * 0.54,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.1,
    );

    final titleSpan = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Buen',
            style: textStyle.copyWith(color: BuenTiempoColors.navy),
          ),
          TextSpan(
            text: 'Tiempo',
            style: textStyle.copyWith(color: BuenTiempoColors.teal),
          ),
        ],
      ),
    );

    // 3. Subtítulo corporativo opcional
    final subtitleWidget = showSubtitle
        ? Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              subtitleText ?? 'CONTROL DE ASISTENCIA Y JORNADAS',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: BuenTiempoColors.navy.withValues(alpha: 0.65),
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
          SizedBox(width: size * 0.30),
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
        SizedBox(height: size * 0.32),
        titleSpan,
        if (showSubtitle) subtitleWidget,
      ],
    );
  }
}
