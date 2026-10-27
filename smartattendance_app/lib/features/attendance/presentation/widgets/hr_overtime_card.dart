// ============================================================================
// ARCHIVO: hr_overtime_card.dart
// QUÉ HACE: Tarjeta de auditoría de jornada y tiempo adicional (Horas Extras)
//           estilo Apple iOS Inset Grouped para un `PhotoDay`.
// CÓMO FUNCIONA: Muestra el horario pactado, el tiempo laborado real, el
//           excedente calculado y permite al Administrador aprobar o rechazar
//           cuando existen horas extras pendientes.
// POR QUÉ: Desacopla la tarjeta de revisión de `HrOvertimeTab` (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';

class HrOvertimeCard extends StatelessWidget {
  final PhotoDay day;
  final bool busy;
  final VoidCallback onApprove, onReject;

  const HrOvertimeCard({super.key, required this.day, required this.busy, required this.onApprove, required this.onReject});

  String _formatDuration(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final additional = day.totals.additional ?? Duration.zero;
    final hasExtra = additional.inSeconds > 0;
    final isPending = day.approvedSeconds == null && hasExtra;
    final isApproved = day.approvedSeconds != null && day.approvedSeconds! > 0;
    final isRejected = day.approvedSeconds != null && day.approvedSeconds == 0;
    final scheduleLabel = day.schedule?.shiftName ?? day.schedule?.timeWindowFormatted ?? 'Sin horario';

    final statusColor = isPending
        ? AppColors.systemOrange
        : (isApproved ? AppColors.systemGreen : (isRejected ? AppColors.systemRed : AppColors.primary));
    final statusLabel = isPending
        ? 'Extra pendiente'
        : (isApproved ? 'Aprobada' : (isRejected ? 'Rechazada' : (day.status == 'open' ? 'En curso' : 'Ordinaria')));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? AppColors.systemOrange.withValues(alpha: 0.5) : context.cBorder, width: isPending ? 1.0 : 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(
              isPending ? CupertinoIcons.clock_fill : (isApproved ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.calendar_today),
              size: 16,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(day.worker.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${day.worker.job} · ${ColombiaClock.day(day.worker.capturedAt)} (${day.records.length} marcas)', style: TextStyle(fontSize: 11.5, color: context.cTextSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(color: context.cBackground.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.cBorder, width: 0.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _timeCol(context, 'Horario', scheduleLabel),
            Container(width: 0.5, height: 26, color: context.cBorder),
            _timeCol(context, 'Laborado', day.totals.worked != null ? ColombiaClock.duration(day.totals.worked!) : 'En curso'),
            Container(width: 0.5, height: 26, color: context.cBorder),
            _timeCol(context, 'Extra', hasExtra ? '+${_formatDuration(additional)}' : '0h', isHighlight: hasExtra),
          ]),
        ),
        if (isPending) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                color: AppColors.systemRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
                onPressed: busy ? null : onReject,
                child: const Text('Rechazar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemRed)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                color: AppColors.systemGreen,
                borderRadius: BorderRadius.circular(9),
                onPressed: busy ? null : onApprove,
                child: const Text('Aprobar Extra', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _timeCol(BuildContext context, String title, String value, {bool isHighlight = false}) => Flexible(
        child: Column(children: [
          Text(title, style: TextStyle(fontSize: 10.5, color: context.cTextSecondary)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isHighlight ? AppColors.systemOrange : context.cTextPrimary)),
        ]),
      );
}
