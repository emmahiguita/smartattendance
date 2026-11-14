// ============================================================================
// ARCHIVO: home_schedule_card.dart
// QUÉ HACE: Expone la asignación real de horario en una sección compacta iOS.
// CÓMO FUNCIONA: Muestra horario en formato dual colombiano (24h y 12h AM/PM)
//                y ventana permitida con espaciado vertical reducido (9px).
// POR QUÉ: Aprovecha la pantalla sin tarjetas ni divisores alejados (< 65 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';

class HomeScheduleCard extends StatelessWidget {
  const HomeScheduleCard({
    super.key,
    required this.schedule,
    this.assignedOvertimeMinutes = 0,
  });

  final WorkSchedule? schedule;
  final int assignedOvertimeMinutes;

  @override
  Widget build(BuildContext context) {
    final value = schedule;
    final extra = value?.assignedOvertimeMinutes ?? assignedOvertimeMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horario asignado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value == null
                ? 'Sin horario asignado'
                : '${value.shiftName ?? 'Jornada asignada'} · ${value.timeWindowFormattedDual}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value == null
                ? 'Consulta con tu administrador'
                : 'Ventana permitida para marcar: ${value.markWindowFormatted}',
            style: TextStyle(
              fontSize: 12.5,
              color: context.cTextSecondary,
            ),
          ),
          if (extra > 0) ...[
            const SizedBox(height: 2),
            Text(
              'Tiempo adicional autorizado: ${extra ~/ 60} h ${extra % 60} min',
              style: TextStyle(
                fontSize: 12.5,
                color: context.cTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
