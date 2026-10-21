// lib/features/history/presentation/widgets/ios_calendar_month_grid.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'weekday_label.dart';

/// ============================================================================
/// COMPONENTE: IosCalendarMonthGrid (Cuadrícula Mensual Estilo iOS)
/// ============================================================================
/// QUÉ HACE:
/// Dibuja el selector de mes y la cuadrícula interactiva de 7 columnas
/// con encabezados de lunes a domingo e indicadores cromáticos de asistencia.
///
/// CÓMO FUNCIONA:
/// 1. Calcula los días del mes y el desplazamiento del primer día de la semana.
/// 2. Cruza con la lista de [records] para proyectar puntos de estado por día.
/// 3. Resalta la fecha actual y la fecha seleccionada con círculos distintivos.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP):
/// Aislar la cuadrícula mensual previene tener archivos gigantes y permite
/// que los cálculos de geometría de calendario se ejecuten sin lag.
/// ============================================================================
class IosCalendarMonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<AttendanceEntity> records;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  const IosCalendarMonthGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.records,
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'es').format(focusedMonth);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday; // 1=Lunes, 7=Domingo
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cBorder, width: 1.0),
      ),
      child: Column(
        children: [
          // 1. Selector de Mes y Botón 'Hoy'
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                onPressed: onPreviousMonth,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  capitalizedMonth,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                onPressed: onNextMonth,
                visualDensity: VisualDensity.compact,
              ),
              TextButton(
                onPressed: onToday,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.systemBlue,
                ),
                child: const Text('Hoy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Encabezados de Días de la Semana (L M M J V S D)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              WeekdayLabel('L'),
              WeekdayLabel('M'),
              WeekdayLabel('M'),
              WeekdayLabel('J'),
              WeekdayLabel('V'),
              WeekdayLabel('S'),
              WeekdayLabel('D'),
            ],
          ),
          const SizedBox(height: 6),

          // 3. Matriz de Días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final dayNumber = index - leadingBlanks + 1;
              final dayDate = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
              final isSelected = _isSameDay(dayDate, selectedDate);
              final isToday = _isSameDay(dayDate, now);

              // Registros de este día específico
              final dayRecords = records.where((r) => _isSameDay(r.fecha, dayDate)).toList();

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelectDate(dayDate),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.systemBlue
                        : (isToday ? AppColors.systemBlue.withValues(alpha: 0.12) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.systemBlue : context.cTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Puntos de estado de asistencia
                      if (dayRecords.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : (dayRecords.length >= 2 ? AppColors.systemGreen : const Color(0xFFF59E0B)),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox(height: 4.5),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
