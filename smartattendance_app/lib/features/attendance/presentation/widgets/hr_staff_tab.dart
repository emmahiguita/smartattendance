// ============================================================================
// ARCHIVO: hr_staff_tab.dart
// QUÉ HACE: Directorio de Personal en Gestión RRHH con barra de métricas
//           compacta estilo iOS, buscador `CupertinoSearchTextField`, botón
//           "Nuevo" y lista abierta con divisores finos (0.5px).
// CÓMO FUNCIONA: Filtra por estado o búsqueda y presenta a todos los
//                colaboradores con espaciado compacto estilo iOS Ajustes.
// POR QUÉ: Elimina cajas pesadas redundantes y cumple SRP (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/worker_dialog.dart';
import 'attendance_kpi_grid.dart';
import 'hr_staff_worker_card.dart';
import 'staff_status_types.dart';

class HrStaffTab extends ConsumerStatefulWidget {
  const HrStaffTab({super.key, this.selectedFilter, this.onFilterChanged});
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;
  @override
  ConsumerState<HrStaffTab> createState() => _HrStaffTabState();
}

class _HrStaffTabState extends ConsumerState<HrStaffTab> {
  String _search = '';
  late String? _filter = widget.selectedFilter;

  @override
  void didUpdateWidget(covariant HrStaffTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      _filter = widget.selectedFilter;
    }
  }

  void _setFilter(String? f) {
    final next = (_filter == f || f == 'todos') ? null : f;
    setState(() => _filter = next);
    widget.onFilterChanged?.call(next);
  }

  void _openNewWorkerModal() {
    WorkerDialog.open(context).then((created) {
      if (created == true && mounted) ref.invalidate(localWorkersProvider);
    });
  }

  bool _matchesFilter(StaffAttendanceStatus status, String? filter) {
    if (filter == null || filter == 'todos') return true;
    return switch (filter.toLowerCase()) {
      'en_jornada' => status.category == StaffStatusCategory.enJornada,
      'sin_entrada' => status.category == StaffStatusCategory.sinEntrada,
      'jornada_cerrada' => status.category == StaffStatusCategory.jornadaCerrada,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(localWorkersProvider);
    final today = ColombiaClock.day(DateTime.now());
    final isDark = context.isDark;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AttendanceKpiGrid(
          selectedFilter: _filter ?? 'todos', onFilterTap: _setFilter),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: CupertinoSearchTextField(
            placeholder: 'Buscar por nombre, cargo o cédula…',
            style: TextStyle(fontSize: 13, color: context.cTextPrimary),
            onChanged: (val) => setState(() => _search = val),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openNewWorkerModal,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF1C1C1E) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.cBorder, width: 0.5),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.person_add, size: 15, color: Colors.white),
              SizedBox(width: 5),
              Text('Nuevo',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      workersAsync.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CupertinoActivityIndicator())),
        error: (e, _) => Center(child: Text('Error: $e')),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DIRECTORIO DE PERSONAL (${filtered.length})',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: context.cTextSecondary)),
                        if (_filter != null)
                          GestureDetector(
                            onTap: () => _setFilter(null),
                            child: Text('Ver todos',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.cTextPrimary)),
                          ),
                      ]),
                ),
                Divider(height: 1, thickness: 0.5, color: context.cBorder),
                if (filtered.isEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Sin colaboradores en esta vista',
                          style: TextStyle(
                              fontSize: 13, color: context.cTextSecondary)))
                else
                  for (var i = 0; i < filtered.length; i++) ...[
                    HrStaffWorkerCard(
                        worker: filtered[i],
                        status: calculateStaffStatus(filtered[i], today)),
                    Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: i < filtered.length - 1 ? 46 : 0,
                        color: context.cBorder),
                  ],
              ]);
        },
      ),
    ]);
  }
}
