import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import 'staff_status_controls.dart';
import 'staff_status_types.dart';
import 'staff_worker_tile.dart';

/// Lee el personal local y presenta su estado real de jornada en la portada.
/// La lógica de búsqueda, categorías y componentes visuales se mantiene separada.
class DashboardStaffStatus extends ConsumerStatefulWidget {
  const DashboardStaffStatus({
    super.key,
    required this.onOpenAll,
    this.initialFilter,
  });

  final VoidCallback onOpenAll;
  final String? initialFilter;

  @override
  ConsumerState<DashboardStaffStatus> createState() =>
      _DashboardStaffStatusState();
}

class _DashboardStaffStatusState extends ConsumerState<DashboardStaffStatus> {
  final _searchController = TextEditingController();
  String _search = '', _filter = 'todos';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? _filter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardStaffStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null &&
        widget.initialFilter != oldWidget.initialFilter) {
      setState(() => _filter = widget.initialFilter!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(localWorkersProvider);
    return IosGlassCard(
      child: workers.when(
        loading: () => const SizedBox(
          height: 70,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const Text('No se pudo cargar el personal local.'),
        data: (rows) => _buildRows(context, rows),
      ),
    );
  }

  Widget _buildRows(BuildContext context, List<LocalWorker> rows) {
    final today = ColombiaClock.day(DateTime.now());
    final query = _search.trim().toLowerCase();

    // Se calcula una vez por persona para búsquedas y filas, evitando trabajo duplicado.
    final statuses = rows
        .map((worker) => MapEntry(worker, calculateStaffStatus(worker, today)))
        .toList(growable: false);
    final active = statuses.where((row) => row.value.active).length;
    final visible = statuses
        .where((row) {
          final worker = row.key;
          final matchesSearch = query.isEmpty ||
              worker.name.toLowerCase().contains(query) ||
              worker.document.toLowerCase().contains(query) ||
              worker.job.toLowerCase().contains(query);
          return matchesSearch && _matchesFilter(row.value);
        })
        .take(6)
        .toList(growable: false);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StaffStatusControls(
        controller: _searchController,
        search: _search,
        filter: _filter,
        activeCount: active,
        totalCount: rows.length,
        onSearchChanged: (value) => setState(() => _search = value),
        onClearSearch: () => setState(() {
          _searchController.clear();
          _search = '';
        }),
        onFilterChanged: (value) => setState(() => _filter = value),
      ),
      const SizedBox(height: 8),
      if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(child: Text('No hay trabajadores en este estado.')),
        )
      else
        ...visible.asMap().entries.map((entry) {
          final worker = entry.value.key;
          final status = entry.value.value;
          return StaffWorkerTile(
            worker: worker,
            status: status,
            showDivider: entry.key < visible.length - 1,
            onTap: () => EmployeeDetailDialog.show(
              context,
              worker: worker,
              attendanceStatusLabel: status.label,
              attendanceStatusColor: status.color,
              lastMarkTime: worker.lastMarkAt == null
                  ? null
                  : ColombiaClock.hour(worker.lastMarkAt!),
            ),
          );
        }),
      if (rows.length > visible.length && rows.length > 5)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.onOpenAll,
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('Ver lista completa'),
          ),
        ),
    ]);
  }

  /// Conserva una sola regla de filtro para todas las filas.
  bool _matchesFilter(StaffAttendanceStatus status) => switch (_filter) {
        'en_jornada' => status.category == StaffStatusCategory.enJornada,
        'sin_entrada' => status.category == StaffStatusCategory.sinEntrada,
        'jornada_cerrada' =>
          status.category == StaffStatusCategory.jornadaCerrada,
        'incompletos' => status.category == StaffStatusCategory.incompleta,
        _ => true,
      };
}
