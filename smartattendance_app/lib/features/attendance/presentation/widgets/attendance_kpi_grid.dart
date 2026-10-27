// ============================================================================
// ARCHIVO: attendance_kpi_grid.dart
// QUÉ HACE: Barra ejecutiva compacta estilo Apple iOS de 4 métricas interactivas
//           de asistencia (Total, En turno, Pendientes, Cerradas) en una sola
//           fila limpia que ahorra más de 110px verticales.
// CÓMO FUNCIONA: Observa `localWorkersProvider` y permite tocar cualquier celda
//                para filtrar instantáneamente la lista de colaboradores.
// POR QUÉ: Sustituye las 4 cajas gigantes por un bloque iOS Inset Grouped
//          compacto y cumple SRP (< 130 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

class AttendanceKpiGrid extends ConsumerWidget {
  const AttendanceKpiGrid({super.key, this.selectedFilter, this.onFilterTap});

  final String? selectedFilter;
  final ValueChanged<String>? onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workers = ref.watch(localWorkersProvider).valueOrNull ?? const [];
    return _buildStrip(context, workers);
  }

  Widget _buildStrip(BuildContext context, List<LocalWorker> workers) {
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

    final items = [
      ('todos', 'Total', workers.length, AppColors.primary),
      ('en_jornada', 'En turno', enJornada, AppColors.systemGreen),
      ('sin_entrada', 'Sin marca', sinEntrada, AppColors.systemOrange),
      ('jornada_cerrada', 'Cerradas', finalizadas, AppColors.primary),
    ];

    return IosGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 14,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: _buildCell(
                context,
                keyId: items[i].$1,
                label: items[i].$2,
                count: items[i].$3,
                dotColor: items[i].$4,
                selected: (selectedFilter ?? 'todos') == items[i].$1,
              ),
            ),
            if (i < items.length - 1)
              Container(width: 0.8, height: 38, color: context.cBorder.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required String keyId,
    required String label,
    required int count,
    required Color dotColor,
    required bool selected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onFilterTap?.call(keyId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : context.cTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : context.cTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
