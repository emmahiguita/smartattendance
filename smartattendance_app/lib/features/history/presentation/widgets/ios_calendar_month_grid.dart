// ============================================================================
// ARCHIVO: ios_calendar_month_grid.dart
// QUÉ HACE: Calendario visual estilo Apple iOS sin tarjetas ni bordes azules
//           para que el Administrador o Supervisor seleccione días del mes,
//           verifique cobertura y asigne horarios al personal.
// CÓMO FUNCIONA: Calcula la matriz de 7 columnas (Lunes a Domingo), muestra el
//                conteo programado por `weekday` y permite asignación en bloque.
// POR QUÉ: Elimina cajas y colores estridentes con divisores finos (< 185 líneas).
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
  final DateTime focusedMonth, selectedDate;
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _scheduledForWeekday(int weekday) => workers
      .where((w) => w.schedule?.weekdays.contains(weekday) ?? false)
      .length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthRaw = DateFormat('MMMM yyyy', 'es').format(focusedMonth);
    final monthTitle = monthRaw[0].toUpperCase() + monthRaw.substring(1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingBlanks =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final scheduledSelected = _scheduledForWeekday(selectedDate.weekday);
    final dayTitle =
        DateFormat('EEEE d MMM', 'es').format(selectedDate).toUpperCase();
    final textScale =
        (MediaQuery.textScalerOf(context).scale(12.5) / 12.5).clamp(1.0, 1.5);
    final isDark = context.isDark;
    final div = Divider(height: 1, thickness: 0.5, color: context.cBorder);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(CupertinoIcons.calendar, size: 17, color: context.cTextSecondary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(monthTitle,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    letterSpacing: -0.3))),
        GestureDetector(
          onTap: onToday,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: context.cBorder, width: 0.5)),
            child: Text('Hoy',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary)),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
            icon: Icon(CupertinoIcons.chevron_left,
                size: 16, color: context.cTextPrimary),
            visualDensity: VisualDensity.compact,
            onPressed: onPreviousMonth),
        IconButton(
            icon: Icon(CupertinoIcons.chevron_right,
                size: 16, color: context.cTextPrimary),
            visualDensity: VisualDensity.compact,
            onPressed: onNextMonth),
      ]),
      const SizedBox(height: 4),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        WeekdayLabel('L'),
        WeekdayLabel('M'),
        WeekdayLabel('M'),
        WeekdayLabel('J'),
        WeekdayLabel('V'),
        WeekdayLabel('S'),
        WeekdayLabel('D'),
      ]),
      const SizedBox(height: 2),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.25 / textScale),
        itemBuilder: (context, index) {
          if (index < leadingBlanks) return const SizedBox.shrink();
          final dayNum = index - leadingBlanks + 1;
          final d = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
          final isSel = _sameDay(d, selectedDate);
          final isToday = _sameDay(d, now);
          final active = _scheduledForWeekday(d.weekday) > 0;
          final selBg = isDark ? Colors.white : const Color(0xFF0F172A);
          final selFg = isDark ? Colors.black : Colors.white;

          return GestureDetector(
            onTap: () => onSelectDate(d),
            child: Container(
              decoration: BoxDecoration(
                color: isSel
                    ? selBg
                    : (isToday
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.07))
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Text('$dayNum',
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            (isSel || isToday) ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? selFg : context.cTextPrimary)),
                if (active)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: isSel ? selFg : AppColors.systemGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
      if (workers.isNotEmpty) ...[
        const SizedBox(height: 6),
        div,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('$dayTitle · $scheduledSelected de ${workers.length} con turno',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.cTextSecondary)),
              if (onBulkAssign != null)
                GestureDetector(
                  onTap: onBulkAssign,
                  child: Text('Asignar en bloque',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.cTextPrimary)),
                ),
            ],
          ),
        ),
      ],
      div,
    ]);
  }
}
