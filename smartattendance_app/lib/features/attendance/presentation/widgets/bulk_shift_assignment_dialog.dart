// ============================================================================
// ARCHIVO: bulk_shift_assignment_dialog.dart
// QUÉ HACE: Ventana flotante estilo Apple iOS (`IosFloatingModal`) para asignar
//           una plantilla de turno (`ShiftTemplate`) en bloque a múltiples
//           colaboradores desde el calendario de Horarios.
// CÓMO FUNCIONA: Usa `CupertinoSearchTextField` y listas `IosFormGroup` con
//                selección múltiple para aplicar turnos masivos en SQLite.
// POR QUÉ: Sustituye el `AlertDialog` Material por una ventana flotante iOS
//          limpia y cumple SRP (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

class BulkShiftAssignmentDialog extends ConsumerStatefulWidget {
  const BulkShiftAssignmentDialog({super.key, required this.workers});
  final List<LocalWorker> workers;

  static Future<bool?> show(BuildContext context, {required List<LocalWorker> workers}) =>
      showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => BulkShiftAssignmentDialog(workers: workers));

  @override
  ConsumerState<BulkShiftAssignmentDialog> createState() => _BulkShiftAssignmentDialogState();
}

class _BulkShiftAssignmentDialogState extends ConsumerState<BulkShiftAssignmentDialog> {
  final Set<int> _selectedIds = {};
  ShiftTemplate? _selectedTemplate;
  bool _saving = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    for (final w in widget.workers) {
      if (w.schedule == null) _selectedIds.add(w.id);
    }
    if (_selectedIds.isEmpty) _selectedIds.addAll(widget.workers.map((w) => w.id));
  }

  Future<void> _assign() async {
    if (_selectedTemplate == null || _selectedIds.isEmpty) {
      setState(() => _error = 'Selecciona un turno y al menos un colaborador.');
      return;
    }
    setState(() => (_saving = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).assignShiftToWorkers(workerIds: _selectedIds.toList(), template: _selectedTemplate!);
      ref.invalidate(localWorkersProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => (_error = e is FormatException ? e.message : 'Error al asignar turnos.', _saving = false));
    }
  }

  Future<void> _pickTemplate(List<ShiftTemplate> templates) async {
    final actions = [
      for (final t in templates)
        IosGlassAction<ShiftTemplate>(
          label: t.name,
          subtitle: t.timeFormatted,
          value: t,
          icon: CupertinoIcons.clock,
        ),
    ];
    final selected = await showIosGlassFloatingMenu<ShiftTemplate>(
      context: context,
      title: 'Seleccionar Turno Oficial',
      subtitle: 'Turno a asignar masivamente a los seleccionados',
      actions: actions,
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedTemplate = selected);
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(shiftTemplatesProvider).valueOrNull ?? const [];
    if (templates.isNotEmpty) _selectedTemplate ??= templates.first;
    final filtered = widget.workers.where((w) {
      if (_search.isEmpty) return true;
      final t = _search.toLowerCase();
      return w.name.toLowerCase().contains(t) || w.document.contains(t);
    }).toList();

    return IosFloatingModal(
      title: 'Asignar en Bloque',
      saveLabel: 'Aplicar (${_selectedIds.length})',
      isSaving: _saving,
      errorMessage: _error,
      onSave: _assign,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IosFormGroup(
          header: 'TURNO A ASIGNAR',
          children: [
            InkWell(
              onTap: () => _pickTemplate(templates),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(children: [
                  const Icon(CupertinoIcons.clock_fill, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedTemplate != null ? '${_selectedTemplate!.name} (${_selectedTemplate!.timeFormatted})' : 'Sin plantillas disponibles',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                    ),
                  ),
                  const Text('Cambiar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CupertinoSearchTextField(
          placeholder: 'Filtrar colaboradores…',
          style: TextStyle(fontSize: 13, color: context.cTextPrimary),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 10),
        IosFormGroup(
          header: 'COLABORADORES (${_selectedIds.length} SELECCIONADOS)',
          children: [
            for (final w in filtered)
              InkWell(
                onTap: () => setState(() => _selectedIds.contains(w.id) ? _selectedIds.remove(w.id) : _selectedIds.add(w.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(children: [
                    Icon(
                      _selectedIds.contains(w.id) ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                      size: 19,
                      color: _selectedIds.contains(w.id) ? AppColors.primary : context.cTextSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(w.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
                  ]),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}
