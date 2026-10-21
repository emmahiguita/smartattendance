// lib/features/attendance/presentation/widgets/bulk_shift_assignment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

/// Diálogo para asignar una jornada/turno de forma masiva o rápida a varios colaboradores.
class BulkShiftAssignmentDialog extends ConsumerStatefulWidget {
  const BulkShiftAssignmentDialog({super.key, required this.workers});
  final List<LocalWorker> workers;

  static Future<bool?> show(BuildContext context, {required List<LocalWorker> workers}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BulkShiftAssignmentDialog(workers: workers),
    );
  }

  @override
  ConsumerState<BulkShiftAssignmentDialog> createState() => _BulkShiftAssignmentDialogState();
}

class _BulkShiftAssignmentDialogState extends ConsumerState<BulkShiftAssignmentDialog> {
  final Set<int> _selectedWorkerIds = {};
  ShiftTemplate? _selectedTemplate;
  bool _saving = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Por defecto seleccionar a los que no tienen jornada
    for (final w in widget.workers) {
      if (w.schedule == null) {
        _selectedWorkerIds.add(w.id);
      }
    }
    // Si todos ya tienen, seleccionar a todos
    if (_selectedWorkerIds.isEmpty) {
      _selectedWorkerIds.addAll(widget.workers.map((w) => w.id));
    }
  }

  Future<void> _assign() async {
    if (_selectedTemplate == null) {
      setState(() => _error = 'Selecciona el turno que deseas asignar.');
      return;
    }
    if (_selectedWorkerIds.isEmpty) {
      setState(() => _error = 'Selecciona al menos un colaborador.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final store = ref.read(localAdminStoreProvider);
      await store.assignShiftToWorkers(
        workerIds: _selectedWorkerIds.toList(),
        template: _selectedTemplate!,
      );
      ref.invalidate(localWorkersProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is FormatException ? e.message : 'Error al asignar la jornada.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(shiftTemplatesProvider);
    final filteredWorkers = widget.workers.where((w) {
      if (_search.isEmpty) return true;
      final term = _search.toLowerCase();
      return w.name.toLowerCase().contains(term) ||
          w.document.contains(term) ||
          w.job.toLowerCase().contains(term);
    }).toList();

    return AlertDialog(
      title: const Text('Asignación de Turnos'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
              const SizedBox(height: 10),
            ],
            // 1. Selector de turno
            const Text('1. Turno a asignar:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            templatesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error al cargar turnos'),
              data: (templates) {
                if (templates.isEmpty) {
                  return const Text('No hay turnos disponibles. Crea uno primero.');
                }
                _selectedTemplate ??= templates.first;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.cBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ShiftTemplate>(
                      isExpanded: true,
                      value: _selectedTemplate,
                      items: templates.map((t) {
                        final label = t.name.contains('(') ? t.name : '${t.name} (${t.timeFormatted})';
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTemplate = val),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            // 2. Selección de trabajadores
            Row(
              children: [
                Expanded(
                  child: Text(
                    '2. Colaboradores (${_selectedWorkerIds.length}):',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () {
                    setState(() {
                      if (_selectedWorkerIds.length == widget.workers.length) {
                        _selectedWorkerIds.clear();
                      } else {
                        _selectedWorkerIds.addAll(widget.workers.map((w) => w.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedWorkerIds.length == widget.workers.length ? 'Desmarcar todos' : 'Todos',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Filtrar personal...',
                prefixIcon: Icon(Icons.search, size: 16),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.cBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  itemCount: filteredWorkers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final w = filteredWorkers[index];
                    final isChecked = _selectedWorkerIds.contains(w.id);
                    final hasSchedule = w.schedule != null;
                    return CheckboxListTile(
                      dense: true,
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedWorkerIds.add(w.id);
                          } else {
                            _selectedWorkerIds.remove(w.id);
                          }
                        });
                      },
                      title: Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        hasSchedule ? 'Turno: ${w.schedule!.shiftName ?? w.schedule!.timeWindowFormatted}' : 'Sin jornada',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasSchedule ? AppColors.primary : Colors.amber.shade800,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _assign,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Asignar a ${_selectedWorkerIds.length} personas'),
        ),
      ],
    );
  }
}
