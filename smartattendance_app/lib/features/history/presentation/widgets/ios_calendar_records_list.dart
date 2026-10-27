// ============================================================================
// ARCHIVO: ios_calendar_records_list.dart
// QUÉ HACE: Renderiza la bitácora de marcaciones agrupadas por fecha en bloques
//           estilo Apple iOS Inset Grouped con divisores finos (0.5px) y
//           filtros rápidos por tipo de evento (Todas, Entradas, Almuerzos, Salidas).
// CÓMO FUNCIONA: Agrupa los registros por día calendario, muestra cabecera en
//                mayúsculas estilo iOS Settings y abre `HistoryDetailSheet` al tocar.
// POR QUÉ: Sustituye listas desordenadas por secciones nativas Cupertino (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'history_detail_sheet.dart';

class IosCalendarRecordsList extends StatelessWidget {
  final DateTime selectedDate;
  final List<AttendanceEntity> dayRecords;
  final List<AttendanceEntity> allRecords;
  final String? filterType;
  final ValueChanged<String?> onFilterChanged;
  final bool isDayOnly;

  const IosCalendarRecordsList({
    super.key,
    required this.selectedDate,
    required this.dayRecords,
    required this.allRecords,
    this.filterType,
    required this.onFilterChanged,
    this.isDayOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final source = isDayOnly ? dayRecords : allRecords;
    final filtered = filterType == null
        ? source
        : source.where((r) => r.tipo.toLowerCase().contains(filterType!.toLowerCase())).toList();

    final grouped = <DateTime, List<AttendanceEntity>>{};
    for (final r in filtered) {
      grouped.putIfAbsent(DateTime(r.fecha.year, r.fecha.month, r.fecha.day), () => []).add(r);
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _filterPill(context, null, 'Todas (${source.length})'),
          const SizedBox(width: 6),
          _filterPill(context, 'entrada', 'Entradas'),
          const SizedBox(width: 6),
          _filterPill(context, 'almuerzo', 'Almuerzos'),
          const SizedBox(width: 6),
          _filterPill(context, 'salida', 'Salidas'),
        ]),
      ),
      const SizedBox(height: 14),
      if (sortedDays.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
          decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cBorder, width: 0.5)),
          child: Column(children: [
            Icon(CupertinoIcons.clock, size: 28, color: context.cTextSecondary),
            const SizedBox(height: 8),
            Text('Sin marcaciones en este periodo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
          ]),
        )
      else
        for (final day in sortedDays) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(_formatDayHeader(day), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: context.cTextSecondary)),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cBorder, width: 0.5)),
            child: Column(children: [
              for (var i = 0; i < grouped[day]!.length; i++) ...[
                _buildRecordRow(context, grouped[day]![i]),
                if (i < grouped[day]!.length - 1) Divider(height: 1, thickness: 0.5, indent: 52, color: context.cBorder),
              ],
            ]),
          ),
        ],
    ]);
  }

  String _formatDayHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final datePart = DateFormat('d MMM yyyy', 'es').format(d).toUpperCase();
    if (d == today) return 'HOY · $datePart';
    if (d == today.subtract(const Duration(days: 1))) return 'AYER · $datePart';
    return DateFormat('EEEE, d MMM yyyy', 'es').format(d).toUpperCase();
  }

  Widget _filterPill(BuildContext context, String? type, String label) {
    final sel = filterType == type;
    return GestureDetector(
      onTap: () => onFilterChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : context.cSurface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: sel ? AppColors.primary : context.cBorder, width: 0.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Colors.white : context.cTextPrimary)),
      ),
    );
  }

  Widget _buildRecordRow(BuildContext context, AttendanceEntity r) {
    final info = attendanceTypeInfo(r.tipo);
    final time = formatTimeOfDay(context, r.hora.toLocal());
    return InkWell(
      onTap: () => HistoryDetailSheet.show(context, r),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: info.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(7)),
            child: Icon(info.icon, color: info.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(info.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
          Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextSecondary)),
          const SizedBox(width: 6),
          Icon(CupertinoIcons.chevron_forward, size: 14, color: context.cTextSecondary),
        ]),
      ),
    );
  }
}
