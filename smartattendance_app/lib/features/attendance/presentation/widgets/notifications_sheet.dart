// lib/features/attendance/presentation/widgets/notifications_sheet.dart
// ============================================================================
// ARCHIVO: notifications_sheet.dart
// QUÉ HACE: Sábana flotante de notificaciones estilo Apple iOS Liquid Glass.
// CÓMO FUNCIONA: Utiliza `showIosFloatingGlassSheet`, suspendida sobre la interfaz
//                con desenfoque gaussiano 30px, esquinas 28dp y sin abrirse desde abajo.
// POR QUÉ: Directriz de diseño: "DEBE SER ESTILO IOS TRASPARENTE Y SABANA FLOTANTE
//          GLASSES LOS MENU NO ABREN NUNCA DESDE ABAJO" (< 145 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../domain/entities/attendance_entity.dart';
import 'notification_card_item.dart';

void showJourneyNotificationsSheet(BuildContext context, WidgetRef ref) {
  showIosFloatingGlassSheet<void>(
    context: context,
    title: 'Notificaciones de Jornada',
    subtitle: 'Actividad confirmada y recordatorios de hoy',
    maxHeightFactor: 0.76,
    child: Consumer(
      builder: (ctx, refConsumer, _) {
        final records = refConsumer.watch(localDayHistoryProvider).valueOrNull ??
            const <AttendanceEntity>[];
        final confirmed = computeConfirmedNotifications(records);
        final reminders = computeJourneyReminders(records);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          shrinkWrap: true,
          children: [
            if (confirmed.isNotEmpty) ...[
              _buildSectionTitle(ctx, 'ACTIVIDAD CONFIRMADA'),
              const SizedBox(height: 8),
              ...confirmed.map((item) => ConfirmedNotificationCard(item: item)),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle(ctx, 'ESTADO Y PRÓXIMOS PASOS'),
            const SizedBox(height: 8),
            if (reminders.isNotEmpty)
              ...reminders.map((r) => ReminderNotificationCard(reminder: r))
            else if (confirmed.isNotEmpty)
              _buildUpToDateCard(ctx)
            else
              _buildEmptyCard(ctx),
          ],
        );
      },
    ),
  );
}

Widget _buildSectionTitle(BuildContext context, String title) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: context.cGray,
      letterSpacing: 0.6,
    ),
  );
}

Widget _buildUpToDateCard(BuildContext context) {
  return IosGlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 3.5,
          height: 24,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.systemGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(
            'Jornada al día — sin alertas ni acciones pendientes',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.cTextPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyCard(BuildContext context) {
  return IosGlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 3.5,
          height: 24,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: context.cTextSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(
            'Sin registros de jornada para el día de hoy',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.cTextSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
