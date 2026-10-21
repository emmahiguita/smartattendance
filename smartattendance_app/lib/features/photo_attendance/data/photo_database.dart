import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'journey_migration.dart';

/// Base exclusiva del modo local. No carga usuarios de demostración ni llama
/// al backend. La inicialización compartida impide abrirla varias veces a la vez.
class PhotoDatabase {
  Future<Database>? _opening;
  Future<Database> get database =>
      _opening ??= _open().catchError((Object error) {
        _opening =
            null; // Un fallo de disco no envenena todos los intentos siguientes.
        throw error;
      });

  Future<Database> _open() async {
    return openDatabase(
        p.join(await getDatabasesPath(), 'local_photo_attendance.db'),
        version: 6,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await db.execute('''CREATE TABLE workers (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          document TEXT NOT NULL UNIQUE, job TEXT NOT NULL
        )''');
          await _createMarks(db, 'photo_marks');
          await _addLocation(db);
          await _indexes(db);
          await JourneyMigration.apply(db);
          await _createShiftTemplates(db);
        },
        onUpgrade: (db, old, _) async {
          if (old < 2) {
            // sqflite ejecuta la migración en una transacción: copiar antes de
            // sustituir permite conservar fotos y marcas de la versión anterior.
            await _createMarks(db, 'photo_marks_v2');
            await db.execute(
                'INSERT INTO photo_marks_v2 SELECT * FROM photo_marks');
            await db.execute('DROP TABLE photo_marks');
            await db
                .execute('ALTER TABLE photo_marks_v2 RENAME TO photo_marks');
            await _indexes(db);
          }
          if (old < 3) await _addLocation(db);
          if (old < 4) await JourneyMigration.apply(db);
          if (old < 5) await JourneyMigration.allowUnzonedTeams(db);
          if (old < 6) await _createShiftTemplates(db);
        });
  }

  Future<void> _createShiftTemplates(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS shift_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      start_minute INTEGER NOT NULL,
      end_minute INTEGER NOT NULL,
      daily_minutes INTEGER NOT NULL,
      deduct_lunch INTEGER NOT NULL DEFAULT 1,
      night_start_minute INTEGER NOT NULL DEFAULT 1140,
      night_end_minute INTEGER NOT NULL DEFAULT 360,
      weekdays TEXT NOT NULL DEFAULT '[1,2,3,4,5]'
    )''');
  }

  /// Migración aditiva: conserva horas y fotos anteriores. NULL significa
  /// «sin dato histórico»; nunca se rellena con la ubicación actual del usuario.
  Future<void> _addLocation(Database db) async {
    await db.execute('ALTER TABLE photo_marks ADD COLUMN latitude REAL');
    await db.execute('ALTER TABLE photo_marks ADD COLUMN longitude REAL');
    await db.execute('ALTER TABLE photo_marks ADD COLUMN accuracy_m REAL');
    await db.execute('ALTER TABLE photo_marks ADD COLUMN location_at TEXT');
  }

  Future<void> _createMarks(Database db, String name) =>
      db.execute('''CREATE TABLE $name (
          uuid TEXT PRIMARY KEY, worker_id INTEGER NOT NULL REFERENCES workers(id),
          name TEXT NOT NULL, document TEXT NOT NULL, job TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('entrada','salida_almuerzo','regreso_almuerzo','salida')),
          captured_at TEXT NOT NULL, local_path TEXT NOT NULL
        )''');

  Future<void> _indexes(Database db) async {
    await db.execute(
        'CREATE INDEX mark_date ON photo_marks(captured_at DESC, uuid)');
    await db.execute(
        'CREATE INDEX mark_worker ON photo_marks(worker_id, captured_at DESC)');
  }
}
