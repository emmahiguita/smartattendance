import 'package:flutter/material.dart';
import '../domain/work_schedule.dart';

/// Editor reutilizable del horario pactado, sin depender de SQLite. Solo emite
/// un horario válido; nunca sustituye una duración inválida por ocho horas.
class ScheduleFields extends StatefulWidget {
  const ScheduleFields(
      {super.key,
      this.initial,
      required this.onChanged,
      required this.enabled});
  final WorkSchedule? initial;
  final ValueChanged<WorkSchedule?> onChanged;
  final bool enabled;
  @override
  State<ScheduleFields> createState() => _ScheduleFieldsState();
}

class _ScheduleFieldsState extends State<ScheduleFields> {
  final _hours = TextEditingController();
  bool? _deduct;
  late int _start, _end;
  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      _hours.text =
          '${s.dailyMinutes ~/ 60}:${(s.dailyMinutes % 60).toString().padLeft(2, '0')}';
    }
    _deduct = s?.deductLunch;
    _start = s?.nightStartMinute ?? 1140;
    _end = s?.nightEndMinute ?? 360;
  }

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  void _emit() {
    final m = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(_hours.text.trim());
    final minutes = m == null ? null : int.parse(m[1]!) * 60 + int.parse(m[2]!);
    widget.onChanged(minutes == null ||
            minutes <= 0 ||
            minutes > 1440 ||
            _deduct == null ||
            _start == _end
        ? null
        : WorkSchedule(minutes, _deduct!,
            nightStartMinute: _start, nightEndMinute: _end));
  }

  Future<void> _pick(bool start) async {
    final minute = start ? _start : _end;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
    if (time != null && mounted) {
      setState(() {
        if (start) {
          _start = time.hour * 60 + time.minute;
        } else {
          _end = time.hour * 60 + time.minute;
        }
      });
      _emit();
    }
  }

  String _time(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: _hours,
            enabled: widget.enabled,
            keyboardType: TextInputType.datetime,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
                labelText: 'Jornada ordinaria diaria (HH:mm)',
                helperText: 'Duración pactada; adicional sujeto a revisión.')),
        const SizedBox(height: 12),
        DropdownButtonFormField<bool>(
            initialValue: _deduct,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Almuerzo registrado'),
            items: const [
              DropdownMenuItem(
                  value: true, child: Text('Descontar del tiempo trabajado')),
              DropdownMenuItem(
                  value: false, child: Text('Incluir como tiempo remunerado'))
            ],
            onChanged: widget.enabled
                ? (v) {
                    setState(() => _deduct = v);
                    _emit();
                  }
                : null),
        const SizedBox(height: 8),
        const Text(
            'Franja nocturna: confirma la aplicable al régimen y período laboral.'),
        Wrap(spacing: 8, children: [
          TextButton(
              onPressed: widget.enabled ? () => _pick(true) : null,
              child: Text('Inicio ${_time(_start)}')),
          TextButton(
              onPressed: widget.enabled ? () => _pick(false) : null,
              child: Text('Fin ${_time(_end)}')),
        ]),
      ]);
}
