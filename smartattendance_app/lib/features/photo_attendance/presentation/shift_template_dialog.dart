// ============================================================================
// ARCHIVO: shift_template_dialog.dart
// QUÉ HACE: Modal flotante iOS para configurar turnos laborales y habilitar o
//           restringir el tiempo permitido para marcar asistencia.
// CÓMO FUNCIONA: Permite al Administrador definir horas de entrada/salida,
//                días laborables y activar/desactivar la ventana horaria de
//                marcación (`enableMarkWindow` con inicio y fin).
// POR QUÉ: Otorga al Administrador control total sobre horarios y tolerancias,
//          garantizando validaciones reales en SQLite (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/shift_template.dart';
import 'local_providers.dart';

class ShiftTemplateDialog extends ConsumerStatefulWidget {
  const ShiftTemplateDialog({super.key, this.template});
  final ShiftTemplate? template;

  static Future<bool?> show(BuildContext context, {ShiftTemplate? template}) =>
      showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => ShiftTemplateDialog(template: template));

  @override
  ConsumerState<ShiftTemplateDialog> createState() => _ShiftTemplateDialogState();
}

class _ShiftTemplateDialogState extends ConsumerState<ShiftTemplateDialog> {
  final _nameController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0), _endTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _markStart = const TimeOfDay(hour: 7, minute: 30), _markEnd = const TimeOfDay(hour: 18, minute: 0);
  bool _deductLunch = true, _enableMarkWindow = false, _saving = false;
  List<int> _selectedDays = [1, 2, 3, 4, 5];
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _nameController.text = t.name;
      _startTime = TimeOfDay(hour: t.startMinute ~/ 60, minute: t.startMinute % 60);
      _endTime = TimeOfDay(hour: t.endMinute ~/ 60, minute: t.endMinute % 60);
      _deductLunch = t.deductLunch;
      _selectedDays = List.from(t.weekdays);
      _enableMarkWindow = t.enableMarkWindow;
      if (t.markStartMinute != null) _markStart = TimeOfDay(hour: t.markStartMinute! ~/ 60, minute: t.markStartMinute! % 60);
      if (t.markEndMinute != null) _markEnd = TimeOfDay(hour: t.markEndMinute! ~/ 60, minute: t.markEndMinute! % 60);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  int _calculateDailyMinutes() {
    final start = _toMin(_startTime), end = _toMin(_endTime);
    int total = end >= start ? end - start : (1440 - start) + end;
    if (_deductLunch && total > 60) total -= 60;
    return total;
  }

  Future<void> _pick(bool isStart, bool isMark) async {
    final cur = isMark ? (isStart ? _markStart : _markEnd) : (isStart ? _startTime : _endTime);
    final picked = await showTimePicker(context: context, initialTime: cur);
    if (picked != null && mounted) {
      setState(() {
        if (isMark) {
          isStart ? _markStart = picked : _markEnd = picked;
        } else {
          isStart ? _startTime = picked : _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDays.isEmpty) {
      setState(() => _error = 'Ingresa el nombre y selecciona al menos un día.');
      return;
    }
    setState(() => (_saving = true, _error = null));
    try {
      final template = ShiftTemplate(
        id: widget.template?.id,
        name: name,
        startMinute: _toMin(_startTime),
        endMinute: _toMin(_endTime),
        dailyMinutes: _calculateDailyMinutes(),
        deductLunch: _deductLunch,
        weekdays: _selectedDays,
        enableMarkWindow: _enableMarkWindow,
        markStartMinute: _enableMarkWindow ? _toMin(_markStart) : null,
        markEndMinute: _enableMarkWindow ? _toMin(_markEnd) : null,
      );
      await ref.read(localAdminStoreProvider).saveShiftTemplate(template);
      ref.invalidate(shiftTemplatesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => (_error = e is FormatException ? e.message : 'Error al guardar turno.', _saving = false));
    }
  }

  Widget _timeRow(String label, TimeOfDay time, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: context.cBackground, borderRadius: BorderRadius.circular(7), border: Border.all(color: context.cBorder, width: 0.8)),
              child: Text(time.format(context), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dailyMins = _calculateDailyMinutes();
    return IosFloatingModal(
      title: widget.template == null ? 'Nuevo Turno' : 'Editar Turno',
      isSaving: _saving,
      errorMessage: _error,
      onSave: _save,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IosFormGroup(header: 'Horario Laboral', children: [
          IosFormFieldRow(label: 'Nombre', placeholder: 'Ej. Turno Mañana', controller: _nameController, textCapitalization: TextCapitalization.words),
          _timeRow('Hora de entrada', _startTime, () => _pick(true, false)),
          _timeRow('Hora de salida', _endTime, () => _pick(false, false)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Descontar 1h de almuerzo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
              CupertinoSwitch(value: _deductLunch, activeTrackColor: AppColors.primary, onChanged: (v) => setState(() => _deductLunch = v)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        IosFormGroup(header: 'Ventana de Marcación Permitida', children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Habilitar límite para marcar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
                  Text(_enableMarkWindow ? 'Se valida rango horario estricto' : 'Marcación flexible en cualquier hora', style: TextStyle(fontSize: 11, color: context.cTextSecondary)),
                ]),
              ),
              CupertinoSwitch(value: _enableMarkWindow, activeTrackColor: AppColors.primary, onChanged: (v) => setState(() => _enableMarkWindow = v)),
            ]),
          ),
          if (_enableMarkWindow) ...[
            _timeRow('Permitir marcar desde', _markStart, () => _pick(true, true)),
            _timeRow('Límite de marcación hasta', _markEnd, () => _pick(false, true)),
          ],
        ]),
        const SizedBox(height: 12),
        IosFormGroup(header: 'Días Laborables · Neta ${dailyMins ~/ 60}h ${dailyMins % 60}m', children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'}.entries.map((e) {
                final sel = _selectedDays.contains(e.key);
                return GestureDetector(
                  onTap: () => setState(() => sel ? _selectedDays.remove(e.key) : (_selectedDays..add(e.key)).sort()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: sel ? AppColors.primary : context.cBackground, shape: BoxShape.circle, border: Border.all(color: sel ? AppColors.primary : context.cBorder, width: 0.8)),
                    child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : context.cTextPrimary)),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ]),
    );
  }
}
