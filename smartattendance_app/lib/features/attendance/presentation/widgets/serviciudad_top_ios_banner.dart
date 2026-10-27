// ============================================================================
// ARCHIVO: serviciudad_top_ios_banner.dart
// QUÉ HACE: Cabecera visual superior de Inicio que muestra la imagen oficial
//           de Serviciudad E.S.P. ("Servicio de Alcantarillado") COMPLETA
//           (relación 1024x600 sin recortes) únicamente en la parte superior,
//           con acabado estilo iOS opaco/translúcido integrado al fondo.
// CÓMO FUNCIONA:
// 1. Mantiene la proporción exacta `1024 / 600` (`BoxFit.contain` / `fill`)
//    para que se vea el 100% de la fotografía, el logo y los 3 íconos.
// 2. Aplica `ShaderMask` y un velo sutil estilo iOS (`BackdropFilter` +
//    gradiente hacia `context.cBackground`) para que se funda con el fondo
//    de la pantalla solo en la franja superior.
// POR QUÉ: Cumple la directiva de mostrar la imagen completa arriba con estilo
//          iOS opaco sin ocupar toda la pantalla (< 115 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Banner superior iOS opaco con la imagen institucional completa en Inicio.
class ServiciudadTopIosBanner extends StatelessWidget {
  const ServiciudadTopIosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = context.cBackground;
    final isLandscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 460 : double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppColors.primary.withValues(alpha: 0.14),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              children: [
                // 1. Imagen completa (1024x600) con opacidad iOS integrada al fondo
                AspectRatio(
                  aspectRatio: 1024 / 600,
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.86 : 0.92),
                        Colors.white.withValues(alpha: isDark ? 0.82 : 0.90),
                        Colors.white.withValues(alpha: isDark ? 0.35 : 0.55),
                      ],
                      stops: const [0.0, 0.76, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      AppAssets.bannerInicioAlcantarillado,
                      width: double.infinity,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                // 2. Velo opaco estilo iOS en el borde inferior para fundirse con la pantalla
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 34,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              bgColor.withValues(alpha: 0.0),
                              bgColor.withValues(alpha: isDark ? 0.72 : 0.62),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
