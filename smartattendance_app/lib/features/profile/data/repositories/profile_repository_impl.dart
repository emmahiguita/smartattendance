// lib/features/profile/data/repositories/profile_repository_impl.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._localDb, {Dio? dio})
      : _dio = dio;

  final ProfileRemoteDataSource _remote;
  final LocalDatabaseService _localDb;
  final Dio? _dio;

  @override
  Future<UserEntity> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
    int? userId,
  }) async {
    try {
      final model = await _remote.updateProfile(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        fechaNacimiento: fechaNacimiento,
        telefono: telefono,
        direccion: direccion,
      );
      return model.toEntity();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) rethrow;
      AppLogger.info('Offline mode: saving profile locally');
      if (userId == null) {
        throw Exception('userId required for offline profile update');
      }
      return updateProfileOffline(
        userId,
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        fechaNacimiento: fechaNacimiento,
        telefono: telefono,
        direccion: direccion,
      );
    }
  }

  /// Actualiza el perfil en modo offline. Guarda en SQLite local y encola
  /// los cambios para sincronizar cuando haya conexión.
  Future<UserEntity> updateProfileOffline(
    int userId, {
    String? nombre,
    String? apellido,
    String? correo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  }) async {
    // Leer datos actuales del usuario local
    final userRow = await _getLocalUserRow(userId);

    await _localDb.updateLocalUser(
      userId,
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      direccion: direccion,
      fechaNacimiento: fechaNacimiento,
    );

    // Encolar cambios para sync cuando haya conexión (solo campos no nulos)
    final pending = <String, dynamic>{};
    if (nombre != null) pending['nombre'] = nombre;
    if (apellido != null) pending['apellido'] = apellido;
    if (correo != null) pending['correo'] = correo;
    if (fechaNacimiento != null) pending['fecha_nacimiento'] = fechaNacimiento;
    if (telefono != null) pending['telefono'] = telefono;
    if (direccion != null) pending['direccion'] = direccion;
    if (pending.isNotEmpty) {
      final json = pending.toString(); // usa toString simple — synced as dict on backend
      await _localDb.insertOfflineProfileChange(userId, json);
    }

    // Reconstruir entidad con datos fusionados (previos + nuevos)
    return _rowToEntity({
      ...?userRow,
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (correo != null) 'correo': correo,
      if (telefono != null) 'telefono': telefono,
      if (direccion != null) 'direccion': direccion,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
    });
  }

  @override
  Future<UserEntity> uploadPhoto(String filePath) async {
    try {
      final model = await _remote.uploadPhoto(filePath);
      return model.toEntity();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) rethrow;
      AppLogger.info('Offline mode: delegating photo upload to ViewModel');
      rethrow; // ViewModel maneja el offline vía uploadPhotoOffline
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown &&
            e.error != null &&
            e.error.toString().contains('SocketException'));
  }

  /// Guarda la foto local y la asocia al usuario en SQLite.
  /// [userId] lo pasa el ViewModel.
  Future<UserEntity> uploadPhotoOffline(String filePath, int userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_photo_$userId${p.extension(filePath)}';
    final destPath = p.join(dir.path, fileName);

    // Sobrescribir foto anterior del mismo usuario
    if (await File(destPath).exists()) {
      await File(destPath).delete();
    }
    await File(filePath).copy(destPath);

    await _localDb.updateLocalUser(userId, fotoUrl: destPath);

    final userRow = await _getLocalUserRow(userId);
    return _rowToEntity({
      ...?userRow,
      'foto_url': destPath,
    });
  }

  /// Carga el usuario local por ID. Busca en usuarios_locales y
  /// fallback a empleados_cache.
  Future<Map<String, dynamic>?> _getLocalUserRow(int userId) async {
    final db = await _localDb.database;
    var results = await db.query(
      'usuarios_locales',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isEmpty) {
      results = await db.query(
        'empleados_cache',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
    }
    return results.isNotEmpty ? results.first : null;
  }

  /// Sincroniza cambios de perfil pendientes con el backend.
  /// Retorna la cantidad de cambios procesados exitosamente.
  Future<int> syncPendingProfiles() async {
    if (_dio == null) return 0;
    final pending = await _localDb.getPendingOfflineProfiles();
    if (pending.isEmpty) return 0;

    AppLogger.info(
        'Sincronizando ${pending.length} cambios de perfil offline...');

    final payload = pending.map((row) {
      Map<String, dynamic> changesMap;
      try {
        // El JSON se guardó como Map.toString() — intentar parsearlo
        final raw = row['changes'] as String;
        changesMap = Map<String, dynamic>.from(
            const JsonDecoder().convert(raw));
      } catch (_) {
        changesMap = {};
      }
      return {
        'client_id': row['id'],
        'changes': changesMap,
      };
    }).toList();

    try {
      final response = await _dio.post(
        '/users/me/sync',
        data: {'changes': payload},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final detalles = data['detalles'] as List<dynamic>? ?? [];
        final exitosos = <int>[];
        for (final d in detalles) {
          final detail = d as Map<String, dynamic>;
          final status = detail['status'] as String? ?? '';
          final clientId = detail['client_id'] as int?;
          if (clientId != null &&
              (status == 'creado' || status == 'duplicado_ignorado')) {
            exitosos.add(clientId);
          }
        }
        if (exitosos.isNotEmpty) {
          await _localDb.markProfilesAsSynced(exitosos);
        }
        return exitosos.length;
      }
    } catch (e) {
      AppLogger.warning('Fallo durante sync de perfil offline: $e');
    }
    return 0;
  }

  UserEntity _rowToEntity(Map<String, dynamic> row) {
    if (row.isEmpty) {
      throw Exception('Usuario local no encontrado. Inicia sesión online primero.');
    }
    return UserEntity(
      id: row['id'] as int,
      nombre: row['nombre'] as String,
      apellido: (row['apellido'] as String?) ?? '',
      cedula: (row['cedula'] as String?) ?? '',
      correo: (row['correo'] as String?) ?? '',
      cargo: (row['cargo'] as String?) ?? 'Empleado',
      fechaNacimiento: row['fecha_nacimiento'] as String?,
      telefono: row['telefono'] as String?,
      direccion: row['direccion'] as String?,
      fotoUrl: row['foto_url'] as String?,
    );
  }

}
