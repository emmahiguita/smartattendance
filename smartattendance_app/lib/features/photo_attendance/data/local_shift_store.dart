// ============================================================================
// ARCHIVO: local_shift_store.dart
// QUÉ HACE: Gestiona la persistencia SQLite de plantillas de turnos
//           (`shift_templates`), asignación de horarios (`WorkSchedule`) a
//           colaboradores y cálculo/auditoría de jornadas con horas extras.
// CÓMO FUNCIONA: Opera con transacciones SQLite atómicas sobre `shift_templates`,
//                `workers` y `journeys`, garantizando que las horas extras
//                sean reglas administrativas y nunca marcaciones manuales.
// POR QUÉ: Desacopla la lógica de turnos y horas extras de `LocalAdminStore`
//          para cumplir SRP y mantener cada archivo por debajo de 200 líneas.
// ============================================================================

import 'package:sqflite/sqflite.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import 'photo_database.dart';
import 'photo_row_mapper.dart';

class LocalShiftStore {
  final PhotoDatabase database;
  final void Function() requireAdmin;
  final Future<void> Function() ensureDefaultData;
  final Future<String?> Function(String name) getSetting;

  const LocalShiftStore({
    required this.database,
    required this.requireAdmin,
    required this.ensureDefaultData,
    required this.getSetting,
  });

  /// Inserta los 4 turnos corporativos iniciales cuando la tabla está vacía.
  static Future<void> seedDefaultShifts(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM shift_templates'),
        ) ??
        0;
    if (count > 0) return;

    const baseShifts = [
      ShiftTemplate(
        name: 'Turno Mañana (06:00 - 14:00)',
        startMinute: 360,
        endMinute: 840,
        dailyMinutes: 480,
        deductLunch: true,
        weekdays: [1, 2, 3, 4, 5],
      ),
      ShiftTemplate(
        name: 'Turno Ordinario / Oficina (08:00 - 17:00)',
        startMinute: 480,
        endMinute: 1020,
        dailyMinutes: 480,
        deductLunch: true,
        weekdays: [1, 2, 3, 4, 5],
      ),
      ShiftTemplate(
        name: 'Turno Tarde (14:00 - 22:00)',
        startMinute: 840,
        endMinute: 1320,
        dailyMinutes: 480,
        deductLunch: false,
        weekdays: [1, 2, 3, 4, 5],
      ),
      ShiftTemplate(
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

  Future<List<ShiftTemplate>> shiftTemplates() async {
    final db = await database.database;
    final rows =
        await db.query('shift_templates', orderBy: 'start_minute ASC, id ASC');
    return rows.map(ShiftTemplate.fromMap).toList();
  }

  Future<void> saveShiftTemplate(ShiftTemplate template) async {
    requireAdmin();
    if (template.name.trim().isEmpty) {
      throw const FormatException('El nombre del turno es obligatorio.');
    }
    final db = await database.database;
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
    final privacy =
        await getSetting('privacy') ?? 'Política General SmartAttendance';

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
      {'schedule_json': null},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<List<PhotoDay>> allOvertimeDays() async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT m.*,
             COALESCE(j.schedule_json, w.schedule_json) AS schedule_json,
             j.status,
             j.approved_seconds, j.reviewed_by, j.reviewed_at, j.review_note
      FROM photo_marks m
      JOIN journeys j ON j.id = m.journey_id
      LEFT JOIN workers w ON w.id = m.worker_id
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
      days.add(PhotoDay(
        records,
        schedule: schedule,
        status: info['status'] as String,
        approvedSeconds: info['approved_seconds'] as int?,
        reviewedBy: info['reviewed_by'] as String?,
        reviewedAt: info['reviewed_at'] as String?,
        reviewNote: info['review_note'] as String?,
      ));
    }
    days.sort((a, b) => b.worker.capturedAt.compareTo(a.worker.capturedAt));
    return days;
  }
}
