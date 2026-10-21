// lib/features/photo_attendance/data/photo_mark_writer.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/attendance_type.dart';
import '../domain/attendance_location.dart';
import '../domain/local_actor.dart';
import '../domain/mark_sequence.dart';
import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import 'capture_gate.dart';
import 'photo_database.dart';
import 'photo_row_mapper.dart';

/// ============================================================================
/// SERVICIO: PhotoMarkWriter (guarda UNA marcación de forma atómica)
/// ============================================================================
/// QUÉ HACE:
/// Persiste en SQLite la foto + coordenadas GPS REALES + tipo de marca
/// (Entrada, Inicio almuerzo, Regreso almuerzo, Salida).
///
/// CÓMO FUNCIONA (save):
/// 1. Valida id de captura, tipo y tamaño de la foto.
/// 2. Copia la foto a la carpeta privada de la app (evidencia durable).
/// 3. Abre una transacción ACID: evita duplicados por UUID, aplica la
///    geocerca del admin ([CaptureGate.check]), asocia la jornada
///    ([journeys]) e inserta la fila. Si algo falla, borra solo la copia nueva.
///
/// POR QUÉ:
/// - La ubicación llega YA capturada desde la pantalla (se pidió en paralelo
///   mientras la cámara estaba abierta): así no se suman ~20 s de GPS
///   después de la foto (cuello de botella eliminado).
/// - Sin GPS no hay marca: antes se guardaba con latitud/longitud nulas
///   cuando no había zona asignada; ahora toda marca lleva coordenadas.
/// ============================================================================
class PhotoMarkWriter {
  PhotoMarkWriter(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;

  /// Verificación rápida ANTES de abrir la cámara (sin GPS): el trabajador
  /// existe en el dispositivo. Falla pronto en vez de después de la foto.
  Future<void> prepare(LocalWorker worker) async {
    final db = await database.database;
    await CaptureGate(actor).employee(db, worker.id);
  }

  Future<PhotoRecord> save(
    LocalWorker worker,
    String type,
    String path, {
    required AttendanceLocation location,
    String? captureId,
  }) async {
    // 1. Validaciones de entrada (baratas, antes de tocar disco o SQL).
    final id = captureId ?? const Uuid().v4();
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id)) {
      throw const FormatException('Identificador de captura inválido.');
    }
    if (!attendanceTypes.contains(type)) {
      throw const FormatException('Tipo de asistencia no reconocido.');
    }

    // Idempotencia: si esta captura ya se guardó (doble toque, reintento),
    // devuelve el registro existente en vez de duplicarlo.
    final db = await database.database;
    final previous =
        await db.query('photo_marks', where: 'uuid = ?', whereArgs: [id]);
    if (previous.isNotEmpty) return _existing(previous.first, worker, type);

    final source = File(path);
    final size = await source.length();
    if (size == 0 || size > 8 * 1024 * 1024) {
      throw const FormatException('Foto vacía o mayor de 8 MB. Vuelve a tomarla.');
    }

    // 2. Copia durable de la evidencia en almacenamiento privado.
    final gate = CaptureGate(actor);
    final now = DateTime.now().toUtc();
    final root = await getApplicationSupportDirectory();
    final folder = Directory(p.join(root.path, 'attendance_evidence'));
    await folder.create(recursive: true); // async: no bloquea el hilo de UI
    final photo = await source.copy(p.join(folder.path,
        '$id-${const Uuid().v4()}${p.extension(path).toLowerCase()}'));

    try {
      // 3. Transacción: todo se guarda o nada se guarda.
      final result = await db.transaction<PhotoRecord>((tx) async {
        final duplicate =
            await tx.query('photo_marks', where: 'uuid = ?', whereArgs: [id]);
        if (duplicate.isNotEmpty) return _existing(duplicate.first, worker, type);

        final employee = await gate.check(tx, worker.id, location);
        final last = await tx.rawQuery('''SELECT m.*, j.status FROM photo_marks m
          JOIN journeys j ON j.id=m.journey_id WHERE m.worker_id=?
          ORDER BY m.captured_at DESC, m.uuid DESC LIMIT 1''', [worker.id]);
        final prior = last.isEmpty ? null : last.first;
        final voided = prior?['status'] == 'void';
        MarkSequence.validate(voided ? null : prior?['type'] as String?, type);

        // Una 'entrada' abre jornada nueva; las demás marcas se unen a la
        // jornada de la marca anterior.
        final journey = (type == 'entrada' ||
                prior == null ||
                prior['journey_id'] == null)
            ? id
            : prior['journey_id'] as String;

        final existingJourney =
            await tx.query('journeys', where: 'id = ?', whereArgs: [journey]);
        if (existingJourney.isEmpty) {
          await tx.insert('journeys', {
            'id': journey,
            'worker_id': worker.id,
            'work_date': ColombiaClock.day(now),
            'status': 'open',
            'schedule_json': employee['schedule_json'],
            'operator_document': actor.document,
            'crew_name': employee['crew_name'],
            'zone_name': employee['zone_name'],
          });
        }

        final row = <String, Object?>{
          'uuid': id,
          'worker_id': worker.id,
          'name': employee['name'],
          'document': employee['document'],
          'job': employee['job'],
          'type': type,
          'captured_at': now.toIso8601String(),
          'local_path': photo.path,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy_m': location.accuracy,
          'location_at': location.fixedAt.toUtc().toIso8601String(),
          'journey_id': journey,
          'operator_document': actor.document,
        };
        await tx.insert('photo_marks', row);

        // La salida cierra la jornada.
        if (type == 'salida') {
          await tx.update('journeys', {'status': 'closed'},
              where: 'id = ?', whereArgs: [journey]);
        }
        return photoRecordFromRow(row);
      });
      if (result.localPath != photo.path) await photo.delete();
      return result;
    } catch (_) {
      // Rollback de archivo: borra SOLO la copia recién creada.
      if (await photo.exists()) await photo.delete();
      rethrow;
    }
  }

  /// Devuelve el registro ya guardado si coincide trabajador y tipo.
  PhotoRecord _existing(Map<String, Object?> row, LocalWorker worker, String type) {
    if (row['worker_id'] != worker.id || row['type'] != type) {
      throw const FormatException('La captura ya pertenece a otra marcación.');
    }
    return photoRecordFromRow(row);
  }
}
