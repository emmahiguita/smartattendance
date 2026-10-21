import 'photo_record.dart';
import 'mark_sequence.dart';
import 'work_schedule.dart';
import 'time_bands.dart';

/// Calcula intervalos completos con duración UTC, incluso al cruzar medianoche.
/// No extiende una entrada abierta hasta «ahora» ni completa horas inexistentes.
class WorkTotals {
  WorkTotals(List<PhotoRecord> records, this.schedule) {
    if (schedule != null) bands = TimeBands(schedule!);
    final sorted = [...records]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    PhotoRecord? previous;
    for (final mark in sorted) {
      try {
        MarkSequence.validate(previous?.type, mark.type);
      } on FormatException {
        issue = 'Secuencia inconsistente';
        break;
      }
      if (previous != null) {
        final delta =
            mark.capturedAt.toUtc().difference(previous.capturedAt.toUtc());
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
  Duration? get worked => !complete || schedule == null
      ? null
      : active + (schedule!.deductLunch ? Duration.zero : lunch);
  Duration? get additional {
    final value = worked;
    if (value == null) return null;
    final extra = value - Duration(minutes: schedule!.dailyMinutes);
    return extra.isNegative ? Duration.zero : extra;
  }

  /// Mismos resultados para pantalla, CSV, XLSX y PDF: no hay cuatro cálculos.
  Map<String, String> get labels => {
        'Estado de jornada': issue ?? 'Completa',
        'Permanencia':
            complete ? ColombiaClock.duration(presence) : 'Por revisar',
        'Almuerzo registrado':
            complete ? ColombiaClock.duration(lunch) : 'Por revisar',
        'Tiempo trabajado': worked == null
            ? 'Requiere jornada pactada'
            : ColombiaClock.duration(worked!),
        'Adicional por revisar': additional == null
            ? 'Sin cálculo'
            : ColombiaClock.duration(additional!),
      };
}
