// ============================================================================
// ARCHIVO: hr_worker_schedule_tile.dart
// QUÉ HACE: Fila compacta estilo Apple iOS para asignar, cambiar o quitar el
//           horario de un colaborador mediante un `CupertinoActionSheet`.
// CÓMO FUNCIONA: Muestra el horario dual colombiano (24h y 12h AM/PM) y al
//                tocar abre la hoja nativa de selección de turno.
// POR QUÉ: Elimina espacios excesivos entre divisores (< 95 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        message: const Text(
            'Selecciona una plantilla de turno oficial (24h / 12h Colombia)'),
        actions: [
          for (final t in templates)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                onAssignShift(t);
              },
              child: Text('${t.name} · ${t.timeFormattedDual}'),
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
        ? '${worker.schedule!.shiftName ?? "Jornada"} · ${worker.schedule!.timeWindowFormattedDual}'
        : 'Sin horario asignado';

    return InkWell(
      onTap: () => _showAssignSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 19,
              color: context.cTextSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$scheduleLabel${activeWeekday == null ? "" : worksOnDay ? " · Día laborable" : " · Día no laborable"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: context.cTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
