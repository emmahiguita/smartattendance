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
      version: 7,
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
        if (oldVersion < 5) {
          await _migrateV5(db);
        }
        if (oldVersion < 6) {
          await _migrateV6(db);
        }
        if (oldVersion < 7) {
          await _migrateV7(db);
        }
      },
      onOpen: (db) async {
        await _createV3Tables(db);
      },
    );
  }

  /// v5: añade columnas de perfil (fecha_nacimiento, direccion)
  /// a usuarios_locales si no existen.
  Future<void> _migrateV5(Database db) async {
    try {
      await db.execute(
          'ALTER TABLE usuarios_locales ADD COLUMN fecha_nacimiento TEXT');
    } catch (_) { /* ya existe */ }
    try {
      await db.execute(
          'ALTER TABLE usuarios_locales ADD COLUMN direccion TEXT');
    } catch (_) { /* ya existe */ }
  }

  /// v6: añade recipient_cedula a offline_messages para resolver IDs.
  Future<void> _migrateV6(Database db) async {
    try {
      await db.execute(
          'ALTER TABLE offline_messages ADD COLUMN recipient_cedula TEXT');
    } catch (_) { /* ya existe */ }
  }

  /// v7: tabla de sync de cambios de perfil offline.
  Future<void> _migrateV7(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        changes TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
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
        fecha_nacimiento TEXT,
        direccion TEXT,
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

    // v7: cola de sync para cambios de perfil offline
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        changes TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Mensajes offline (para envío cuando no hay red)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient_id INTEGER NOT NULL,
        recipient_cedula TEXT,
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

  /// Obtiene el próximo ID secuencial para insertar un usuario local.
  Future<int> nextLocalUserId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM usuarios_locales');
    return (Sqflite.firstIntValue(result) ?? 0) + 1;
  }

  /// Actualiza los campos editables del perfil de un usuario local.
  /// Solo modifica los campos no nulos pasados — los demás quedan intactos.
  Future<void> updateLocalUser(int userId, {
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
    String? direccion,
    String? fechaNacimiento,
    String? fotoUrl,
  }) async {
    final db = await database;
    final values = <String, dynamic>{};
    if (nombre != null) values['nombre'] = nombre;
    if (apellido != null) values['apellido'] = apellido;
    if (correo != null) values['correo'] = correo;
    if (telefono != null) values['telefono'] = telefono;
    if (direccion != null) values['direccion'] = direccion;
    if (fechaNacimiento != null) values['fecha_nacimiento'] = fechaNacimiento;
    if (fotoUrl != null) values['foto_url'] = fotoUrl;
    if (values.isEmpty) return;

    await db.update(
      'usuarios_locales',
      values,
      where: 'id = ?',
      whereArgs: [userId],
    );
    AppLogger.info('Updated local user $userId: ${values.keys.join(', ')}');
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

  Future<List<Map<String, dynamic>>> getPendingOfflineUsers() async {
    final db = await database;
    return db.query(
      'empleados_cache',
      where: 'id < 0',
      orderBy: 'updated_at ASC',
    );
  }

  Future<void> updateUserIdCascade(int oldTempId, int newRealId) async {
    final db = await database;
    final batch = db.batch();

    // 1. Actualizar en empleados_cache
    batch.update(
      'empleados_cache',
      {'id': newRealId},
      where: 'id = ?',
      whereArgs: [oldTempId],
    );

    // 2. Actualizar en offline_attendances (si marcó estando offline)
    batch.update(
      'offline_attendances',
      {'usuario_id': newRealId},
      where: 'usuario_id = ?',
      whereArgs: [oldTempId],
    );

    // 3. Actualizar en offline_profiles (si intentó editar perfil estando offline)
    batch.update(
      'offline_profiles',
      {'user_id': newRealId},
      where: 'user_id = ?',
      whereArgs: [oldTempId],
    );

    // 4. Actualizar en local_qr_codes (si generó QR offline)
    batch.update(
      'local_qr_codes',
      {'usuario_id': newRealId},
      where: 'usuario_id = ?',
      whereArgs: [oldTempId],
    );

    // 5. Actualizar en attendance_history
    batch.update(
      'attendance_history',
      {'usuario_id': newRealId},
      where: 'usuario_id = ?',
      whereArgs: [oldTempId],
    );

    await batch.commit(noResult: true);
    AppLogger.info('Cascaded user ID update from $oldTempId to $newRealId');
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

  Future<List<Map<String, dynamic>>> getAttendanceHistoryByDate(String dateStr) async {
    final db = await database;
    return await db.query(
      'attendance_history',
      where: 'fecha LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'hora ASC',
    );
  }

  // ┈┈ Local QR Codes ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  Future<void> cacheQRs(List<Map<String, dynamic>> qrs) async {
    final db = await database;
    final batch = db.batch();
    // Limpiamos los QRs cacheados anteriores que no hayan sido usados,
    // o simplemente borramos todos para mantener la lista fresca
    batch.delete('local_qr_codes');
    final now = DateTime.now().toIso8601String();
    for (final qr in qrs) {
      batch.insert('local_qr_codes', {
        'usuario_id': qr['usuario_id'],
        'codigo': qr['codigo'],
        'usado': 0,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
    AppLogger.info('Cached ${qrs.length} active QR codes locally');
  }

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

  Future<void> insertOfflineMessage(int recipientId, String body, {String? recipientCedula}) async {
    final db = await database;
    await db.insert('offline_messages', {
      'recipient_id': recipientId,
      'recipient_cedula': recipientCedula,
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

  // ── offline_profiles ────────────────────────────────────────────────

  /// Guarda un cambio de perfil pendiente de sincronizar.
  /// [changes] es un JSON string con los campos modificados.
  Future<void> insertOfflineProfileChange(int userId, String changes) async {
    final db = await database;
    await db.insert('offline_profiles', {
      'user_id': userId,
      'changes': changes,
      'sincronizado': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retorna los cambios de perfil pendientes de sync (no sincronizados).
  Future<List<Map<String, dynamic>>> getPendingOfflineProfiles() async {
    final db = await database;
    return db.query('offline_profiles',
        where: 'sincronizado = 0', orderBy: 'created_at ASC');
  }

  /// Marca como sincronizados los cambios de perfil por ID.
  Future<void> markProfilesAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('offline_profiles', {'sincronizado': 1},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});
