// lib/features/attendance/presentation/widgets/hr_schedules_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/shift_template_dialog.dart';
import 'bulk_shift_assignment_dialog.dart';

/// Pestaña 2 de RRHH: Gestión Real de Jornadas y Turnos.
/// Permite crear/editar plantillas de turnos y asignar jornadas reales a colaboradores.
class HrSchedulesTab extends ConsumerStatefulWidget {
  const HrSchedulesTab({super.key});

  @override
  ConsumerState<HrSchedulesTab> createState() => _HrSchedulesTabState();
}

class _HrSchedulesTabState extends ConsumerState<HrSchedulesTab> {
  String _searchWorker = '';
  String _workerFilter = 'all'; // all, with, without

  void _showNewShiftDialog({ShiftTemplate? template}) {
    ShiftTemplateDialog.show(context, template: template).then((saved) {
      if (saved == true && mounted) {
        ref.invalidate(shiftTemplatesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(template == null ? 'Turno creado exitosamente.' : 'Turno actualizado.'),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _deleteShiftTemplate(ShiftTemplate template) {
    if (template.id == null) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Turno'),
        content: Text('¿Deseas eliminar la plantilla "${template.name}"? Los colaboradores que ya la tengan asignada conservarán su horario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        await ref.read(localAdminStoreProvider).deleteShiftTemplate(template.id!);
        ref.invalidate(shiftTemplatesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turno eliminado.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _assignShiftToSingleWorker(LocalWorker worker, ShiftTemplate template) async {
    try {
      await ref.read(localAdminStoreProvider).assignShiftToWorkers(
        workerIds: [worker.id],
        template: template,
      );
      ref.invalidate(localWorkersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Turno "${template.name}" asignado a ${worker.name}.'),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e is FormatException ? e.message : e}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeWorkerSchedule(LocalWorker worker) async {
    try {
      await ref.read(localAdminStoreProvider).removeScheduleFromWorker(worker.id);
      ref.invalidate(localWorkersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jornada retirada de ${worker.name}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(localWorkersProvider);
    final templatesAsync = ref.watch(shiftTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tarjeta ejecutiva de resumen
        workersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (workers) {
            final withSchedule = workers.where((w) => w.schedule != null).length;
            final withoutSchedule = workers.length - withSchedule;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.cBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado General de Jornadas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.cTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$withSchedule asignados · $withoutSchedule sin jornada',
                              style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de progreso de cobertura
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: workers.isNotEmpty ? withSchedule / workers.length : 0,
                      backgroundColor: context.cBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final assigned = await BulkShiftAssignmentDialog.show(context, workers: workers);
                        if (assigned == true && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Turnos asignados exitosamente.'),
                              backgroundColor: AppColors.systemGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.group_add_rounded, size: 16),
                      label: const Text('Asignar turno a varios colaboradores', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // 2. Sección: Catálogo de Turnos Oficiales
        Row(
          children: [
            Expanded(
              child: Text(
                'Plantillas de Turnos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showNewShiftDialog(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nuevo Turno', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),

        templatesAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (e, _) => Text('Error al cargar turnos: $e'),
          data: (templates) {
            if (templates.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cBorder),
                ),
                child: const Text('No hay plantillas de turno. Crea una con el botón "+ Nuevo Turno".'),
              );
            }
            return SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return _buildShiftTemplateCard(t);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 22),

        // 3. Sección: Asignación Individual de Colaboradores
        Text(
          'Asignación por Colaborador',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.cTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),

        // Filtro y buscador
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.cBorder, width: 0.8),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchWorker = val),
                  style: TextStyle(color: context.cTextPrimary, fontSize: 12.5),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar colaborador...',
                    hintStyle: TextStyle(color: context.cTextSecondary, fontSize: 12),
                    prefixIcon: Icon(Icons.search, size: 16, color: context.cTextSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: context.cSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.cBorder, width: 0.8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _workerFilter,
                  style: TextStyle(color: context.cTextPrimary, fontSize: 12),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos')),
                    DropdownMenuItem(value: 'with', child: Text('Con turno')),
                    DropdownMenuItem(value: 'without', child: Text('Sin turno')),
                  ],
                  onChanged: (val) => setState(() => _workerFilter = val ?? 'all'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Lista de asignaciones
        workersAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Error: $e'),
          data: (workers) {
            final templates = templatesAsync.value ?? [];
            final filtered = workers.where((w) {
              if (_workerFilter == 'with' && w.schedule == null) return false;
              if (_workerFilter == 'without' && w.schedule != null) return false;
              if (_searchWorker.isEmpty) return true;
              final t = _searchWorker.toLowerCase();
              return w.name.toLowerCase().contains(t) || w.document.contains(t);
            }).toList();

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cBorder),
                ),
                child: Center(
                  child: Text('No hay colaboradores que coincidan.', style: TextStyle(color: context.cTextSecondary)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final w = filtered[index];
                return _buildWorkerScheduleTile(w, templates);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildShiftTemplateCard(ShiftTemplate t) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.more_vert_rounded, color: context.cTextSecondary),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showNewShiftDialog(template: t);
                  } else if (action == 'delete') {
                    _deleteShiftTemplate(t);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar turno', style: TextStyle(fontSize: 12.5))),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(fontSize: 12.5, color: Colors.red))),
                ],
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  t.timeFormatted,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Text(
            '${t.durationFormatted} neta · ${t.weekdaysSummary}',
            style: TextStyle(fontSize: 10.5, color: context.cTextSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerScheduleTile(LocalWorker w, List<ShiftTemplate> templates) {
    final hasSchedule = w.schedule != null;
    final scheduleLabel = hasSchedule
        ? (w.schedule!.shiftName ?? w.schedule!.timeWindowFormatted)
        : 'Sin jornada';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cBorder, width: 0.8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: hasSchedule
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.amber.withValues(alpha: 0.15),
            child: Icon(
              hasSchedule ? Icons.schedule_rounded : Icons.person_off_rounded,
              size: 18,
              color: hasSchedule ? AppColors.primary : Colors.amber.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  scheduleLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: hasSchedule ? AppColors.primary : Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Botón selector de turno
          PopupMenuButton<dynamic>(
            tooltip: 'Asignar turno',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasSchedule ? 'Cambiar' : 'Asignar',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
            onSelected: (value) {
              if (value is ShiftTemplate) {
                _assignShiftToSingleWorker(w, value);
              } else if (value == 'remove') {
                _removeWorkerSchedule(w);
              }
            },
            itemBuilder: (_) => [
              for (final t in templates)
                PopupMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t.name} (${t.timeFormatted})',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasSchedule) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.close_rounded, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Quitar jornada asignada', style: TextStyle(fontSize: 12.5, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
