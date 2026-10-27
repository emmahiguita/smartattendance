// ============================================================================
// ARCHIVO: hr_schedules_tab.dart
// QUÉ HACE: Pestaña 2 de Gestión RRHH ("Horarios") con el Calendario Visual
//           Apple iOS integrado para inspeccionar cobertura por fecha, gestionar
//           plantillas de turno y asignar horarios a cada colaborador.
// CÓMO FUNCIONA: Reúne `IosCalendarMonthGrid`, `HrShiftTemplatesStrip` y la
//                lista agrupada estilo iOS de `HrWorkerScheduleTile`.
// POR QUÉ: Coloca el calendario donde realmente sirve al Administrador (en la
//          asignación de horarios) y mantiene el código < 175 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../history/presentation/widgets/ios_calendar_month_grid.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/shift_template_dialog.dart';
import 'bulk_shift_assignment_dialog.dart';
import 'hr_shift_templates_strip.dart';
import 'hr_worker_schedule_tile.dart';

class HrSchedulesTab extends ConsumerStatefulWidget {
  const HrSchedulesTab({super.key});
  @override
  ConsumerState<HrSchedulesTab> createState() => _HrSchedulesTabState();
}

class _HrSchedulesTabState extends ConsumerState<HrSchedulesTab> {
  late DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _searchWorker = '', _workerFilter = 'all';

  void _showShiftDialog({ShiftTemplate? template}) {
    ShiftTemplateDialog.show(context, template: template).then((saved) {
      if (saved == true && mounted) ref.invalidate(shiftTemplatesProvider);
    });
  }

  Future<void> _deleteShift(ShiftTemplate template) async {
    if (template.id == null) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar Turno'),
        content: Text('¿Deseas eliminar la plantilla "${template.name}"?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(localAdminStoreProvider).deleteShiftTemplate(template.id!);
      ref.invalidate(shiftTemplatesProvider);
    }
  }

  Future<void> _assignShift(LocalWorker worker, ShiftTemplate template) async {
    await ref.read(localAdminStoreProvider).assignShiftToWorkers(workerIds: [worker.id], template: template);
    ref.invalidate(localWorkersProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Horario "${template.name}" asignado a ${worker.name}.'),
        backgroundColor: AppColors.systemGreen,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _removeSchedule(LocalWorker worker) async {
    await ref.read(localAdminStoreProvider).removeScheduleFromWorker(worker.id);
    ref.invalidate(localWorkersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(localWorkersProvider).valueOrNull ?? const [];
    final templates = ref.watch(shiftTemplatesProvider).valueOrNull ?? const [];
    final filtered = workers.where((w) {
      if (_workerFilter == 'with' && w.schedule == null) return false;
      if (_workerFilter == 'without' && w.schedule != null) return false;
      if (_searchWorker.isEmpty) return true;
      final t = _searchWorker.toLowerCase();
      return w.name.toLowerCase().contains(t) || w.document.contains(t);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      IosCalendarMonthGrid(
        focusedMonth: _focusedMonth,
        selectedDate: _selectedDate,
        workers: workers,
        onSelectDate: (d) => setState(() => _selectedDate = d),
        onPreviousMonth: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1)),
        onNextMonth: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1)),
        onToday: () {
          final now = DateTime.now();
          setState(() => (_focusedMonth = DateTime(now.year, now.month, 1), _selectedDate = DateTime(now.year, now.month, now.day)));
        },
        onBulkAssign: () => BulkShiftAssignmentDialog.show(context, workers: workers),
      ),
      const SizedBox(height: 16),
      HrShiftTemplatesStrip(
        workers: workers,
        templates: templates,
        onCreateShift: () => _showShiftDialog(),
        onEditShift: (t) => _showShiftDialog(template: t),
        onDeleteShift: _deleteShift,
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Text('ASIGNACIÓN POR COLABORADOR (${filtered.length})', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: context.cTextSecondary)),
      ),
      CupertinoSlidingSegmentedControl<String>(
        groupValue: _workerFilter,
        backgroundColor: context.cSurface,
        thumbColor: AppColors.primary,
        children: {
          'all': _segText('Todos', _workerFilter == 'all'),
          'with': _segText('Con horario', _workerFilter == 'with'),
          'without': _segText('Sin horario', _workerFilter == 'without'),
        },
        onValueChanged: (v) => setState(() => _workerFilter = v ?? 'all'),
      ),
      const SizedBox(height: 8),
      CupertinoSearchTextField(
        placeholder: 'Buscar colaborador por nombre o cédula…',
        style: TextStyle(fontSize: 13, color: context.cTextPrimary),
        onChanged: (v) => setState(() => _searchWorker = v),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cBorder, width: 0.5)),
        child: Column(children: [
          for (var i = 0; i < filtered.length; i++) ...[
            HrWorkerScheduleTile(
              worker: filtered[i],
              templates: templates,
              activeWeekday: _selectedDate.weekday,
              onAssignShift: (t) => _assignShift(filtered[i], t),
              onRemoveSchedule: () => _removeSchedule(filtered[i]),
            ),
            if (i < filtered.length - 1) Divider(height: 1, thickness: 0.5, indent: 54, color: context.cBorder),
          ],
        ]),
      ),
    ]);
  }

  Widget _segText(String text, bool sel) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Colors.white : context.cTextPrimary)),
      );
}
