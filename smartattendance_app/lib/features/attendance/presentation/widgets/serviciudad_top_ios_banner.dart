// ============================================================================
// ARCHIVO: serviciudad_top_ios_banner.dart
// QUÉ HACE: Carrusel institucional de Serviciudad E.S.P. ubicado debajo del
//           encabezado del administrador/usuario sin recortar las imágenes.
// CÓMO FUNCIONA: Despliega las fotografías oficiales en su relación de aspecto
//                nativa exacta 16:9 (1024x576) con `BoxFit.fill` y transición
//                suave cada 5 segundos sin velos que oscurezcan o corten bordes.
// POR QUÉ: Evita que cascos, rostros o el logo de Serviciudad se vean cortados
//          y elimina imágenes duplicadas (< 140 líneas).
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_theme.dart';

/// Carrusel institucional sin recortes ubicado debajo del encabezado de usuario.
class ServiciudadTopIosBanner extends StatefulWidget {
  const ServiciudadTopIosBanner({super.key});

  @override
  State<ServiciudadTopIosBanner> createState() =>
      _ServiciudadTopIosBannerState();
}

class _ServiciudadTopIosBannerState extends State<ServiciudadTopIosBanner> {
  // QUÉ HACE: Lista única de los banners oficiales normalizados a 1024x576 (16:9).
  // CÓMO: Referencia las dos imágenes institucionales sin duplicados.
  // POR QUÉ: Garantiza visualización 100% completa sin recortes superiores/inferiores.
  static const List<String> _banners = [
    AppAssets.bannerServiciudadCiudadLimpia,
    AppAssets.bannerServiciudadAlcantarillado,
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
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isLandscape ? 520 : double.infinity),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.cBorder, width: 0.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1024 / 576,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (_, idx) => Image.asset(
                    _banners[idx],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) =>
                        ColoredBox(color: context.cSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 5,
              height: 3.5,
              decoration: BoxDecoration(
                color: active
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : context.cTextSecondary.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
