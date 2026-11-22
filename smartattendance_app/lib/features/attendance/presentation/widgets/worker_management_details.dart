// ============================================================================
// ARCHIVO: worker_management_details.dart
// QUÉ HACE: Presenta la vista de detalles y acciones de gestión del trabajador
//           en hoja modal estilo Apple iOS con iconografía azul (#007AFF) y
//           textos de alta legibilidad en iOS y Android.
// CÓMO FUNCIONA: Muestra cabecera ejecutiva con avatar e insignia de estado,
//                secciones con iconos azules (#007AFF) y divisores finos (0.5px).
// POR QUÉ: Mantiene toda la ficha visible y clara en la sub-pantalla (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
  final VoidCallback onAssignment, onPassword, onCapture, onDelete, onApplySchedule;
  final ValueChanged<bool> onReviewOvertime;

  static const Color _iosBlue = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final status = calculateStaffStatus(worker, ColombiaClock.day(DateTime.now()));
    final div = Divider(height: 1, thickness: 0.5, color: context.cBorder);
    final initial = worker.name.trim().isNotEmpty ? worker.name.trim()[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _iosBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _iosBlue.withValues(alpha: 0.28), width: 0.9),
            ),
            child: Text(initial, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _iosBlue)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(worker.name,
                  style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, letterSpacing: -0.25, color: context.cTextPrimary)),
              const SizedBox(height: 2),
              Text('${worker.job.isNotEmpty ? worker.job : 'Colaborador'} · C.C. ${worker.document}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: status.color.withValues(alpha: 0.35), width: 0.6),
            ),
            child: Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: status.color)),
          ),
        ]),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.systemGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(message!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemGreen)),
            ),
          ),
        const SizedBox(height: 12),
        div,
        _detailRow(
          context,
          CupertinoIcons.clock_fill,
          'Horario pactado',
          worker.schedule != null
              ? '${worker.schedule!.shiftName ?? "Jornada"} · ${worker.schedule!.timeWindowFormattedDual}'
              : 'Sin horario asignado (Toca para asignar)',
        ),
        _detailRow(context, CupertinoIcons.person_2_fill, 'Equipo / Cuadrilla', worker.crewName ?? 'Sin equipo asignado (Zona libre)'),
        _detailRow(context, CupertinoIcons.location_fill, 'Sitio de trabajo GPS', worker.zoneName ?? 'Sin sitio asignado'),
        const SizedBox(height: 12),
        WorkerHrOvertimeSection(
          latestDay: latestDay,
          loading: loadingDay,
          reviewing: reviewing,
          isDark: context.isDark,
          onApplySchedule: onApplySchedule,
          onReviewOvertime: onReviewOvertime,
        ),
        const SizedBox(height: 12),
        div,
        _actionRow(context, CupertinoIcons.slider_horizontal_3, 'Editar puesto, equipo, sitio y horario', onAssignment, iconColor: _iosBlue),
        div,
        _actionRow(context, CupertinoIcons.lock_fill, 'Establecer contraseña de acceso', onPassword, iconColor: const Color(0xFF5856D6)),
        div,
        _actionRow(context, CupertinoIcons.camera_fill, 'Registrar asistencia con fotografía', onCapture, iconColor: AppColors.systemGreen),
        if (canDelete) ...[
          div,
          _actionRow(context, CupertinoIcons.person_badge_minus, 'Desvincular colaborador de la nómina', onDelete,
              iconColor: AppColors.systemRed, isDestructive: true),
        ],
        div,
      ]),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) => Column(children: [
        InkWell(
          onTap: onAssignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _iosBlue.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 15.5, color: _iosBlue),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(color: context.cTextSecondary, fontSize: 11.8, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1.5),
                  Text(value, style: TextStyle(color: context.cTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
              Icon(CupertinoIcons.chevron_forward, size: 14, color: _iosBlue.withValues(alpha: 0.75)),
            ]),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: context.cBorder),
      ]);

  Widget _actionRow(BuildContext context, IconData icon, String title, VoidCallback onTap,
          {required Color iconColor, bool isDestructive = false}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? AppColors.systemRed : context.cTextPrimary)),
            ),
            Icon(CupertinoIcons.chevron_forward, size: 14, color: context.cTextSecondary),
          ]),
        ),
      );
}
