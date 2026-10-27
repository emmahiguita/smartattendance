// ============================================================================
// ARCHIVO: serviciudad_services_strip.dart
// QUÉ HACE: Tira de servicios públicos (Acueducto, Aseo, Alcantarillado) estilo
//           Material 3 Limpio que al tocar abre el sitio oficial real de Serviciudad.
// CÓMO FUNCIONA: Despliega 3 tarjetas ejecutivas; al pulsar, abre directamente la
//                página web oficial del servicio en el navegador vía `url_launcher`.
// POR QUÉ: Atiende la directiva: "la información abajo al tocarla debe dirigir al
//          sitio real de donde salió la información, M3 limpio" (< 160 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadServicesStrip extends StatelessWidget {
  const ServiciudadServicesStrip({super.key});

  static Future<void> _launchOfficialUrl(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abriendo portal: $urlString'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al abrir URL oficial: $e');
    }
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String url,
    required String iconAsset,
    required IconData fallbackIcon,
    required Color color,
  }) {
    final isDark = context.isDark;

    return Expanded(
      child: IosGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        onTap: () => _launchOfficialUrl(context, url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: isDark ? 0.40 : 0.25),
                      width: 0.9,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 18, color: color),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.arrow_up_right,
                  size: 13,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: context.cTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: context.cTextSecondary,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Servicios públicos domiciliarios',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.cTextSecondary,
                letterSpacing: 0.2,
              ),
            ),
            GestureDetector(
              onTap: () => _launchOfficialUrl(context, 'https://serviciudad.gov.co'),
              child: const Row(
                children: [
                  Text(
                    'serviciudad.gov.co',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(CupertinoIcons.arrow_up_right, size: 10, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildServiceCard(
              context,
              title: 'Acueducto',
              subtitle: 'Agua potable para Dosquebradas',
              url: 'https://serviciudad.gov.co/index.php/servicios/acueducto',
              iconAsset: AppAssets.iconoAcueducto,
              fallbackIcon: CupertinoIcons.drop_fill,
              color: const Color(0xFF0077B6),
            ),
            const SizedBox(width: 8),
            _buildServiceCard(
              context,
              title: 'Aseo',
              subtitle: 'Rutas de recolección y barrido',
              url: 'https://serviciudad.gov.co/index.php/servicios/aseo',
              iconAsset: AppAssets.iconoAseo,
              fallbackIcon: CupertinoIcons.trash_fill,
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(width: 8),
            _buildServiceCard(
              context,
              title: 'Alcantarillado',
              subtitle: 'Saneamiento e infraestructura',
              url: 'https://serviciudad.gov.co/index.php/servicios/alcantarillado',
              iconAsset: AppAssets.iconoAlcantarillado,
              fallbackIcon: CupertinoIcons.shield_fill,
              color: const Color(0xFFD97706),
            ),
          ],
        ),
      ],
    );
  }
}
