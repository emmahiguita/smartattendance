// ============================================================================
// ARCHIVO: ios_attendance_calendar.dart
// QUÉ HACE: Bitácora de historial de asistencia estilo Apple iOS Inset Grouped
//           con filtro rápido de periodo (Hoy, 7 días, Mes, Todo), filtro por
//           tipo de marcación y botón nativo de exportación (CSV / Excel).
// CÓMO FUNCIONA: Elimina el calendario mensual de Historial (movido a RRHH ->
//                Horarios) y presenta los registros de SQLite en bloques
//                agrupados estilo iOS limpios y entendibles.
// POR QUÉ: Cumple la directriz del usuario de no mezclar el calendario de
//          asignación de horarios en Historial y respeta SRP (< 165 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'ios_calendar_records_list.dart';

class IosAttendanceCalendar extends StatefulWidget {
  final List<AttendanceEntity> records;
  final VoidCallback onExport;
  final Future<void> Function() onRefresh;

  const IosAttendanceCalendar({
    super.key,
    required this.records,
    required this.onExport,
    required this.onRefresh,
  });

  @override
  State<IosAttendanceCalendar> createState() => _IosAttendanceCalendarState();
}

class _IosAttendanceCalendarState extends State<IosAttendanceCalendar> {
  String _period = 'month';
  String? _filterType;

  List<AttendanceEntity> _filteredByPeriod() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.records.where((r) {
      final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
      return switch (_period) {
        'today' => d == today,
        'week' => now.difference(d).inDays <= 7,
        'month' => r.fecha.year == now.year && r.fecha.month == now.month,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final periodRecords = _filteredByPeriod();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // Cabecera iOS con control segmentado de periodo y botón Compartir
          Row(
            children: [
              Expanded(
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _period,
                  backgroundColor: context.cSurface,
                  thumbColor: AppColors.primary,
                  children: {
                    'today': _segLabel('Hoy', _period == 'today'),
                    'week': _segLabel('7 días', _period == 'week'),
                    'month': _segLabel('Mes', _period == 'month'),
                    'all': _segLabel('Todo', _period == 'all'),
                  },
                  onValueChanged: (v) {
                    if (v != null) setState(() => _period = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.onExport,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: context.cSurface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.cBorder, width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.share,
                          size: 15, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'Exportar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IosCalendarRecordsList(
            selectedDate: DateTime.now(),
            dayRecords: periodRecords,
            allRecords: periodRecords,
            filterType: _filterType,
            onFilterChanged: (f) => setState(() => _filterType = f),
            isDayOnly: false,
          ),
        ],
      ),
    );
  }

  Widget _segLabel(String text, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? Colors.white : context.cTextPrimary,
        ),
      ),
    );
  }
}
