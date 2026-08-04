// lib/features/attendance/presentation/widgets/premium_area_sections.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../data/models/attendance_model.dart';

/// Registros de asistencia ORGANIZADOS POR ÁREA (cargo del empleado).
///
/// Cada área es una sección con encabezado (icono + nombre + contador) y sus
/// filas compactas (empleado, tipo, fecha, hora). Incluye chips de filtro
/// para ver un área específica o todas.
class AreaGroupedAttendanceList extends StatelessWidget {
  final List<AttendanceModel> attendances;
  final String? selectedArea;
  final void Function(String?) onAreaSelected;

  const AreaGroupedAttendanceList({
    super.key,
    required this.attendances,
    required this.selectedArea,
    required this.onAreaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final areas = <String>{
      for (final a in attendances) a.cargoEmpleado ?? 'Sin área',
    }.toList()
      ..sort();

    // Aplicar filtro de área (null = todas).
    final visible = selectedArea == null
        ? attendances
        : attendances
            .where((a) => (a.cargoEmpleado ?? 'Sin área') == selectedArea)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chips de filtro por área ──
        _AreaFilterChips(
          areas: areas,
          selected: selectedArea,
          onSelected: onAreaSelected,
        ),
        const SizedBox(height: 16),

        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No hay registros en esta área',
                style: TextStyle(color: context.cTextSecondary, fontSize: 14),
              ),
            ),
          )
        else
          // ── Secciones agrupadas por área ──
          ..._groupByArea(visible).entries.map(
                (entry) => _AreaSection(area: entry.key, records: entry.value),
              ),
      ],
    );
  }

  Map<String, List<AttendanceModel>> _groupByArea(
      List<AttendanceModel> records) {
    final map = <String, List<AttendanceModel>>{};
    for (final r in records) {
      final area = r.cargoEmpleado ?? 'Sin área';
      map.putIfAbsent(area, () => []).add(r);
    }
    return map;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FILTRO POR ÁREA (chips)
// ═══════════════════════════════════════════════════════════════════════
class _AreaFilterChips extends StatelessWidget {
  final List<String> areas;
  final String? selected;
  final void Function(String?) onSelected;

  const _AreaFilterChips({
    required this.areas,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Todas las áreas"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              selectedColor: AppColors.primary,
              backgroundColor: context.cSurface,
              labelStyle: TextStyle(
                color: selected == null ? Colors.white : context.cTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: context.cBorder),
              showCheckmark: false,
            ),
          ),
          ...areas.map(
            (area) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(area),
                selected: selected == area,
                onSelected: (_) => onSelected(area),
                selectedColor: AppColors.primary,
                backgroundColor: context.cSurface,
                labelStyle: TextStyle(
                  color: selected == area ? Colors.white : context.cTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: context.cBorder),
                showCheckmark: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECCIÓN POR ÁREA
// ═══════════════════════════════════════════════════════════════════════
class _AreaSection extends StatelessWidget {
  final String area;
  final List<AttendanceModel> records;

  const _AreaSection({required this.area, required this.records});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado del área ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: context.cBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.domain,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    area,
                    style: TextStyle(
                      color: context.cTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${records.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Registros del área ──
          ...records.map((r) {
            final info = attendanceTypeInfo(r.tipo);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.cBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.fullName,
                      style: TextStyle(
                        color: context.cTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        info.label,
                        style: TextStyle(
                            color: info.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${dateFmt.format(r.fecha.toLocal())} · ${formatTimeOfDay(context, r.hora.toLocal())}',
                      style: TextStyle(
                          color: context.cTextSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
