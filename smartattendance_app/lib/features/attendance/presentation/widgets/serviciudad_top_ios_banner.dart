// ============================================================================
// ARCHIVO: serviciudad_top_ios_banner.dart
// QUÉ HACE: Carrusel superior SIN CARD con las 3 fotografías operativas
//           enviadas por el usuario (`bannerInicioCuadrillaDia`,
//           `bannerInicioNocturno` y `bannerInicioAlcantarillado`), que van
//           pasando automáticamente cada 5 segundos con desvanecimiento iOS
//           opaco hacia el fondo de la pantalla, seguido del texto de Misión y Visión.
// CÓMO FUNCIONA:
// 1. `Timer.periodic(Duration(seconds: 5))` avanza el `PageController` entre
//    las 3 imágenes enviadas, mostrándolas completas (`BoxFit.fill`).
// 2. `ShaderMask` funde el borde inferior con el fondo de la pantalla sin card.
// POR QUÉ: Muestra todas las imágenes enviadas por el usuario pasando cada
//          5 segundos (< 160 líneas).
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadTopIosBanner extends StatefulWidget {
  const ServiciudadTopIosBanner({super.key});

  @override
  State<ServiciudadTopIosBanner> createState() => _ServiciudadTopIosBannerState();
}

class _ServiciudadTopIosBannerState extends State<ServiciudadTopIosBanner> {
  static const List<String> _banners = [
    AppAssets.bannerInicioCuadrillaDia,
    AppAssets.bannerInicioNocturno,
    AppAssets.bannerInicioAlcantarillado,
  ];

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isLandscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Carrusel de las 3 imágenes enviadas SIN CARD (pasan cada 5 segundos)
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLandscape ? 520 : double.infinity),
            child: AspectRatio(
              aspectRatio: 1024 / 600,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.94 : 0.98),
                        Colors.white.withValues(alpha: isDark ? 0.88 : 0.94),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.80, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _banners.length,
                      onPageChanged: (idx) => setState(() => _currentIndex = idx),
                      itemBuilder: (_, idx) => Image.asset(
                        _banners[idx],
                        width: double.infinity,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_banners.length, (i) {
                        final active = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : context.cTextSecondary.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Bloque puramente textual: Título + Misión y Visión (SIN CARD)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MISIÓN, VISIÓN Y COMPROMISO INSTITUCIONAL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12, height: 1.38, color: context.cTextSecondary),
                  children: [
                    TextSpan(text: 'Misión: ', style: TextStyle(fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                    const TextSpan(text: 'Garantizar la prestación eficiente y continua de los servicios de Acueducto, Aseo y Alcantarillado para el bienestar y salud de la ciudad.\n'),
                    TextSpan(text: 'Visión: ', style: TextStyle(fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                    const TextSpan(text: 'Consolidarnos como la empresa pública líder en sostenibilidad ambiental, innovación operativa y calidad de vida en la región.'),
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
