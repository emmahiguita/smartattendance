// ============================================================================
// ARCHIVO: attendance_kpi_grid.dart
// QUÉ HACE: Barra ejecutiva compacta estilo Apple iOS de 4 métricas interactivas
//           de asistencia (Total, En turno, Sin marca, Cerradas) en una fila.
// CÓMO FUNCIONA: Observa `localWorkersProvider` y permite tocar cualquier celda
//                para filtrar la lista de colaboradores sin tarjetas pesadas.
// POR QUÉ: Sustituye cajas por una franja limpia con divisores finos (< 130 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ('todos', 'Total', workers.length),
      ('en_jornada', 'En turno', enJornada),
      ('sin_entrada', 'Sin marca', sinEntrada),
      ('jornada_cerrada', 'Cerradas', finalizadas),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: _buildCell(
                  context,
                  keyId: items[i].$1,
                  label: items[i].$2,
                  count: items[i].$3,
                  selected: (selectedFilter ?? 'todos') == items[i].$1,
                ),
              ),
              if (i < items.length - 1)
                Container(
                  width: 0.5,
                  height: 30,
                  color: context.cBorder,
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Divider(height: 1, thickness: 0.5, color: context.cBorder),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required String keyId,
    required String label,
    required int count,
    required bool selected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onFilterTap?.call(keyId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? (context.isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: context.cTextPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? context.cTextPrimary : context.cTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
