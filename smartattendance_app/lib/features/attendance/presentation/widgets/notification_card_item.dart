// lib/features/attendance/presentation/widgets/notification_card_item.dart
// ============================================================================
// ARCHIVO: notification_card_item.dart
// QUÉ HACE: Renderiza filas de notificación limpias y ejecutivas estilo Apple HIG,
//           sin iconos infantiles, círculos saturados ni componentes redundantes.
// CÓMO FUNCIONA: Utiliza [IosGlassCard] con barra indicadora de estado mínima
//                (3px), tipografía nítida y alineación tabular de hora.
// POR QUÉ: Directiva del usuario: "DEPURA NOTIFICACIONES ESOS ICONOS NO SON
//          PROFESIONAL NO DEBEN HABER ESE TIPO DE ICONOS LIMPIALOS HAZLO LIMPIO" (< 100 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_theme.dart';

class ConfirmedNotificationCard extends StatelessWidget {
  const ConfirmedNotificationCard({super.key, required this.item});

  final ConfirmedJourneyNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: IosGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3.5,
              height: 34,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        item.hora,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.detalle,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: context.cTextSecondary,
                    ),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: IosGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3.5,
              height: 34,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: reminder.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reminder.detalle,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: context.cTextSecondary,
                    ),
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
