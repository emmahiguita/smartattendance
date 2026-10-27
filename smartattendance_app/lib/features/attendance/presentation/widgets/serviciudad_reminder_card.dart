// ============================================================================
// ARCHIVO: serviciudad_reminder_card.dart
// QUÉ HACE: Tarjeta Frosted Glass de recordatorio inteligente de asistencia
//           basada en turnos reales y marcaciones del día (`JourneyReminder`).
// CÓMO FUNCIONA: Muestra la próxima acción sugerida, tiempo restante o estado
//                "Jornada al día" con botón directo para marcar.
// POR QUÉ: Satisface la especificación Serviciudad Mobile (< 180 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ServiciudadReminderCard extends StatelessWidget {
  const ServiciudadReminderCard({
    super.key,
    required this.reminders,
    this.onActionTap,
  });

  final List<JourneyReminder> reminders;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final hasReminder = reminders.isNotEmpty;
    final r = hasReminder ? reminders.first : null;

    final title = r?.titulo ?? 'Recordatorio de Marcación';
    final desc = r?.detalle ?? 'Te avisaremos 10 minutos antes de tu siguiente evento de jornada.';
    final isWarning = r?.level == ReminderLevel.warning;
    final statusColor = isWarning ? AppColors.warning : AppColors.primary;

    return IosGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
              border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.iconoAsistencia,
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => Icon(CupertinoIcons.bell_fill, size: 18, color: statusColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                      ),
                    ),
                    if (isWarning) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Pendiente', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.warning)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: context.cTextSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasReminder && onActionTap != null) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              onPressed: onActionTap,
              child: const Text('Marcar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: CupertinoColors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
