import 'package:path/path.dart' as p;
import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import '../domain/journey_report.dart';

/// Una fila por trabajador/día. Listas de horas/fotos mantienen varias jornadas
/// sin sobrescribir entradas o descansos. CSV referencia fotos; XLSX las incrusta.
class PhotoDayTable {
  static const stages = {
    'entrada': 'Entrada',
    'salida_almuerzo': 'Inicio almuerzo',
    'regreso_almuerzo': 'Regreso almuerzo',
    'salida': 'Salida'
  };
  static const headers = [
    'Fecha',
    'Trabajador',
    'Cédula',
    'Cargo',
    'Entrada',
    'Foto entrada',
    'Inicio almuerzo',
    'Foto almuerzo',
    'Regreso almuerzo',
    'Foto regreso',
    'Salida',
    'Foto salida',
    'GPS entrada',
    'GPS inicio almuerzo',
    'GPS regreso almuerzo',
    'GPS salida',
    'Zona / Sede Asignada',
    ...JourneyReport.headers,
    'Encargados de las marcaciones',
  ];

  static List<String> cells(PhotoDay day) => [
        day.date.toIso8601String().split('T').first,
        day.worker.name,
        day.worker.document,
        day.worker.job,
        for (final type in stages.keys) ...[
          day
              .marks(type)
              .map((r) => ColombiaClock.hour(r.capturedAt))
              .join('\n'),
          day.marks(type).map((r) => p.basename(r.localPath)).join('\n'),
        ],
        // Columnas al final conservan las posiciones de las fotos incrustadas.
        // Cada línea corresponde a una hora/foto, incluso con varias jornadas.
        for (final type in stages.keys)
          day.marks(type).map((r) {
            final gps = r.location;
            return gps == null
                ? 'Sin GPS guardado'
                : '${gps.description} | GPS: ${ColombiaClock.wall(gps.fixedAt).toIso8601String()}';
          }).join('\n'),
        day.zoneName ?? 'Sede Principal Operativa',
        ...JourneyReport.cells(day),
        day.records
            .map((r) =>
                '${r.type}: ${r.operatorDocument ?? 'Sin dato histórico'}')
            .join('\n'),
      ];
}
