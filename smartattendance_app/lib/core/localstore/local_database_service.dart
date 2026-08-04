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
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
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
        if (oldVersion < 4) {
          await _createV3Tables(db);
          await _seedLocalUsers(db);
        }
      },
      onOpen: (db) async {
        await _createV3Tables(db);
      },
    );
  }

  /// Crea todas las tablas (v1+v3) en una sola llamada.
  Future<void> _createTables(Database db) async {
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
    await _createV3Tables(db);
  }

  /// Tablas añadidas en v3: empleados cacheados, historial de asistencia
  /// local, y QR generados offline.
  Future<void> _createV3Tables(Database db) async {
    // Empleados cacheados del backend (se actualizan cuando hay conexión)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS empleados_cache (
        id INTEGER PRIMARY KEY,
        cedula TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        correo TEXT,
        cargo TEXT,
        foto_url TEXT,
        telefono TEXT,
        is_admin INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Historial de asistencia guardado localmente
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_history (
        id INTEGER PRIMARY KEY,
        usuario_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        latitud REAL,
        longitud REAL,
        direccion TEXT,
        nombre TEXT,
        apellido TEXT,
        cedula TEXT,
        cargo TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // QR generados localmente
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_qr_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        codigo TEXT NOT NULL,
        usado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Mensajes offline (para envío cuando no hay red)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient_id INTEGER NOT NULL,
        body TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
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

  /// Busca en empleados cacheados por cédula.
  Future<Map<String, dynamic>?> getCachedEmpleadoByCedula(String cedula) async {
    final db = await database;
    final results = await db.query(
      'empleados_cache',
      where: 'cedula = ?',
      whereArgs: [cedula],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Inserta o reemplaza un usuario local en la DB.
  Future<void> insertLocalUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('usuarios_locales', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
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

  // ── Empleados Cache ────────────────────────────────────────────

  Future<void> cacheEmpleados(List<Map<String, dynamic>> empleados) async {
    final db = await database;
    final batch = db.batch();
    for (final e in empleados) {
      batch.insert('empleados_cache', {
        ...e,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    AppLogger.info('Cached ${empleados.length} employees locally');
  }

  Future<List<Map<String, dynamic>>> getCachedEmpleados() async {
    final db = await database;
    return db.query('empleados_cache', orderBy: 'nombre ASC');
  }

  Future<void> insertLocalEmpleado(Map<String, dynamic> empleado) async {
    final db = await database;
    await db.insert('empleados_cache', {
      ...empleado,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Attendance History (local) ─────────────────────────────────

  Future<void> insertAttendanceRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert('attendance_history', record,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(int userId) async {
    final db = await database;
    return await db.query(
      'attendance_history',
      where: 'usuario_id = ?',
      whereArgs: [userId],
      orderBy: 'fecha DESC, hora DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllAttendanceHistory() async {
    final db = await database;
    return await db.query('attendance_history', orderBy: 'fecha DESC, hora DESC');
  }

  // ── Local QR Codes ────────────────────────────────────────────

  Future<void> insertLocalQR(int userId, String codigo) async {
    final db = await database;
    await db.insert('local_qr_codes', {
      'usuario_id': userId,
      'codigo': codigo,
      'usado': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getValidQR(String codigo) async {
    final db = await database;
    final results = await db.query(
      'local_qr_codes',
      where: 'codigo = ? AND usado = 0',
      whereArgs: [codigo],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> markQRAsUsed(String codigo) async {
    final db = await database;
    await db.update(
      'local_qr_codes',
      {'usado': 1},
      where: 'codigo = ?',
      whereArgs: [codigo],
    );
  }

  // ── Offline Messages ──────────────────────────────────────────

  Future<void> insertOfflineMessage(int recipientId, String body) async {
    final db = await database;
    await db.insert('offline_messages', {
      'recipient_id': recipientId,
      'body': body,
      'sincronizado': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOfflineMessages() async {
    final db = await database;
    return await db.query(
      'offline_messages',
      where: 'sincronizado = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markMessagesAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'offline_messages',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});
