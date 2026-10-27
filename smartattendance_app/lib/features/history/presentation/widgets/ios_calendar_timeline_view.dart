// ============================================================================
// ARCHIVO: ios_calendar_timeline_view.dart
// QUÉ HACE: Muestra la línea de tiempo cronológica real de las marcaciones del
//           día seleccionado (Entrada, Inicio Almuerzo, Regreso, Salida).
// CÓMO FUNCIONA: Ordena los `AttendanceEntity` reales por hora y renderiza cada
//                hito con su hora exacta, dirección/geocerca y acceso al detalle.
// POR QUÉ: Reemplaza la tarjeta simulada/ajena de "Google Meet" por una
//          cronología real de asistencia laboral (< 170 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'history_detail_sheet.dart';

class IosCalendarTimelineView extends StatelessWidget {
  final DateTime selectedDate;
  final List<AttendanceEntity> dayRecords;

  const IosCalendarTimelineView({
    super.key,
    required this.selectedDate,
    required this.dayRecords,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE d MMMM, yyyy', 'es').format(selectedDate);
    final sorted = [...dayRecords]..sort((a, b) => a.hora.compareTo(b.hora));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cronología · $dateStr',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                ),
              ),
              Text(
                '${sorted.length} hitos',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (sorted.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 34,
                  color: context.cTextSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin marcaciones registradas en esta fecha',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cTextSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...sorted.map((r) {
            final info = attendanceTypeInfo(r.tipo);
            final timeStr = formatTimeOfDay(context, r.hora.toLocal());
            final subtitle = (r.direccion != null && r.direccion!.isNotEmpty)
                ? r.direccion!
                : 'Verificación biométrica + GPS';
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => HistoryDetailSheet.show(context, r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: info.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(info.icon, color: info.color, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: context.cTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.cTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: info.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
