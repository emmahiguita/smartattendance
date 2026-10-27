// ============================================================================
// ARCHIVO: serviciudad_motion_carousel.dart
// QUÉ HACE: Carrusel institucional animado con imágenes 100% completas (sin recortar),
//           cifras operativas reales y redirección al portal oficial de Serviciudad.
// CÓMO FUNCIONA: Mantiene proporción nativa de banners, auto-avance suave, pausa táctil
//                y apertura del portal oficial del servicio vía `url_launcher`.
// POR QUÉ: Atiende la directiva: "la información abajo al tocarla debe dirigir
//          al sitio real, cards M3 limpias sin recortes" (< 190 líneas).
// ============================================================================

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadMotionCarousel extends StatefulWidget {
  const ServiciudadMotionCarousel({super.key});

  @override
  State<ServiciudadMotionCarousel> createState() => _ServiciudadMotionCarouselState();
}

class _ServiciudadMotionCarouselState extends State<ServiciudadMotionCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  static const _slides = [
    (
      title: 'Acueducto · Agua Potable',
      banner: AppAssets.bannerAcueducto,
      kpiText: 'Cobertura 99.4% · 4.866 m de redes optimizadas',
      url: 'https://serviciudad.gov.co/index.php/servicios/acueducto',
      accent: Color(0xFF0284C7),
      icon: CupertinoIcons.drop_fill,
    ),
    (
      title: 'Aseo · Limpieza Urbana',
      banner: AppAssets.bannerAseo,
      kpiText: '12 rutas activas · 380 km de barrido mensual',
      url: 'https://serviciudad.gov.co/index.php/servicios/aseo',
      accent: Color(0xFF10B981),
      icon: CupertinoIcons.leaf_arrow_circlepath,
    ),
    (
      title: 'Alcantarillado · Saneamiento',
      banner: AppAssets.bannerAlcantarillado,
      kpiText: '2.875 m de colectores · 1.450 sumideros limpios',
      url: 'https://serviciudad.gov.co/index.php/servicios/alcantarillado',
      accent: Color(0xFF1E3A8A),
      icon: CupertinoIcons.wrench_fill,
    ),
    (
      title: 'Visión 2026 · Sostenibilidad',
      banner: AppAssets.bannerZonas,
      kpiText: 'Autonomía hídrica regional y calidad certificada',
      url: 'https://serviciudad.gov.co/index.php/transparencia',
      accent: Color(0xFF0369A1),
      icon: CupertinoIcons.checkmark_shield_fill,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoPlay() => _autoPlayTimer?.cancel();

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openOfficialLink(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error al abrir URL del banner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 156,
          child: Listener(
            onPointerDown: (_) => _pauseAutoPlay(),
            onPointerUp: (_) => _startAutoPlay(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (ctx, i) {
                final s = _slides[i];
                return GestureDetector(
                  onTap: () => _openOfficialLink(s.url),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: context.cSurface.withValues(alpha: isDark ? 0.85 : 0.98),
                      border: Border.all(
                        color: s.accent.withValues(alpha: isDark ? 0.40 : 0.25),
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Imagen 100% Completa sin recortar con fondo slate
                        Expanded(
                          child: Container(
                            color: isDark ? const Color(0xFF0B1320) : const Color(0xFF0F172A),
                            child: Image.asset(
                              s.banner,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                color: s.accent,
                                child: Center(
                                  child: Icon(s.icon, size: 40, color: const Color(0x60FFFFFF)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Barra informativa inferior con redirección visible
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: context.cSurface,
                            border: Border(
                              top: BorderSide(
                                color: context.cBorder.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(s.icon, size: 13, color: s.accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s.kpiText,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.cTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.arrow_up_right, size: 11, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = _currentPage == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: active ? 20 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : context.cBorder.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2.5),
              ),
            );
          }),
        ),
      ],
    );
  }
}
