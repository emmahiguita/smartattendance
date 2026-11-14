// ============================================================================
// ARCHIVO: hr_overtime_card.dart
// QUÉ HACE: Presenta una jornada y las decisiones de tiempo adicional en filas iOS.
// CÓMO FUNCIONA: Compacta el espaciado vertical (8px) y separa identidad,
//                totales y acciones con divisor fino de 0.5px.
// POR QUÉ: Evita espacios vacíos grandes entre registros de horas extras.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';

class HrOvertimeCard extends StatelessWidget {
  const HrOvertimeCard({
    super.key,
    required this.day,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final PhotoDay day;
  final bool busy;
  final VoidCallback onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    final extra = day.totals.additional ?? Duration.zero;
    final pending = day.approvedSeconds == null && extra.inSeconds > 0;
    final status = pending
        ? 'Extra pendiente'
        : day.approvedSeconds == 0
            ? 'Rechazada'
            : (day.approvedSeconds ?? 0) > 0
                ? 'Aprobada'
                : day.status == 'open'
                    ? 'En curso'
                    : 'Ordinaria';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            day.worker.name,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${day.worker.job} · ${ColombiaClock.day(day.worker.capturedAt)} · $status',
            style: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
          ),
          const SizedBox(height: 6),
          _value(
            context,
            'Horario',
            day.schedule?.shiftName ??
                day.schedule?.timeWindowFormatted ??
                'Sin horario',
          ),
          _value(
            context,
            'Tiempo laborado',
            day.totals.worked == null
                ? 'En curso'
                : ColombiaClock.duration(day.totals.worked!),
          ),
          _value(context, 'Tiempo adicional', ColombiaClock.duration(extra)),
          if (pending) ...[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: busy ? null : onReject,
                  child: const Text('Rechazar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: busy ? null : onApprove,
                  child: const Text('Aprobar Extra'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
        ],
      ),
    );
  }

  Widget _value(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}
