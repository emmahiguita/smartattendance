// lib/features/attendance/presentation/widgets/notification_card_item.dart
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: NotificationCardItem (Estilo Apple iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Renderiza tarjetas individuales de notificación para el modal de jornada:
/// marcación confirmada, recordatorio pendiente o estado al día.
///
/// CÓMO FUNCIONA:
/// Emplea [IosGlassCard] con iconos circulares traslúcidos y cifras tabulares.
///
/// POR QUÉ:
/// Desacopla la vista de la tarjeta de la lista principal (< 110 líneas).
/// ============================================================================
class ConfirmedNotificationCard extends StatelessWidget {
  const ConfirmedNotificationCard({super.key, required this.item});

  final ConfirmedJourneyNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IosGlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: item.color.withValues(alpha: 0.12),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.titulo,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary,
                        ),
                      ),
                      Text(
                        item.hora,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.detalle,
                    style: TextStyle(fontSize: 11.5, color: context.cGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderNotificationCard extends StatelessWidget {
  const ReminderNotificationCard({super.key, required this.reminder});

  final JourneyReminder reminder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IosGlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: reminder.color.withValues(alpha: 0.12),
              child: Icon(reminder.icon, color: reminder.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.titulo,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reminder.detalle,
                    style: TextStyle(fontSize: 11.5, color: context.cGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
