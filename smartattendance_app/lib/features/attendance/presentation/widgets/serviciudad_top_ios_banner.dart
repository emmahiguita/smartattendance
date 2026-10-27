// ============================================================================
// ARCHIVO: serviciudad_top_ios_banner.dart
// QUÉ HACE: Muestra la imagen oficial de Serviciudad E.S.P. ("Servicio de
//           Alcantarillado") COMPLETA en la parte superior de Inicio SIN CARD
//           (sin bordes, sin contenedor ni sombras), fundida en estilo iOS
//           opaco con el fondo de la pantalla, y debajo presenta de forma
//           puramente textual el título y resumen corto de Misión, Visión e
//           información institucional.
// CÓMO FUNCIONA:
// 1. `ShaderMask` difumina el borde inferior de la fotografía (`1024x600`)
//    directamente hacia el fondo de la pantalla (`context.cBackground`).
// 2. Debajo renderiza tipografía limpia con Misión, Visión e Información
//    institucional breve, sin encerrarla en tarjetas.
// POR QUÉ: Cumple la directiva "la imagen debe estar sin una card, y debajo de
//          ella el título de la misión visión e información corta y ya textual"
//          (< 125 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Cabecera superior sin card con desvanecimiento iOS y bloque textual de Misión y Visión.
class ServiciudadTopIosBanner extends StatelessWidget {
  const ServiciudadTopIosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Imagen superior COMPLETA SIN CARD (borde a borde con fusión iOS opaca al fondo)
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLandscape ? 520 : double.infinity,
            ),
            child: AspectRatio(
              aspectRatio: 1024 / 600,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.90 : 0.96),
                    Colors.white.withValues(alpha: isDark ? 0.85 : 0.92),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.78, 1.0],
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
          ),
        ),

        // 2. Bloque puramente textual: Título + Misión, Visión e Información corta (SIN CARD)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MISIÓN, VISIÓN Y COMPROMISO INSTITUCIONAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.38,
                    color: context.cTextSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Misión: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const TextSpan(
                      text:
                          'Garantizar la prestación eficiente y continua de los servicios de Acueducto, Aseo y Alcantarillado para el bienestar y salud de la ciudad.\n',
                    ),
                    TextSpan(
                      text: 'Visión: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const TextSpan(
                      text:
                          'Consolidarnos como la empresa pública líder en sostenibilidad ambiental, innovación operativa y calidad de vida en la región.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
