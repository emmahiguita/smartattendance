import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import 'local_providers.dart';
import 'schedule_fields.dart';

/// Configura equipo, horario y constancia de privacidad de una persona.
class WorkerAssignmentDialog extends ConsumerStatefulWidget {
  const WorkerAssignmentDialog({super.key, required this.worker});
  final LocalWorker worker;
  @override
  ConsumerState<WorkerAssignmentDialog> createState() =>
      _WorkerAssignmentDialogState();
}

class _WorkerAssignmentDialogState
    extends ConsumerState<WorkerAssignmentDialog> {
  final _reference = TextEditingController();
  List<Map<String, Object?>> _teams = [];
  Map<String, dynamic>? _privacy;
  int? _team;
  WorkSchedule? _schedule;
  bool _loading = true, _busy = false, _confirmed = false;
  bool _withoutSchedule = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = ref.read(localAdminStoreProvider);
      final teams = await store.rows('crews');
      final worker = await store.workerConfig(widget.worker.id);
      final privacy = await store.setting('privacy');
      if (!mounted) return;
      _schedule = WorkSchedule.decode(worker['schedule_json'] as String?);
      _withoutSchedule = _schedule == null;
      _team = worker['crew_id'] as int?;
      _reference.text = worker['authorization_reference'] as String? ?? '';
      _teams = teams;
      _privacy =
          privacy == null ? null : jsonDecode(privacy) as Map<String, dynamic>;
    } catch (_) {
      if (mounted) _error = 'No se pudo cargar la asignación.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if ((!_withoutSchedule && _schedule == null) ||
        !_confirmed ||
        _privacy == null) {
      setState(() => _error =
          'Completa el horario elegido y revisa la autorización de datos.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(localAdminStoreProvider).assignWorker(widget.worker.id,
          _team, _withoutSchedule ? null : _schedule, _reference.text);
      ref.invalidate(localWorkersProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'No se pudo guardar la asignación.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: AlertDialog(
          title: Text(widget.worker.name),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading) const LinearProgressIndicator(),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_loading),
                    initialValue: _team,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Equipo de trabajo (opcional)'),
                    items: [
                      const DropdownMenuItem<int>(
                          value: null, child: Text('Sin equipo')),
                      for (final team in _teams)
                        DropdownMenuItem(
                            value: team['id'] as int,
                            child: Text(team['name'] as String)),
                    ],
                    onChanged:
                        _busy ? null : (value) => setState(() => _team = value),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _withoutSchedule,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                              _withoutSchedule = value;
                              if (value) _schedule = null;
                            }),
                    title: const Text('Personal sin horario fijo'),
                    subtitle: const Text(
                        'Las horas extra requieren un horario asignado.'),
                  ),
                  if (!_loading && !_withoutSchedule)
                    ScheduleFields(
                      key: ValueKey(widget.worker.id),
                      initial: _schedule,
                      enabled: !_busy,
                      onChanged: (value) => _schedule = value,
                    ),
                  const SizedBox(height: 16),
                  if (_privacy == null)
                    const Text('Configura el tratamiento de datos en Ajustes.')
                  else
                    Text(
                        'Responsable: ${_privacy!['company']}\nContacto: ${_privacy!['email']} · ${_privacy!['phone']}\nFinalidad: ${_privacy!['purpose']}\nConservación: ${_privacy!['retention']}'),
                  TextField(
                    controller: _reference,
                    maxLength: 300,
                    decoration: const InputDecoration(
                        labelText: 'Referencia del soporte de autorización'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _confirmed,
                    onChanged: _busy
                        ? null
                        : (value) =>
                            setState(() => _confirmed = value ?? false),
                    title: const Text(
                        'Revisé la autorización para fotos y, si se usa, ubicación.'),
                  ),
                  const Text(
                      'No marques esta opción por cuenta del trabajador. Conserva el soporte y atiende sus derechos.'),
                  if (_error != null)
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: _busy || _loading ? null : _save,
              child: Text(_busy ? 'Guardando…' : 'Guardar asignación'),
            ),
          ],
        ),
      );
}
