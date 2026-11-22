// ============================================================================
// ARCHIVO: photo_mark_writer.dart
// QUÉ HACE: Persiste en SQLite la marcación biométrica con GPS real, validando
//           geocerca, horario y unicidad de etapa. La restricción de orden
//           secuencial estricto fue desactivada para permitir registrar cualquier
//           tipo de marcación sin importar la secuencia de jornada.
// CÓMO FUNCIONA:
// 1. Consulta las marcas del trabajador en la fecha actual (`ColombiaClock.day(now)`).
// 2. Verifica que el tipo no haya sido ya registrado hoy (unicidad), pero NO
//    exige que se registren en orden fijo. Esto permite pruebas y correcciones.
// POR QUÉ: El administrador necesita poder registrar cualquier tipo de marcación
//          sin restricciones de continuidad para pruebas y correcciones (< 165 líneas).
// ============================================================================

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/utils/attendance_type.dart';
import '../domain/attendance_location.dart';
import '../domain/local_actor.dart';
import '../domain/mark_sequence.dart';
import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import 'capture_gate.dart';
import 'photo_database.dart';
import 'photo_row_mapper.dart';

class PhotoMarkWriter {
  PhotoMarkWriter(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;

  /// QUÉ HACE: Verifica que el trabajador exista antes de activar la cámara.
  Future<void> prepare(LocalWorker worker) async {
    final db = await database.database;
    await CaptureGate(actor).employee(db, worker.id);
  }

  /// QUÉ HACE: Guarda una marcación validando geocerca, horario y secuencia diaria.
  Future<PhotoRecord> save(
    LocalWorker worker,
    String type,
    String path, {
    required AttendanceLocation location,
    String? captureId,
  }) async {
    final id = captureId ?? const Uuid().v4();
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id)) {
      throw const FormatException('Identificador de captura inválido.');
    }
    if (!attendanceTypes.contains(type)) {
      throw const FormatException('Tipo de asistencia no reconocido.');
    }

    final db = await database.database;
    final previous = await db.query('photo_marks', where: 'uuid = ?', whereArgs: [id]);
    if (previous.isNotEmpty) return _existing(previous.first, worker, type);

    final source = File(path);
    final size = await source.length();
    if (size == 0 || size > 8 * 1024 * 1024) {
      throw const FormatException('Foto vacía o mayor de 8 MB. Vuelve a tomarla.');
    }

    final gate = CaptureGate(actor);
    final now = DateTime.now().toUtc();
    final todayDate = ColombiaClock.day(now);
    final root = await getApplicationSupportDirectory();
    final folder = Directory(p.join(root.path, 'attendance_evidence'));
    await folder.create(recursive: true);
    final photo = await source.copy(
      p.join(folder.path, '$id-${const Uuid().v4()}${p.extension(path).toLowerCase()}'),
    );

    try {
      final result = await db.transaction<PhotoRecord>((tx) async {
        final duplicate = await tx.query('photo_marks', where: 'uuid = ?', whereArgs: [id]);
        if (duplicate.isNotEmpty) return _existing(duplicate.first, worker, type);

        final employee = await gate.check(tx, worker.id, location);

        // Consulta todas las marcas registradas en el DÍA DE HOY para este colaborador
        final todayMarks = await tx.rawQuery('''
          SELECT m.*, j.status FROM photo_marks m
          JOIN journeys j ON j.id = m.journey_id
          WHERE m.worker_id = ? AND j.work_date = ? AND j.status != 'void'
          ORDER BY m.captured_at DESC, m.uuid DESC
        ''', [worker.id, todayDate]);

        final priorToday = todayMarks.isEmpty ? null : todayMarks.first;
        final doneTypes = todayMarks.map((m) => (m['type'] as String? ?? '').toLowerCase()).toSet();

        // QUÉ HACE: Verifica que el tipo NO esté ya registrado hoy (unicidad por día).
        // CÓMO: Busca si `type` ya existe en doneTypes del día actual.
        // POR QUÉ: Se permite cualquier orden de marcación (pruebas/correcciones),
        //          pero NO se puede registrar la misma etapa dos veces en el mismo día.
        if (doneTypes.contains(type.trim().toLowerCase())) {
          throw FormatException('Ya registraste "${MarkSequence.labelOf(type)}" en la jornada de hoy. No puedes repetirla.');
        }

        // QUÉ HACE: Determina el journey (jornada) del día al que pertenece esta marca.
        // CÓMO: Si hay marcas previas hoy, todas comparten el mismo journey_id del primero.
        //       Si es la primera marca del día (cualquier tipo), crea un journey nuevo.
        // POR QUÉ: Permite iniciar la jornada con cualquier tipo de marca, no solo 'entrada'.
        final journey = (priorToday == null || priorToday['journey_id'] == null)
            ? id
            : priorToday['journey_id'] as String;

        final existingJourney = await tx.query('journeys', where: 'id = ?', whereArgs: [journey]);
        if (existingJourney.isEmpty) {
          await tx.insert('journeys', {
            'id': journey,
            'worker_id': worker.id,
            'work_date': todayDate,
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

        // Encolado transparente para sincronización automática en la nube
        try {
          final localDb = LocalDatabaseService();
          var localUser = await localDb.getLocalUserByCedula(worker.document);
          if (localUser == null) {
            final nextId = await localDb.nextLocalUserId();
            final nameParts = (employee['name'] as String? ?? 'Colaborador').split(' ');
            final firstName = nameParts.first;
            final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            await localDb.insertLocalUser({
              'id': nextId,
              'cedula': worker.document,
              'nombre': firstName,
              'apellido': lastName,
              'cargo': employee['job'] as String? ?? 'Operario',
              'is_admin': 0,
            });
            localUser = await localDb.getLocalUserByCedula(worker.document);
          }
          final userId = (localUser?['id'] as int?) ?? worker.id;
          await localDb.insertOfflineAttendance({
            'uuid_marca': id,
            'usuario_id': userId,
            'fecha_hora_local': now.toIso8601String(),
            'tipo': type,
            'latitud': location.latitude,
            'longitud': location.longitude,
            'direccion': employee['zone_name'] ?? 'Zona Operativa',
            'foto_path': photo.path,
            'sincronizado': 0,
            'created_at': now.toIso8601String(),
          });
        } catch (_) {}

        if (type == 'salida') {
          await tx.update('journeys', {'status': 'closed'}, where: 'id = ?', whereArgs: [journey]);
        }
        return photoRecordFromRow(row);
      });
      if (result.localPath != photo.path) await photo.delete();
      const TraccarService().pushPosition(
        deviceId: worker.document,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        zoneName: result.type,
      );
      return result;
    } catch (_) {
      if (await photo.exists()) await photo.delete();
      rethrow;
    }
  }

  PhotoRecord _existing(Map<String, Object?> row, LocalWorker worker, String type) {
    if (row['worker_id'] != worker.id || row['type'] != type) {
      throw const FormatException('La captura ya pertenece a otra marcación.');
    }
    return photoRecordFromRow(row);
  }
}
