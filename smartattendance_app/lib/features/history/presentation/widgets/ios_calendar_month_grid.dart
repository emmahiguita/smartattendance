// ============================================================================
// ARCHIVO: ios_calendar_month_grid.dart
// QUÉ HACE: Calendario visual estilo Apple iOS para que el Administrador en
//           Gestión RRHH -> Horarios seleccione días del mes, verifique qué
//           jornadas están activas y asigne horarios al personal.
// CÓMO FUNCIONA: Calcula la matriz de 7 columnas (Lunes a Domingo), muestra el
//                conteo de personal programado por día de la semana (`weekday`)
//                y permite asignación rápida en bloque desde la barra inferior.
// POR QUÉ: Reubica el calendario desde Historial hacia el módulo administrativo
//          de Horarios cumpliendo SRP (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import 'weekday_label.dart';

class IosCalendarMonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<AttendanceEntity> records;
  final List<LocalWorker> workers;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousMonth, onNextMonth, onToday;
  final VoidCallback? onBulkAssign;

  const IosCalendarMonthGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    this.records = const [],
    this.workers = const [],
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    this.onBulkAssign,
  });

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  int _scheduledForWeekday(int weekday) =>
      workers.where((w) => w.schedule?.weekdays.contains(weekday) ?? false).length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthRaw = DateFormat('MMMM yyyy', 'es').format(focusedMonth);
    final monthTitle = monthRaw[0].toUpperCase() + monthRaw.substring(1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingBlanks = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final scheduledSelected = _scheduledForWeekday(selectedDate.weekday);
    final dayTitle = DateFormat('EEEE d MMM', 'es').format(selectedDate).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.cBorder, width: 0.5)),
      child: Column(children: [
        Row(children: [
          const Icon(CupertinoIcons.calendar, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(monthTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.cTextPrimary, letterSpacing: -0.3))),
          GestureDetector(
            onTap: onToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
              child: const Text('Hoy', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(CupertinoIcons.chevron_left, size: 17), visualDensity: VisualDensity.compact, onPressed: onPreviousMonth),
          IconButton(icon: const Icon(CupertinoIcons.chevron_right, size: 17), visualDensity: VisualDensity.compact, onPressed: onNextMonth),
        ]),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [WeekdayLabel('L'), WeekdayLabel('M'), WeekdayLabel('M'), WeekdayLabel('J'), WeekdayLabel('V'), WeekdayLabel('S'), WeekdayLabel('D')],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 1.18),
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final dayNum = index - leadingBlanks + 1;
            final d = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
            final isSelected = _isSameDay(d, selectedDate);
            final isToday = _isSameDay(d, now);
            final activeCount = _scheduledForWeekday(d.weekday);

            return GestureDetector(
              onTap: () => onSelectDate(d),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: (isSelected || isToday) ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isToday ? AppColors.primary : context.cTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: activeCount > 0 ? (isSelected ? Colors.white : AppColors.systemGreen) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
        if (workers.isNotEmpty) ...[
          Divider(height: 16, thickness: 0.5, color: context.cBorder),
          Row(children: [
            Expanded(
              child: Text(
                '$dayTitle · $scheduledSelected de ${workers.length} con turno',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextSecondary),
              ),
            ),
            if (onBulkAssign != null)
              GestureDetector(
                onTap: onBulkAssign,
                child: const Text('Asignar en bloque', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
          ]),
        ],
      ]),
    );
  }
}
