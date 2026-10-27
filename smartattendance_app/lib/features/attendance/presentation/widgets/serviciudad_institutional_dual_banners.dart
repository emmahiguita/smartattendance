// ============================================================================
// ARCHIVO: serviciudad_institutional_dual_banners.dart
// QUÉ HACE: Tarjetas duales institucionales al pie de Inicio ("Cuidemos el agua"
//           y "Una ciudad más limpia") idénticas a la maqueta oficial de Serviciudad.
// CÓMO FUNCIONA: Presenta dos tarjetas con esquinas de 16px, imagen de fondo
//                con degradado oscuro, tipografía blanca accesible y chevron verde.
// POR QUÉ: Réplica exacta de la sección publicitaria de la imagen (< 130 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';

class ServiciudadInstitutionalDualBanners extends StatelessWidget {
  const ServiciudadInstitutionalDualBanners({super.key});

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String bannerAsset,
    required IconData icon,
    bool showChevron = false,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(bannerAsset, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      child: Icon(icon, size: 13, color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (showChevron)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2E7D32),
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.chevron_right, size: 11, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard(
          context: context,
          title: 'Cuidemos el agua',
          subtitle: 'Un mejor mañana empieza hoy.',
          bannerAsset: AppAssets.bannerAcueducto,
          icon: CupertinoIcons.drop_fill,
        ),
        const SizedBox(width: 10),
        _buildCard(
          context: context,
          title: 'Una ciudad más limpia',
          subtitle: 'Es tarea de todos.',
          bannerAsset: AppAssets.bannerAseo,
          icon: CupertinoIcons.trash_fill,
          showChevron: true,
        ),
      ],
    );
  }
}
