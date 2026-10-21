// lib/features/attendance/presentation/widgets/notifications_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../domain/entities/attendance_entity.dart';
import 'notification_card_item.dart';

/// ============================================================================
/// UTILIDAD: showJourneyNotificationsSheet (Estilo Apple iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Despliega el modal de notificaciones y recordatorios de la jornada:
/// 1. Notifica las marcaciones confirmadas hoy (Entrada, Almuerzo, etc. con hora real).
/// 2. Elimina la inconsistencia de "Entrada pendiente" una vez se ha entrado.
/// 3. Muestra recordatorios de próximos pasos con estética Apple HIG.
///
/// CÓMO FUNCIONA:
/// Observa de forma reactiva [localDayHistoryProvider] en tiempo real.
///
/// POR QUÉ:
/// Cumple con la directriz del usuario: "al abrir notificaciones debe notificar
/// que se entró y ya no mostrar entrada pendiente" (< 140 líneas).
/// ============================================================================
void showJourneyNotificationsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (ctx) => Consumer(
      builder: (context, refConsumer, _) {
        final records = refConsumer.watch(localDayHistoryProvider).valueOrNull ??
            const <AttendanceEntity>[];
        final confirmed = computeConfirmedNotifications(records);
        final reminders = computeJourneyReminders(records);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.cBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notificaciones de Jornada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.cTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Actividad confirmada y recordatorios de hoy',
                            style: TextStyle(fontSize: 12, color: context.cGray),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (confirmed.isNotEmpty) ...[
                          _buildSectionTitle(context, 'ACTIVIDAD CONFIRMADA'),
                          const SizedBox(height: 8),
                          ...confirmed.map((item) => ConfirmedNotificationCard(item: item)),
                          const SizedBox(height: 16),
                        ],
                        _buildSectionTitle(context, 'ESTADO Y PRÓXIMOS PASOS'),
                        const SizedBox(height: 8),
                        if (reminders.isNotEmpty)
                          ...reminders.map((r) => ReminderNotificationCard(reminder: r))
                        else if (confirmed.isNotEmpty)
                          _buildUpToDateCard(context)
                        else
                          _buildEmptyCard(context),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.systemGreen,
          child: Icon(Icons.check_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Jornada al día — sin alertas ni acciones pendientes',
            style: TextStyle(fontSize: 12.5, color: context.cTextPrimary),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyCard(BuildContext context) {
  return IosGlassCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: context.cGray.withValues(alpha: 0.12),
          child: Icon(Icons.info_outline_rounded, color: context.cGray, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Sin registros de jornada para el día de hoy',
            style: TextStyle(fontSize: 12.5, color: context.cGray),
          ),
        ),
      ],
    ),
  );
}
