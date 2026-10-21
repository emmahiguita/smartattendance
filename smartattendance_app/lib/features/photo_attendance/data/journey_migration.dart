import 'package:sqflite/sqflite.dart';
import '../domain/work_schedule.dart';

/// Añade jornadas sin borrar fotos. Las marcas antiguas se recorren por empleado
/// y hora; una entrada conserva su identidad al pasar de un día al siguiente.
abstract final class JourneyMigration {
  static Future<void> apply(Database db) async {
    await db.execute('''CREATE TABLE journeys (
      id TEXT PRIMARY KEY, worker_id INTEGER NOT NULL REFERENCES workers(id),
      work_date TEXT NOT NULL, schedule_json TEXT, status TEXT NOT NULL,
      reviewed_by TEXT, reviewed_at TEXT, approved_seconds INTEGER, review_note TEXT,
      operator_document TEXT, crew_name TEXT, zone_name TEXT
    )''');
    await db.execute('ALTER TABLE photo_marks ADD COLUMN journey_id TEXT');
    await db
        .execute('ALTER TABLE photo_marks ADD COLUMN operator_document TEXT');
    await db.execute('ALTER TABLE workers ADD COLUMN schedule_json TEXT');
    await db.execute('ALTER TABLE workers ADD COLUMN crew_id INTEGER');
    await db
        .execute('ALTER TABLE workers ADD COLUMN authorization_reference TEXT');
    await db
        .execute('ALTER TABLE workers ADD COLUMN authorization_policy TEXT');
    await db.execute('ALTER TABLE workers ADD COLUMN authorization_at TEXT');
    await db.execute('''CREATE TABLE work_zones (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      latitude REAL NOT NULL, longitude REAL NOT NULL, radius_m REAL NOT NULL
    )''');
    await db.execute('''CREATE TABLE crews (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      supervisor_document TEXT NOT NULL, driver_document TEXT,
      zone_id INTEGER REFERENCES work_zones(id),
      valid_from TEXT NOT NULL, valid_until TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE local_settings (
      name TEXT PRIMARY KEY, value TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE review_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      journey_id TEXT NOT NULL REFERENCES journeys(id),
      action TEXT NOT NULL, admin_document TEXT NOT NULL, reviewed_at TEXT NOT NULL
    )''');
    await db.execute(
        'CREATE INDEX mark_journey ON photo_marks(journey_id, captured_at)');
    final rows =
        await db.query('photo_marks', orderBy: 'worker_id, captured_at, uuid');
    final open = <int, String>{};
    for (final row in rows) {
      final worker = row['worker_id'] as int;
      final type = row['type'] as String;
      final id = type == 'entrada'
          ? row['uuid'] as String
          : open[worker] ?? row['uuid'] as String;
      // Un registro huérfano queda visible como incompleto; no se le inventa entrada.
      await db.insert(
          'journeys',
          {
            'id': id,
            'worker_id': worker,
            'work_date':
                ColombiaClock.day(DateTime.parse(row['captured_at'] as String)),
            'status': 'open',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.update('photo_marks', {'journey_id': id},
          where: 'uuid = ?', whereArgs: [row['uuid']]);
      open[worker] = id;
      if (type == 'salida') {
        await db.update('journeys', {'status': 'closed'},
            where: 'id = ?', whereArgs: [id]);
        open.remove(worker);
      }
    }
  }

  /// Hace opcional la geocerca sin perder equipos ya configurados.
  static Future<void> allowUnzonedTeams(Database db) async {
    await db.execute('ALTER TABLE crews RENAME TO crews_before_optional_zone');
    await db.execute('''CREATE TABLE crews (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      supervisor_document TEXT NOT NULL, driver_document TEXT,
      zone_id INTEGER REFERENCES work_zones(id),
      valid_from TEXT NOT NULL, valid_until TEXT NOT NULL
    )''');
    await db.execute('''INSERT INTO crews
      (id,name,supervisor_document,driver_document,zone_id,valid_from,valid_until)
      SELECT id,name,supervisor_document,driver_document,zone_id,valid_from,valid_until
      FROM crews_before_optional_zone''');
    await db.execute('DROP TABLE crews_before_optional_zone');
  }
}
