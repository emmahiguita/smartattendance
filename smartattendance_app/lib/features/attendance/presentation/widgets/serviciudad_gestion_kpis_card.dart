// ============================================================================
// ARCHIVO: serviciudad_gestion_kpis_card.dart
// QUÉ HACE: Tarjeta retrospectiva "Resultados de gestión 2025" que al pulsar
//           dirige directamente al informe oficial en serviciudad.gov.co.
// CÓMO FUNCIONA: Cuadrícula dual 2x2 Material 3 limpia con métricas de acueducto,
//                alcantarillado y aseo; abre la fuente real vía `url_launcher`.
// POR QUÉ: Atiende la directiva: "la información abajo al tocarla debe dirigir
//          al sitio real de donde salió la información" (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadGestionKpisCard extends StatelessWidget {
  const ServiciudadGestionKpisCard({super.key});

  static Future<void> _openOfficialReport(BuildContext context) async {
    const url = 'https://serviciudad.gov.co/index.php/transparencia';
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error al abrir reporte oficial: $e');
    }
  }

  Widget _buildKpiTile(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: context.cSurface.withValues(alpha: context.isDark ? 0.45 : 0.70),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.cBorder.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('2025', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: context.cTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
    return IosGlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _openOfficialReport(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'INFORME OFICIAL',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text('serviciudad.gov.co', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
                  const SizedBox(width: 3),
                  Icon(CupertinoIcons.arrow_up_right, size: 10, color: context.cTextSecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Resultados de gestión 2025',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.cTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Informe publicado el 8 de abril de 2026. Toca para ver informe completo.',
            style: TextStyle(fontSize: 11, color: context.cTextSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKpiTile(context, value: '4.866 m', label: 'Redes acueducto intervenidas', icon: CupertinoIcons.drop, color: AppColors.primary),
              const SizedBox(width: 8),
              _buildKpiTile(context, value: '2.875 m', label: 'Redes alcantarillado intervenidas', icon: CupertinoIcons.wrench, color: const Color(0xFF1E3A8A)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKpiTile(context, value: '980 m', label: 'Colectores intervenidos', icon: CupertinoIcons.layers_alt, color: AppColors.accent),
              const SizedBox(width: 8),
              _buildKpiTile(context, value: 'Vehículos', label: 'Aseo urbano y rural recuperados', icon: CupertinoIcons.car_detailed, color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}
