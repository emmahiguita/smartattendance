// lib/features/attendance/presentation/widgets/dashboard_staff_status.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import 'staff_status_types.dart';
import 'staff_worker_tile.dart';

/// ============================================================================
/// COMPONENTE: DashboardStaffStatus (Estilo iOS Glass Inset Grouped)
/// ============================================================================
/// QUÉ HACE:
/// Muestra el estado operativo del personal registrado en la base de datos local:
/// contador de activos, buscador en tiempo real, filtros y lista tabular estilo iOS.
///
/// CÓMO FUNCIONA:
/// Observa [localWorkersProvider] de Riverpod, filtra en memoria con cero latencia
/// y delega cada fila a [StaffWorkerTile].
///
/// POR QUÉ:
/// Cumple con las directrices Apple HIG y el principio SRP en menos de 200 líneas.
/// ============================================================================
class DashboardStaffStatus extends ConsumerStatefulWidget {
  const DashboardStaffStatus({super.key, required this.onOpenAll, this.initialFilter});
  final VoidCallback onOpenAll;
  final String? initialFilter;

  @override
  ConsumerState<DashboardStaffStatus> createState() => _DashboardStaffStatusState();
}

class _DashboardStaffStatusState extends ConsumerState<DashboardStaffStatus> {
  final _searchController = TextEditingController();
  String _search = '', _filter = 'todos';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) _filter = widget.initialFilter!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardStaffStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null && widget.initialFilter != oldWidget.initialFilter) {
      setState(() => _filter = widget.initialFilter!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(localWorkersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IosGlassCard(
      child: workersAsync.when(
        loading: () => const SizedBox(height: 70, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => Text('No se pudo cargar el personal.', style: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70), fontSize: 13)),
        data: (workers) => _buildContent(context, workers, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<LocalWorker> rows, bool isDark) {
    final today = ColombiaClock.day(DateTime.now());
    final q = _search.trim().toLowerCase();

    final searched = rows.where((w) {
      if (q.isEmpty) return true;
      return w.name.toLowerCase().contains(q) || w.document.toLowerCase().contains(q) || w.job.toLowerCase().contains(q);
    }).toList();

    final filtered = searched.where((w) {
      final s = calculateStaffStatus(w, today);
      return switch (_filter) {
        'en_jornada' => s.category == StaffStatusCategory.enJornada,
        'sin_entrada' => s.category == StaffStatusCategory.sinEntrada,
        'jornada_cerrada' => s.category == StaffStatusCategory.jornadaCerrada,
        'incompletos' => s.category == StaffStatusCategory.incompleta,
        _ => true,
      };
    }).toList();

    final activeCount = rows.where((w) => calculateStaffStatus(w, today).category == StaffStatusCategory.enJornada).length;
    final visible = filtered.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Estado del personal', style: TextStyle(color: context.cTextPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(12)),
              child: Text('$activeCount/${rows.length} activos', style: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70), fontSize: 11, fontWeight: FontWeight.w600, fontFeatures: AppDesignTokens.tabularFigures)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 38,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _search = val),
            style: TextStyle(color: context.cTextPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              hintText: 'Buscar colaborador o cédula…',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70), fontSize: 12.5),
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _search = '';
                      }),
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('Todos', 'todos', isDark),
              _chip('En jornada', 'en_jornada', isDark),
              _chip('Sin entrada', 'sin_entrada', isDark),
              _chip('Jornada cerrada', 'jornada_cerrada', isDark),
              _chip('Incompletos', 'incompletos', isDark),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(child: Text('No hay colaboradores en esta categoría', style: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70), fontSize: 12.5))),
          )
        else
          ...visible.asMap().entries.map((entry) => StaffWorkerTile(
                worker: entry.value,
                status: calculateStaffStatus(entry.value, today),
                showDivider: entry.key < visible.length - 1,
                onTap: () {
                  final s = calculateStaffStatus(entry.value, today);
                  EmployeeDetailDialog.show(
                    context,
                    worker: entry.value,
                    attendanceStatusLabel: s.label,
                    attendanceStatusColor: s.color,
                    lastMarkTime: entry.value.lastMarkAt != null
                        ? ColombiaClock.hour(entry.value.lastMarkAt!)
                        : null,
                  );
                },
              )),
        if (filtered.length > visible.length || rows.length > 5) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onOpenAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text('Ver lista completa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(String label, String key, bool isDark) {
    final sel = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
              fontSize: 11,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
