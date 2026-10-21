// lib/features/attendance/presentation/widgets/attendance_kpi_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_design_tokens.dart';
import '../../../../core/design_system/attendance_kpi_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

/// ============================================================================
/// COMPONENTE: AttendanceKpiGrid (Estilo iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Muestra las 4 tarjetas de métricas operacionales del día:
/// Activos, En jornada, Sin entrada y Jornadas cerradas.
///
/// CÓMO FUNCIONA:
/// Observa [localWorkersProvider] de SQLite y calcula reactivamente los estados.
/// Permite tocar cualquier KPI para filtrar el listado inferior.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP) y Clean Architecture: código menor
/// a 200 líneas sin simulaciones ni latencias.
/// ============================================================================
class AttendanceKpiGrid extends ConsumerWidget {
  const AttendanceKpiGrid({super.key, this.selectedFilter, this.onFilterTap});

  final String? selectedFilter;
  final ValueChanged<String>? onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(localWorkersProvider);

    return workersAsync.when(
      loading: () => _buildLayout(
        const AttendanceKpiCard(title: 'Empleados', subtitle: 'En plantilla', icon: Icons.people_outline_rounded, isLoading: true),
        const AttendanceKpiCard(title: 'En jornada', subtitle: 'Laborando hoy', icon: Icons.timer_outlined, isLoading: true),
        const AttendanceKpiCard(title: 'Sin entrada', subtitle: 'Pendientes', icon: Icons.access_time_rounded, isLoading: true),
        const AttendanceKpiCard(title: 'Finalizadas', subtitle: 'Cerradas', icon: Icons.check_circle_outline_rounded, isLoading: true),
      ),
      error: (_, __) => _buildLayout(
        const AttendanceKpiCard(title: 'Empleados', subtitle: 'Sin datos', icon: Icons.people_outline_rounded, errorMessage: 'Error'),
        const AttendanceKpiCard(title: 'En jornada', subtitle: 'Sin datos', icon: Icons.timer_outlined, errorMessage: 'Error'),
        const AttendanceKpiCard(title: 'Sin entrada', subtitle: 'Sin datos', icon: Icons.access_time_rounded, errorMessage: 'Error'),
        const AttendanceKpiCard(title: 'Finalizadas', subtitle: 'Sin datos', icon: Icons.check_circle_outline_rounded, errorMessage: 'Error'),
      ),
      data: (workers) => _buildDataGrid(workers),
    );
  }

  Widget _buildDataGrid(List<LocalWorker> workers) {
    final today = ColombiaClock.day(DateTime.now());
    var enJornada = 0, sinEntrada = 0, finalizadas = 0;

    for (final w in workers) {
      if (w.lastWorkDate != today) {
        sinEntrada++;
      } else {
        switch (w.lastMark) {
          case 'entrada':
          case 'regreso_almuerzo':
          case 'salida_almuerzo':
            enJornada++;
          case 'salida':
            finalizadas++;
          default:
            sinEntrada++;
        }
      }
    }

    return _buildLayout(
      AttendanceKpiCard(
        title: 'Empleados activos',
        value: workers.length,
        subtitle: 'Total plantilla',
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.primary,
        isSelected: selectedFilter == 'todos',
        onTap: () => onFilterTap?.call('todos'),
      ),
      AttendanceKpiCard(
        title: 'En jornada',
        value: enJornada,
        subtitle: 'Laborando ahora',
        icon: Icons.timer_rounded,
        iconColor: AppColors.systemGreen,
        isSelected: selectedFilter == 'en_jornada',
        onTap: () => onFilterTap?.call('en_jornada'),
      ),
      AttendanceKpiCard(
        title: 'Sin entrada',
        value: sinEntrada,
        subtitle: 'Pendientes hoy',
        icon: Icons.access_time_rounded,
        iconColor: AppColors.systemOrange,
        isSelected: selectedFilter == 'sin_entrada',
        onTap: () => onFilterTap?.call('sin_entrada'),
      ),
      AttendanceKpiCard(
        title: 'Jornadas cerradas',
        value: finalizadas,
        subtitle: 'Salida registrada',
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.accentIndigo,
        isSelected: selectedFilter == 'jornada_cerrada',
        onTap: () => onFilterTap?.call('jornada_cerrada'),
      ),
    );
  }

  Widget _buildLayout(Widget c1, Widget c2, Widget c3, Widget c4) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: c1),
            const SizedBox(width: AppDesignTokens.cardSpacing),
            Expanded(child: c2),
            const SizedBox(width: AppDesignTokens.cardSpacing),
            Expanded(child: c3),
            const SizedBox(width: AppDesignTokens.cardSpacing),
            Expanded(child: c4),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: c1),
              const SizedBox(width: AppDesignTokens.cardSpacing),
              Expanded(child: c2),
            ],
          ),
          const SizedBox(height: AppDesignTokens.cardSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: c3),
              const SizedBox(width: AppDesignTokens.cardSpacing),
              Expanded(child: c4),
            ],
          ),
        ],
      );
    });
  }
}
