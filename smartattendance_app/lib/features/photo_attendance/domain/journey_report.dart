import 'photo_record.dart';
import 'work_schedule.dart';

/// Una sola representación para pantalla y formatos. El adicional calculado
/// requiere revisión: no se transforma automáticamente en extras aprobadas.
abstract final class JourneyReport {
  static const headers = [
    'Estado de jornada',
    'Permanencia',
    'Almuerzo registrado',
    'Tiempo trabajado',
    'Adicional por revisar',
    'Ordinarias diurnas',
    'Ordinarias nocturnas',
    'Adicional diurno',
    'Adicional nocturno',
    'Trabajo dominical',
    'Trabajo festivo',
    'Adicional aprobado',
    'Revisado por',
    'Revisado el',
    'Nota de revisión'
  ];
  static List<String> cells(PhotoDay day) {
    final totals = day.totals;
    final bands = totals.bands;
    final known = totals.complete && bands != null && day.status != 'void';
    return [
      ...totals.labels.values.toList().asMap().entries.map((e) =>
          day.status == 'void'
              ? (e.key == 0 ? 'Cerrada como incompleta' : 'Por revisar')
              : e.value),
      for (var i = 0; i < 6; i++)
        known ? ColombiaClock.duration(bands.values[i]) : 'Sin cálculo',
      day.approvedSeconds == null
          ? 'Sin aprobación'
          : ColombiaClock.duration(Duration(seconds: day.approvedSeconds!)),
      day.reviewedBy ?? '',
      day.reviewedAt == null
          ? ''
          : ColombiaClock.wall(DateTime.parse(day.reviewedAt!))
              .toIso8601String()
              .replaceAll('Z', ''),
      day.reviewNote ?? '',
    ];
  }

  static Map<String, String> labels(PhotoDay day) =>
      Map.fromIterables(headers, cells(day));
}
