// lib/core/localstore/local_database_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../logging/app_logger.dart';

class LocalDatabaseService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smartattendance_offline.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_attendances (
            uuid_marca TEXT PRIMARY KEY,
            usuario_id INTEGER NOT NULL,
            fecha_hora_local TEXT NOT NULL,
            tipo TEXT,
            latitud REAL,
            longitud REAL,
            direccion TEXT,
            sincronizado INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE usuarios_locales (
            id INTEGER PRIMARY KEY,
            cedula TEXT NOT NULL UNIQUE,
            nombre TEXT NOT NULL,
            apellido TEXT NOT NULL,
            correo TEXT,
            cargo TEXT,
            foto_url TEXT,
            telefono TEXT,
            is_admin INTEGER NOT NULL DEFAULT 0,
            password_hash TEXT
          )
        ''');
        await _seedLocalUsers(db);
        AppLogger.info('SQLite tables created and seeded');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS usuarios_locales (
              id INTEGER PRIMARY KEY,
              cedula TEXT NOT NULL UNIQUE,
              nombre TEXT NOT NULL,
              apellido TEXT NOT NULL,
              correo TEXT,
              cargo TEXT,
              foto_url TEXT,
              telefono TEXT,
              is_admin INTEGER NOT NULL DEFAULT 0,
              password_hash TEXT
            )
          ''');
          await _seedLocalUsers(db);
        }
      },
    );
  }

  /// Seed de usuarios locales — permite login offline sin backend.
  Future<void> _seedLocalUsers(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM usuarios_locales'),
    ) ?? 0;
    if (count > 0) return; // Ya hay datos.

    final users = [
      {
        'id': 1, 'cedula': '1007331963', 'nombre': 'Emmanuel',
        'apellido': 'Higuita', 'correo': 'emmanuel@empresa.co',
        'cargo': 'Administrador', 'is_admin': 1, 'password_hash': null,
      },
      {
        'id': 2, 'cedula': '1234567890', 'nombre': 'Juan',
        'apellido': 'Pérez', 'correo': 'juan@empresa.co',
        'cargo': 'Desarrollador', 'is_admin': 0, 'password_hash': null,
      },
      {
        'id': 3, 'cedula': '0987654321', 'nombre': 'María',
        'apellido': 'García', 'correo': 'maria@empresa.co',
        'cargo': 'Diseñadora', 'is_admin': 0, 'password_hash': null,
      },
      {
        'id': 4, 'cedula': '1122334455', 'nombre': 'Carlos',
        'apellido': 'López', 'correo': 'carlos@empresa.co',
        'cargo': 'Analista', 'is_admin': 0, 'password_hash': null,
      },
      {
        'id': 5, 'cedula': '5544332211', 'nombre': 'Sofía',
        'apellido': 'Martínez', 'correo': 'sofia@empresa.co',
        'cargo': 'QA', 'is_admin': 0, 'password_hash': null,
      },
    ];

    for (final u in users) {
      await db.insert('usuarios_locales', u,
        conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    AppLogger.info('Seeded ${users.length} local users');
  }

  /// Busca usuario local por cédula. Retorna null si no existe.
  Future<Map<String, dynamic>?> getLocalUserByCedula(String cedula) async {
    final db = await database;
    final results = await db.query(
      'usuarios_locales',
      where: 'cedula = ?',
      whereArgs: [cedula],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Retorna todos los usuarios locales.
  Future<List<Map<String, dynamic>>> getAllLocalUsers() async {
    final db = await database;
    return db.query('usuarios_locales', orderBy: 'nombre ASC');
  }

  // ── Offline Attendances ──────────────────────────────────────────

  Future<void> insertOfflineAttendance(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(
      'offline_attendances',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info('Inserted offline attendance: ${row['uuid_marca']}');
  }

  Future<List<Map<String, dynamic>>> getPendingOfflineAttendances() async {
    final db = await database;
    return await db.query(
      'offline_attendances',
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'fecha_hora_local ASC',
    );
  }

  Future<int> countPendingOfflineAttendances() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_attendances WHERE sincronizado = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markAsSynced(List<String> uuids) async {
    if (uuids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final uuid in uuids) {
      batch.update(
        'offline_attendances',
        {'sincronizado': 1},
        where: 'uuid_marca = ?',
        whereArgs: [uuid],
      );
    }
    await batch.commit(noResult: true);
    AppLogger.info('Marked ${uuids.length} attendances as synced');
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});
