// ============================================================================
// ARCHIVO: work_totals.dart
// QUÉ HACE: Calcula la duración real de la jornada laboral y las Horas Extras.
// CÓMO FUNCIONA:
// 1. Verifica la secuencia de marcas (`MarkSequence.validate`) y acumula tiempo
//    activo (`active`) y almuerzo (`lunch`).
// 2. Si el trabajador tiene Horas Extras Asignadas (`assignedOvertimeMinutes > 0`)
//    y cumple su jornada (ya sea marcando Salida al terminar el turno base o
//    marcando Salida al finalizar las horas extras), el sistema contabiliza
//    automáticamente esas horas extras asignadas.
// POR QUÉ: Cumple la regla de negocio donde al cumplir el horario asignado con
//          horas extras asignadas ya se cuentan dichas horas extras (< 100 líneas).
// ============================================================================

import 'photo_record.dart';
import 'mark_sequence.dart';
import 'work_schedule.dart';
import 'time_bands.dart';

class WorkTotals {
  WorkTotals(List<PhotoRecord> records, this.schedule) {
    if (schedule != null) bands = TimeBands(schedule!);
    final sorted = [...records]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    PhotoRecord? previous;
    for (final mark in sorted) {
      try {
        MarkSequence.validate(previous?.type, mark.type);
      } on FormatException {
        issue = 'Secuencia inconsistente';
        break;
      }
      if (previous != null) {
        final delta = mark.capturedAt.toUtc().difference(previous.capturedAt.toUtc());
        if (delta <= Duration.zero || previous.workerId != mark.workerId) {
          issue = 'Horas inconsistentes';
          break;
        }
        if (previous.type == 'salida_almuerzo') {
          lunch += delta;
          if (schedule?.deductLunch == false) {
            bands?.add(previous.capturedAt, mark.capturedAt);
          }
        } else if (previous.type != 'salida') {
          active += delta;
          bands?.add(previous.capturedAt, mark.capturedAt);
        }
      }
      previous = mark;
    }
    if (issue == null && (previous == null || previous.type != 'salida')) {
      issue = 'Jornada incompleta';
    }
  }

  final WorkSchedule? schedule;
  Duration active = Duration.zero, lunch = Duration.zero;
  String? issue;
  TimeBands? bands;

  bool get complete => issue == null;
  Duration get presence => active + lunch;

  Duration? get worked {
    if (!complete || schedule == null) return null;
    final baseWorked = active + (schedule!.deductLunch ? Duration.zero : lunch);
    if (schedule!.assignedOvertimeMinutes > 0) {
      final minWithOvertime = Duration(minutes: schedule!.dailyMinutes + schedule!.assignedOvertimeMinutes);
      return baseWorked >= minWithOvertime ? baseWorked : baseWorked + Duration(minutes: schedule!.assignedOvertimeMinutes);
    }
    return baseWorked;
  }

  Duration? get additional {
    final value = worked;
    if (value == null || schedule == null) return null;
    final extra = value - Duration(minutes: schedule!.dailyMinutes);
    final assignedExtra = Duration(minutes: schedule!.assignedOvertimeMinutes);
    final effectiveExtra = extra >= assignedExtra ? extra : assignedExtra;
    return effectiveExtra.isNegative ? Duration.zero : effectiveExtra;
  }

  /// Mismos resultados para pantalla, CSV, XLSX y PDF.
  Map<String, String> get labels => {
        'Estado de jornada': issue ?? (schedule?.hasAssignedOvertime == true ? 'Completa (+Extras asignadas)' : 'Completa'),
        'Permanencia': complete ? ColombiaClock.duration(presence) : 'Por revisar',
        'Almuerzo registrado': complete ? ColombiaClock.duration(lunch) : 'Por revisar',
        'Tiempo trabajado': worked == null ? 'Requiere jornada pactada' : ColombiaClock.duration(worked!),
        'Adicional por revisar': additional == null ? 'Sin cálculo' : ColombiaClock.duration(additional!),
      };
}
