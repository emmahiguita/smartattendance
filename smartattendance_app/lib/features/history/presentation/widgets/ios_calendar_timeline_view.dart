// lib/features/history/presentation/widgets/ios_calendar_timeline_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'google_meet_card.dart';
import 'history_detail_sheet.dart';

/// ============================================================================
/// COMPONENTE: IosCalendarTimelineView (Línea de Tiempo Diaria Google Calendar)
/// ============================================================================
/// QUÉ HACE: Agenda diaria estilo Google Calendar con Google Meet corporativo,
/// eje horario de 06:00 a 20:00 y bloques reales de eventos de asistencia.
/// CÓMO FUNCIONA: Mapea registros a escala horaria e integra [HistoryDetailSheet].
/// SOLID: SRP (Responsabilidad única de renderizar la agenda horaria diaria).
/// ============================================================================
class IosCalendarTimelineView extends StatelessWidget {
  final DateTime selectedDate;
  final List<AttendanceEntity> dayRecords;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  const IosCalendarTimelineView({
    super.key,
    required this.selectedDate,
    required this.dayRecords,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isToday(selectedDate);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es').format(selectedDate);
    final capitalizedDate = dateStr[0].toUpperCase() + dateStr.substring(1);

    return Column(
      children: [
        // 1. Selector de Día (Atrás / Adelante)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: onPreviousDay,
              ),
              Expanded(
                child: Text(
                  capitalizedDate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: onNextDay,
              ),
            ],
          ),
        ),

        // 2. Tarjeta Google Meet
        GoogleMeetCard(selectedDate: selectedDate),

        // 3. Eje Horario Continuo de 06:00 a 20:00
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 15,
          itemBuilder: (context, idx) {
            final hour = 6 + idx;
            final hourRecords = dayRecords.where((r) => r.hora.toLocal().hour == hour).toList();
            final isCurrentHour = isToday && now.hour == hour;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isCurrentHour ? Colors.redAccent.withValues(alpha: 0.5) : context.cBorder.withValues(alpha: 0.4),
                        width: isCurrentHour ? 1.5 : 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrentHour ? FontWeight.w800 : FontWeight.w500,
                            color: isCurrentHour ? Colors.redAccent : context.cTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: hourRecords.map((r) {
                            final info = attendanceTypeInfo(r.tipo);
                            final time = formatTimeOfDay(context, r.hora.toLocal());

                            return InkWell(
                              onTap: () => HistoryDetailSheet.show(context, r),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: info.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(left: BorderSide(color: info.color, width: 4)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        info.label,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: context.cTextPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: info.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador de línea roja para la hora actual
                if (isCurrentHour)
                  Positioned(
                    top: (now.minute / 60.0) * 52.0,
                    left: 42,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1.5,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
