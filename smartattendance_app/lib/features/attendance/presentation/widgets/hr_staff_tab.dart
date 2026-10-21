// lib/features/attendance/presentation/widgets/hr_staff_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import 'staff_status_types.dart';
import 'worker_hr_management_sheet.dart';

/// Pestaña 1 de RRHH: Directorio de Personal unificado, sin duplicados ni pantallas zombies.
class HrStaffTab extends ConsumerStatefulWidget {
  const HrStaffTab({super.key, this.selectedFilter, this.onFilterChanged});
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;

  @override
  ConsumerState<HrStaffTab> createState() => _HrStaffTabState();
}

class _HrStaffTabState extends ConsumerState<HrStaffTab> {
  String _search = '';
  late String? _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.selectedFilter;
  }

  @override
  void didUpdateWidget(covariant HrStaffTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      _filter = widget.selectedFilter;
    }
  }

  void _setFilter(String? f) {
    setState(() => _filter = f);
    widget.onFilterChanged?.call(f);
  }

  bool _matchesFilter(StaffAttendanceStatus status, String? filter) {
    if (filter == null) return true;
    switch (filter.toLowerCase()) {
      case 'presentes':
      case 'presente':
        return status.category == StaffStatusCategory.enJornada;
      case 'ausentes':
      case 'ausente':
      case 'sin entrada':
        return status.category == StaffStatusCategory.sinEntrada;
      case 'almuerzo':
      case 'en almuerzo':
        return status.label.toLowerCase().contains('almuerzo');
      case 'finalizado':
      case 'cerrada':
        return status.category == StaffStatusCategory.jornadaCerrada;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(localWorkersProvider);
    final today = ColombiaClock.day(DateTime.now());

    return workersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(
        child: Text('Error al cargar colaboradores: $e'),
      ),
      data: (workers) {
        final filtered = workers.where((w) {
          final status = calculateStaffStatus(w, today);
          if (!_matchesFilter(status, _filter)) return false;
          if (_search.isEmpty) return true;
          final term = _search.toLowerCase();
          return w.name.toLowerCase().contains(term) ||
              w.document.contains(term) ||
              w.job.toLowerCase().contains(term);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buscador
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: context.cSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.cBorder, width: 0.8),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _search = val),
                style: TextStyle(color: context.cTextPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar por nombre, cargo o cédula...',
                  hintStyle: TextStyle(color: context.cTextSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.cTextSecondary),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Chips de filtrado rápido por estado de marcación de hoy
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusFilterChip('Todos (${workers.length})', null),
                  const SizedBox(width: 6),
                  _statusFilterChip('Presentes', 'presente'),
                  const SizedBox(width: 6),
                  _statusFilterChip('Ausentes', 'sin entrada'),
                  const SizedBox(width: 6),
                  _statusFilterChip('En almuerzo', 'almuerzo'),
                  const SizedBox(width: 6),
                  _statusFilterChip('Jornada cerrada', 'cerrada'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Contador de resultados
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filtered.length} colaboradores',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Ficha integral',
                  style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 40, color: context.cTextSecondary),
                    const SizedBox(height: 10),
                    Text(
                      _search.isNotEmpty ? 'No se encontraron resultados para "$_search"' : 'No hay personal en este estado',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prueba cambiando el filtro o la búsqueda.',
                      style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final worker = filtered[index];
                  final status = calculateStaffStatus(worker, today);
                  return _buildWorkerCard(context, worker, status);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _statusFilterChip(String label, String? apiValue) {
    final isSelected = _filter == apiValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => _setFilter(isSelected && apiValue != null ? null : apiValue),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: context.cSurface,
      side: BorderSide(color: isSelected ? AppColors.primary : context.cBorder, width: isSelected ? 1.2 : 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildWorkerCard(BuildContext context, LocalWorker worker, StaffAttendanceStatus status) {
    final hasSchedule = worker.schedule != null;
    final scheduleText = hasSchedule
        ? (worker.schedule!.shiftName ?? worker.schedule!.timeWindowFormatted)
        : 'Sin jornada';

    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cBorder, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => WorkerHrManagementSheet.show(context, worker: worker),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar con iniciales
                CircleAvatar(
                  radius: 22,
                  backgroundColor: status.color.withValues(alpha: 0.15),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Datos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.cTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Estado de hoy
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: status.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${worker.job} · C.C. ${worker.document}',
                        style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badge de Turno / Jornada
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasSchedule
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: hasSchedule
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : Colors.amber.withValues(alpha: 0.3),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasSchedule ? Icons.schedule_rounded : Icons.warning_amber_rounded,
                                    size: 11,
                                    color: hasSchedule ? AppColors.primary : Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      scheduleText,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: hasSchedule ? AppColors.primary : Colors.amber.shade800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Icono para ver QR/Credencial directo
                          IconButton(
                            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                            color: context.cTextSecondary,
                            tooltip: 'Ver credencial QR',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              EmployeeDetailDialog.show(
                                context,
                                worker: worker,
                                attendanceStatusLabel: status.label,
                                attendanceStatusColor: status.color,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
