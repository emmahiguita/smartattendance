// ============================================================================
// ARCHIVO: hr_staff_tab.dart
// QUÉ HACE: Directorio de Personal en Gestión RRHH con barra de métricas
//           compacta estilo iOS, buscador `CupertinoSearchTextField`, botón
//           "+ Nuevo" y lista agrupada estilo Apple iOS Inset Grouped.
// CÓMO FUNCIONA: Filtra por estado o búsqueda y presenta a todos los
//                colaboradores dentro de un contenedor agrupado con divisores
//                finos (0.5px) como en Ajustes / Contactos de iOS.
// POR QUÉ: Elimina cajas pesadas redundantes y cumple SRP (< 155 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
    if (oldWidget.selectedFilter != widget.selectedFilter) _filter = widget.selectedFilter;
  }

  void _setFilter(String? f) {
    final next = (_filter == f || f == 'todos') ? null : f;
    setState(() => _filter = next);
    widget.onFilterChanged?.call(next);
  }

  void _openNewWorkerModal() {
    showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const WorkerDialog()).then((created) {
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

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AttendanceKpiGrid(selectedFilter: _filter ?? 'todos', onFilterTap: _setFilter),
      const SizedBox(height: 12),
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
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.person_add_solid, size: 14, color: Colors.white),
              SizedBox(width: 5),
              Text('Nuevo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      workersAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(28), child: Center(child: CupertinoActivityIndicator())),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workers) {
          final filtered = workers.where((w) {
            final status = calculateStaffStatus(w, today);
            if (!_matchesFilter(status, _filter)) return false;
            if (_search.isEmpty) return true;
            final term = _search.toLowerCase();
            return w.name.toLowerCase().contains(term) || w.document.contains(term) || w.job.toLowerCase().contains(term);
          }).toList();

          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 4, bottom: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('DIRECTORIO DE PERSONAL (${filtered.length})', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: context.cTextSecondary)),
                if (_filter != null)
                  GestureDetector(onTap: () => _setFilter(null), child: const Text('Ver todos', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary))),
              ]),
            ),
            Container(
              decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cBorder, width: 0.5)),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('Sin colaboradores en esta vista', style: TextStyle(fontSize: 12.5, color: context.cTextSecondary))),
                    )
                  : Column(children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        HrStaffWorkerCard(worker: filtered[i], status: calculateStaffStatus(filtered[i], today)),
                        if (i < filtered.length - 1) Divider(height: 1, thickness: 0.5, indent: 58, color: context.cBorder),
                      ],
                    ]),
            ),
          ]);
        },
      ),
    ]);
  }
}
