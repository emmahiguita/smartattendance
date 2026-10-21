// lib/features/photo_attendance/presentation/shift_template_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/shift_template.dart';
import 'local_providers.dart';

/// Diálogo interactivo para crear o modificar un turno laboral de forma real.
class ShiftTemplateDialog extends ConsumerStatefulWidget {
  const ShiftTemplateDialog({super.key, this.template});
  final ShiftTemplate? template;

  static Future<bool?> show(BuildContext context, {ShiftTemplate? template}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShiftTemplateDialog(template: template),
    );
  }

  @override
  ConsumerState<ShiftTemplateDialog> createState() => _ShiftTemplateDialogState();
}

class _ShiftTemplateDialogState extends ConsumerState<ShiftTemplateDialog> {
  final _nameController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _deductLunch = true;
  List<int> _selectedDays = [1, 2, 3, 4, 5];
  bool _saving = false;
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  int _calculateDailyMinutes() {
    final start = _toMinutes(_startTime);
    final end = _toMinutes(_endTime);
    int total = end >= start ? end - start : (1440 - start) + end;
    if (_deductLunch && total > 60) {
      total -= 60; // 1 hora de descanso/almuerzo
    }
    return total;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Ingresa un nombre para el turno.');
      return;
    }
    if (_selectedDays.isEmpty) {
      setState(() => _error = 'Selecciona al menos un día laborable.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final start = _toMinutes(_startTime);
      final end = _toMinutes(_endTime);
      final daily = _calculateDailyMinutes();

      final template = ShiftTemplate(
        id: widget.template?.id,
        name: name,
        startMinute: start,
        endMinute: end,
        dailyMinutes: daily,
        deductLunch: _deductLunch,
        nightStartMinute: 1140,
        nightEndMinute: 360,
        weekdays: _selectedDays,
      );

      final store = ref.read(localAdminStoreProvider);
      await store.saveShiftTemplate(template);
      ref.invalidate(shiftTemplatesProvider);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is FormatException ? e.message : 'Error al guardar el turno.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyMins = _calculateDailyMinutes();
    final dailyHours = dailyMins ~/ 60;
    final dailyRemainder = dailyMins % 60;

    return AlertDialog(
      title: Text(widget.template == null ? 'Nuevo Turno Laboral' : 'Editar Turno'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Turno *',
                  hintText: 'Ej: Turno Mañana, Turno Operativo...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _timeCard(
                      label: 'Entrada',
                      time: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeCard(
                      label: 'Salida',
                      time: _endTime,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jornada neta calculada: $dailyHours h ${dailyRemainder > 0 ? '$dailyRemainder m' : ''}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Descontar 1 hora de almuerzo / descanso', style: TextStyle(fontSize: 13)),
                value: _deductLunch,
                onChanged: (val) => setState(() => _deductLunch = val),
              ),
              const Divider(height: 20),
              const Text('Días aplicables:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final entry in {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'}.entries)
                    FilterChip(
                      label: Text(entry.value, style: const TextStyle(fontSize: 11)),
                      selected: _selectedDays.contains(entry.key),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(entry.key);
                            _selectedDays.sort();
                          } else {
                            _selectedDays.remove(entry.key);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar Turno'),
        ),
      ],
    );
  }

  Widget _timeCard({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.cBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: context.cTextSecondary)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$h:$m', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.cTextPrimary)),
                Icon(Icons.access_time_rounded, size: 16, color: context.cTextSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
