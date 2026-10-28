// ============================================================================
// ARCHIVO: serviciudad_top_ios_banner.dart
// QUÉ HACE: Carrusel superior SIN CARD con las fotografías operativas oficiales
//           enviadas por el usuario pasando cada 5 segundos con desvanecimiento
//           iOS opaco hacia el fondo de la pantalla y el logo oficial de
//           Serviciudad E.S.P., SIN texto de Misión ni Visión.
// CÓMO FUNCIONA:
// 1. `Timer.periodic(Duration(seconds: 5))` avanza el `PageController` entre
//    las imágenes enviadas, mostrándolas completas (`BoxFit.fill`).
// 2. `ShaderMask` funde el borde inferior con el fondo de la pantalla y muestra
//    el logo institucional oficial (`AppAssets.logoOficialReal`).
// POR QUÉ: Cumple la directiva "sin mision y vision solo las imagenes y el logo"
//          manteniendo el código en < 130 líneas.
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
    AppAssets.bannerInicioCalidadVida,
    AppAssets.bannerInicioRedesTuberia,
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
                        Colors.white.withValues(alpha: isDark ? 0.95 : 0.99),
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
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        AppAssets.logoOficialReal,
                        height: 28,
                        fit: BoxFit.contain,
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
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: active ? 16 : 6,
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
      ],
    );
  }
}
