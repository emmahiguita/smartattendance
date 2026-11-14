// ============================================================================
// ARCHIVO: worker_management_details.dart
// QUÉ HACE: Presenta datos y acciones de gestión del trabajador en hoja iOS.
// CÓMO FUNCIONA: Organiza secciones compactas con divisores finos (0.5px) y
//                filas de altura ajustada (8px vertical) sin espacios muertos.
// POR QUÉ: Mantiene toda la ficha visible en la sub-pantalla (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import 'staff_status_types.dart';
import 'worker_hr_overtime_section.dart';

class WorkerManagementDetails extends StatelessWidget {
  const WorkerManagementDetails({
    super.key,
    required this.worker,
    required this.latestDay,
    required this.loadingDay,
    required this.reviewing,
    required this.canDelete,
    required this.onAssignment,
    required this.onPassword,
    required this.onCapture,
    required this.onDelete,
    required this.onApplySchedule,
    required this.onReviewOvertime,
    this.message,
  });

  final LocalWorker worker;
  final PhotoDay? latestDay;
  final bool loadingDay, reviewing, canDelete;
  final String? message;
  final VoidCallback onAssignment,
      onPassword,
      onCapture,
      onDelete,
      onApplySchedule;
  final ValueChanged<bool> onReviewOvertime;

  @override
  Widget build(BuildContext context) {
    final status =
        calculateStaffStatus(worker, ColombiaClock.day(DateTime.now()));
    final div = Divider(height: 1, thickness: 0.5, color: context.cBorder);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(worker.name,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.cTextPrimary)),
        const SizedBox(height: 2),
        Text('${worker.job} · C.C. ${worker.document} · ${status.label}',
            style: TextStyle(fontSize: 12.5, color: context.cTextSecondary)),
        if (message != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message!,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary))),
        const SizedBox(height: 10),
        div,
        _row(
            context,
            'Horario pactado',
            worker.schedule != null
                ? '${worker.schedule!.shiftName ?? "Jornada"} · ${worker.schedule!.timeWindowFormattedDual}'
                : 'Sin horario asignado'),
        _row(context, 'Equipo', worker.crewName ?? 'Sin equipo'),
        _row(context, 'Sitio de trabajo',
            worker.zoneName ?? 'Sin sitio asignado'),
        const SizedBox(height: 10),
        WorkerHrOvertimeSection(
          latestDay: latestDay,
          loading: loadingDay,
          reviewing: reviewing,
          isDark: context.isDark,
          onApplySchedule: onApplySchedule,
          onReviewOvertime: onReviewOvertime,
        ),
        const SizedBox(height: 10),
        div,
        _actionRow(
            context, CupertinoIcons.lock, 'Establecer contraseña', onPassword),
        div,
        _actionRow(context, CupertinoIcons.camera,
            'Registrar asistencia facial', onCapture),
        if (canDelete) ...[
          div,
          _actionRow(context, CupertinoIcons.person_badge_minus,
              'Desvincular colaborador', onDelete),
        ],
        div,
      ]),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Column(
        children: [
          InkWell(
            onTap: onAssignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                color: context.cTextSecondary, fontSize: 12)),
                        const SizedBox(height: 1),
                        Text(value,
                            style: TextStyle(
                                color: context.cTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
                Icon(CupertinoIcons.chevron_forward,
                    size: 14, color: context.cTextSecondary),
              ]),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
        ],
      );

  Widget _actionRow(BuildContext context, IconData icon, String title,
          VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            Icon(icon, size: 18, color: context.cTextSecondary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.cTextPrimary))),
            Icon(CupertinoIcons.chevron_forward,
                size: 14, color: context.cTextSecondary),
          ]),
        ),
      );
}
