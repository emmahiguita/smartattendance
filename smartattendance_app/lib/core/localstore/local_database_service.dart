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
      version: 1,
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
        AppLogger.info('SQLite offline_attendances table created successfully');
      },
    );
  }

  Future<void> insertOfflineAttendance(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(
      'offline_attendances',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info(
        'Inserted offline attendance with uuid: ${row['uuid_marca']}');
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
    AppLogger.info('Marked ${uuids.length} attendances as synced in SQLite');
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});
