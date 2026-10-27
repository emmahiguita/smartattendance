// ============================================================================
// ARCHIVO: hr_worker_schedule_tile.dart
// QUÉ HACE: Fila estilo Apple iOS Inset Grouped para asignar, cambiar o quitar
//           el horario de un colaborador mediante un `CupertinoActionSheet`.
// CÓMO FUNCIONA: Al tocar la fila o el botón de horario, abre una hoja de
//                acción nativa iOS con todas las plantillas de turno activas.
// POR QUÉ: Elimina botones Material recargados y menús desalineados (< 145 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';

class HrWorkerScheduleTile extends StatelessWidget {
  final LocalWorker worker;
  final List<ShiftTemplate> templates;
  final int? activeWeekday;
  final ValueChanged<ShiftTemplate> onAssignShift;
  final VoidCallback onRemoveSchedule;

  const HrWorkerScheduleTile({
    super.key,
    required this.worker,
    required this.templates,
    this.activeWeekday,
    required this.onAssignShift,
    required this.onRemoveSchedule,
  });

  void _showAssignSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Asignar horario a ${worker.name}'),
        message: const Text('Selecciona una plantilla de turno oficial'),
        actions: [
          for (final t in templates)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                onAssignShift(t);
              },
              child: Text('${t.name} (${t.timeFormatted})'),
            ),
          if (worker.schedule != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                onRemoveSchedule();
              },
              child: const Text('Quitar horario asignado'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSchedule = worker.schedule != null;
    final worksOnDay = activeWeekday == null ||
        (worker.schedule?.weekdays.contains(activeWeekday) ?? false);
    final scheduleLabel = hasSchedule
        ? '${worker.schedule!.shiftName ?? "Jornada"} · ${worker.schedule!.timeWindowFormatted}'
        : 'Sin horario asignado';

    return InkWell(
      onTap: () => _showAssignSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasSchedule
                    ? (worksOnDay
                        ? AppColors.systemGreen.withValues(alpha: 0.14)
                        : AppColors.primary.withValues(alpha: 0.14))
                    : AppColors.systemOrange.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSchedule
                    ? CupertinoIcons.calendar_badge_plus
                    : CupertinoIcons.exclamationmark_circle,
                size: 16,
                color: hasSchedule
                    ? (worksOnDay ? AppColors.systemGreen : AppColors.primary)
                    : AppColors.systemOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    scheduleLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: hasSchedule
                          ? context.cTextSecondary
                          : AppColors.systemOrange,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              hasSchedule ? 'Cambiar' : 'Asignar',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_forward,
                size: 14, color: context.cTextSecondary),
          ],
        ),
      ),
    );
  }
}
