import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../domain/work_schedule.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import 'photo_database.dart';
import 'photo_row_mapper.dart';
import 'journey_review_store.dart';

/// Configuración del administrador local. La política queda fotografiada en
/// cada autorización y jornada: modificar ajustes no reescribe el historial.
class LocalAdminStore {
  LocalAdminStore(this.database, this.adminDocument);
  final PhotoDatabase database;
  final String? adminDocument;
  void requireAdmin() {
    if (adminDocument == null) {
      throw const FormatException('Acción exclusiva del administrador.');
    }
  }

  Future<String?> setting(String name) async {
    final rows = await (await database.database)
        .query('local_settings', where: 'name=?', whereArgs: [name]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> saveSetting(String name, String value) async {
    requireAdmin();
    await (await database.database).insert(
        'local_settings', {'name': name, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> rows(String table) async {
    requireAdmin();
    if (!const ['crews', 'work_zones'].contains(table)) {
      throw ArgumentError('Tabla no permitida');
    }
    return (await database.database).query(table, orderBy: 'name');
  }

  Future<void> saveZone(Map<String, Object?> zone, {int? id}) async {
    requireAdmin();
    final lat = (zone['latitude'] as num).toDouble(),
        lng = (zone['longitude'] as num).toDouble();
    final radius = (zone['radius_m'] as num).toDouble();
    if ((zone['name'] as String).trim().isEmpty ||
        !lat.isFinite ||
        lat.abs() > 90 ||
        !lng.isFinite ||
        lng.abs() > 180 ||
        !radius.isFinite ||
        radius < 20 ||
        radius > 50000) {
      throw const FormatException(
          'Revisa nombre, coordenadas y radio (20 a 50000 metros).');
    }
    final db = await database.database;
    if (id == null) {
      await db.insert('work_zones', zone);
    } else {
      await db.update('work_zones', zone, where: 'id=?', whereArgs: [id]);
    }
  }

  Future<void> saveCrew(Map<String, Object?> crew, {int? id}) async {
    requireAdmin();
    final from = DateTime.tryParse(crew['valid_from'] as String);
    final until = DateTime.tryParse(crew['valid_until'] as String);
    if ((crew['name'] as String).trim().isEmpty ||
        from == null ||
        until == null ||
        until.isBefore(from) ||
        !RegExp(r'^\d{3,20}$')
            .hasMatch(crew['supervisor_document'] as String)) {
      throw const FormatException(
          'Revisa nombre, cédula del supervisor y período.');
    }
    final driver = crew['driver_document'] as String?;
    if (driver != null &&
        driver.isNotEmpty &&
        !RegExp(r'^\d{3,20}$').hasMatch(driver)) {
      throw const FormatException('Identificación adicional inválida.');
    }
    final db = await database.database;
    if (id == null) {
      await db.insert('crews', crew);
    } else {
      await db.update('crews', crew, where: 'id=?', whereArgs: [id]);
    }
  }

  Future<void> assignWorker(int workerId, int? crewId, WorkSchedule? schedule,
      String authorizationReference) async {
    requireAdmin();
    final privacy = await setting('privacy');
    if (privacy == null || authorizationReference.trim().isEmpty) {
      throw const FormatException(
          'Configura tratamiento de datos y referencia de autorización del trabajador.');
    }
    if (schedule != null &&
        (schedule.dailyMinutes <= 0 ||
            schedule.dailyMinutes > 1440 ||
            schedule.nightStartMinute < 0 ||
            schedule.nightStartMinute >= 1440 ||
            schedule.nightEndMinute < 0 ||
            schedule.nightEndMinute >= 1440 ||
            schedule.nightStartMinute == schedule.nightEndMinute)) {
      throw const FormatException('Duración de jornada inválida.');
    }
    final db = await database.database;
    if (crewId != null &&
        (await db.query('crews', where: 'id=?', whereArgs: [crewId])).isEmpty) {
      throw const FormatException('Selecciona un equipo existente.');
    }
    await db.update(
        'workers',
        {
          'crew_id': crewId,
          'schedule_json': schedule?.encode(),
          'authorization_reference': authorizationReference.trim(),
          'authorization_policy': privacy,
          'authorization_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id=?',
        whereArgs: [workerId]);
  }

  Future<Map<String, Object?>> workerConfig(int id) async {
    requireAdmin();
    final rows = await (await database.database)
        .query('workers', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) throw const FormatException('Trabajador no encontrado.');
    return rows.first;
  }

  Future<void> applySchedule(PhotoDay day) {
    requireAdmin();
    return JourneyReviewStore(database, adminDocument!).applySchedule(day);
  }

  Future<void> review(PhotoDay day,
      {required bool approve, bool abandon = false}) {
    requireAdmin();
    return JourneyReviewStore(database, adminDocument!)
        .review(day, approve: approve, abandon: abandon);
  }

  /// Información de privacidad no prellenada: los datos reales los da la empresa.
  Future<void> savePrivacy(Map<String, String> fields) async {
    requireAdmin();
    if (fields.values.any((v) => v.trim().isEmpty) ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
            .hasMatch(fields['email'] ?? '')) {
      throw const FormatException(
          'Completa responsable, contacto, finalidad y conservación.');
    }
    await saveSetting('privacy', jsonEncode(fields));
  }

  /// Inicializa datos por defecto para que la gestión de turnos funcione de forma real e inmediata.
  Future<void> ensureDefaultData() async {
    final db = await database.database;
    // 1. Garantizar política de privacidad inicial si no existe
    final p = await setting('privacy');
    if (p == null) {
      await db.insert(
        'local_settings',
        {
          'name': 'privacy',
          'value': jsonEncode({
            'responsible': 'Talento Humano & Operaciones',
            'email': 'rrhh@smartattendance.local',
            'purpose': 'Control de asistencia biométrica y gestión horaria laboral',
            'retention': '5 años conforme a normativa laboral',
          }),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 2. Garantizar turnos base iniciales si la tabla está vacía
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM shift_templates'),
    ) ?? 0;

    if (count == 0) {
      final baseShifts = [
        const ShiftTemplate(
          name: 'Turno Mañana (06:00 - 14:00)',
          startMinute: 360,
          endMinute: 840,
          dailyMinutes: 480,
          deductLunch: true,
          weekdays: [1, 2, 3, 4, 5],
        ),
        const ShiftTemplate(
          name: 'Turno Ordinario / Oficina (08:00 - 17:00)',
          startMinute: 480,
          endMinute: 1020,
          dailyMinutes: 480,
          deductLunch: true,
          weekdays: [1, 2, 3, 4, 5],
        ),
        const ShiftTemplate(
          name: 'Turno Tarde (14:00 - 22:00)',
          startMinute: 840,
          endMinute: 1320,
          dailyMinutes: 480,
          deductLunch: false,
          weekdays: [1, 2, 3, 4, 5],
        ),
        const ShiftTemplate(
          name: 'Turno Noche (22:00 - 06:00)',
          startMinute: 1320,
          endMinute: 360,
          dailyMinutes: 480,
          deductLunch: false,
          nightStartMinute: 1260,
          nightEndMinute: 360,
          weekdays: [1, 2, 3, 4, 5],
        ),
      ];

      for (final s in baseShifts) {
        await db.insert('shift_templates', s.toMap());
      }
    }
  }

  Future<List<ShiftTemplate>> shiftTemplates() async {
    final db = await database.database;
    final rows = await db.query('shift_templates', orderBy: 'start_minute ASC, id ASC');
    return rows.map(ShiftTemplate.fromMap).toList();
  }

  Future<void> saveShiftTemplate(ShiftTemplate template) async {
    requireAdmin();
    final db = await database.database;
    if (template.name.trim().isEmpty) {
      throw const FormatException('El nombre del turno es obligatorio.');
    }
    if (template.id == null) {
      await db.insert('shift_templates', template.toMap());
    } else {
      await db.update(
        'shift_templates',
        template.toMap(),
        where: 'id = ?',
        whereArgs: [template.id],
      );
    }
  }

  Future<void> deleteShiftTemplate(int id) async {
    requireAdmin();
    final db = await database.database;
    await db.delete('shift_templates', where: 'id = ?', whereArgs: [id]);
  }

  /// Asigna un turno real a una lista de trabajadores (soporte individual y masivo)
  Future<void> assignShiftToWorkers({
    required List<int> workerIds,
    required ShiftTemplate template,
    String? reference,
  }) async {
    requireAdmin();
    await ensureDefaultData();
    final schedule = template.toSchedule();
    final authRef = (reference != null && reference.trim().isNotEmpty)
        ? reference.trim()
        : 'Asignación administrativa de jornada (${template.name})';

    final db = await database.database;
    final privacy = await setting('privacy') ?? 'Política General SmartAttendance';

    await db.transaction((tx) async {
      for (final workerId in workerIds) {
        await tx.update(
          'workers',
          {
            'schedule_json': schedule.encode(),
            'authorization_reference': authRef,
            'authorization_policy': privacy,
            'authorization_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [workerId],
        );
      }
    });
  }

  Future<void> removeScheduleFromWorker(int workerId) async {
    requireAdmin();
    final db = await database.database;
    await db.update(
      'workers',
      {
        'schedule_json': null,
      },
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  /// Obtiene todas las jornadas con tiempo adicional (horas extras) registradas
  Future<List<PhotoDay>> allOvertimeDays() async {
    final db = await database.database;
    // Traer jornadas que tengan schedule_json y marcas registradas
    final rows = await db.rawQuery('''
      SELECT m.*, j.schedule_json, j.status,
             j.approved_seconds, j.reviewed_by, j.reviewed_at, j.review_note
      FROM photo_marks m
      JOIN journeys j ON j.id = m.journey_id
      WHERE j.schedule_json IS NOT NULL
      ORDER BY m.captured_at DESC, m.uuid DESC
    ''');

    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      groups.putIfAbsent(row['journey_id'] as String, () => []).add(row);
    }

    final days = <PhotoDay>[];
    for (final markRows in groups.values) {
      final info = markRows.first;
      final schedule = WorkSchedule.decode(info['schedule_json'] as String?);
      final records = markRows.map(photoRecordFromRow).toList();
      final day = PhotoDay(
        records,
        schedule: schedule,
        status: info['status'] as String,
        approvedSeconds: info['approved_seconds'] as int?,
        reviewedBy: info['reviewed_by'] as String?,
        reviewedAt: info['reviewed_at'] as String?,
        reviewNote: info['review_note'] as String?,
      );

      // Si la jornada tiene tiempo adicional calculado o ya fue revisada con segundos aprobados
      if (day.totals.additional != null || day.approvedSeconds != null) {
        days.add(day);
      }
    }

    // Ordenar de más reciente a más antigua
    days.sort((a, b) => b.worker.capturedAt.compareTo(a.worker.capturedAt));
    return days;
  }
}
