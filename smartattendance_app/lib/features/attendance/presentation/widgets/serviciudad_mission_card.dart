// ============================================================================
// ARCHIVO: serviciudad_mission_card.dart
// QUÉ HACE: Tarjeta institucional Frosted Glass con el logo oficial de Serviciudad
//           E.S.P., misión y visión corporativa y los 4 pilares operativos.
// CÓMO FUNCIONA: Presenta el logo transparente en alta resolución sobre una
//                superficie translúcida `IosGlassCard` con tipografía ejecutiva.
// POR QUÉ: Comunica la identidad corporativa y el propósito del sistema (< 190 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadMissionCard extends StatelessWidget {
  const ServiciudadMissionCard({super.key});

  Widget _buildPillar(BuildContext context, {required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.cSurface.withValues(alpha: context.isDark ? 0.45 : 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cBorder.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                Text(desc, style: TextStyle(fontSize: 10, color: context.cTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IosGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/serviciudad_logo.png',
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.drop_fill, size: 48, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'SERVICIUDAD E.S.P.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Acueducto · Alcantarillado · Aseo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.quote_bubble, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'MISIÓN INSTITUCIONAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '“Prestamos servicios públicos domiciliarios de acueducto, alcantarillado y aseo con eficiencia, calidad y continuidad, mejorando la calidad de vida de nuestros usuarios.”',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: context.cTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              'OBJETIVOS OPERATIVOS EN CAMPO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.cTextSecondary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildPillar(context, icon: CupertinoIcons.timer, title: 'Eficiencia', desc: 'Cuadrillas y rutas')),
              const SizedBox(width: 8),
              Expanded(child: _buildPillar(context, icon: CupertinoIcons.checkmark_seal_fill, title: 'Calidad', desc: 'Control de servicio')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildPillar(context, icon: CupertinoIcons.arrow_2_circlepath, title: 'Continuidad', desc: 'Supervisión activa')),
              const SizedBox(width: 8),
              Expanded(child: _buildPillar(context, icon: CupertinoIcons.heart_fill, title: 'Bienestar', desc: 'Impacto ciudadano')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Modernización operativa y control geoespacial de cuadrillas en Dosquebradas y Risaralda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: context.cTextSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
