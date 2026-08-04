// lib/features/attendance/data/repositories/attendance_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../models/today_employee_status.dart';

final class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(
    this._dio,
    this._localDb, {
    LocationService location = const LocationService(),
  }) : _location = location;

  final Dio _dio;
  final LocalDatabaseService _localDb;
  final LocationService _location;

  @override
  Future<AttendanceEntity> register(int userId, {String? tipo}) async {
    final uuidMarca = const Uuid().v4();
    final now = DateTime.now();

    // Ubicación en tiempo real con timeout duro
    final location = await _location.capture();

    try {
      AppLogger.logApiCall('POST', '/attendance/', data: {
        'usuario_id': userId,
        'tipo': tipo,
        'uuid_marca': uuidMarca,
      });

      final response = await _dio.post(
        '/attendance/',
        data: {
          'usuario_id': userId,
          if (tipo != null) 'tipo': tipo,
          'uuid_marca': uuidMarca,
          if (location != null) 'latitud': location.lat,
          if (location != null) 'longitud': location.lng,
          if (location?.dir != null) 'direccion': location!.dir,
        },
      );

      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.warning(
          'Envío online directo fallido/sin red. Guardando registro en cola SQLite local: $e');

      final offlineRow = {
        'uuid_marca': uuidMarca,
        'usuario_id': userId,
        'fecha_hora_local': now.toIso8601String(),
        'tipo': tipo ?? 'entrada',
        'latitud': location?.lat,
        'longitud': location?.lng,
        'direccion': location?.dir,
        'sincronizado': 0,
        'created_at': now.toIso8601String(),
      };

      await _localDb.insertOfflineAttendance(offlineRow);

      return AttendanceModel(
        id: -1,
        usuarioId: userId,
        tipo: tipo ?? 'entrada',
        fecha: now,
        hora: now,
        latitud: location?.lat,
        longitud: location?.lng,
        direccion: location?.dir,
      );
    }
  }

  @override
  Future<int> syncPendingRecords() async {
    final pending = await _localDb.getPendingOfflineAttendances();
    if (pending.isEmpty) return 0;

    AppLogger.info(
        'Sincronizando ${pending.length} registros de asistencia offline con el backend...');

    final recordsPayload = pending.map((row) {
      return {
        'uuid_marca': row['uuid_marca'],
        'usuario_id': row['usuario_id'],
        'fecha_hora_local': row['fecha_hora_local'],
        'tipo': row['tipo'],
        'latitud': row['latitud'],
        'longitud': row['longitud'],
        'direccion': row['direccion'],
      };
    }).toList();

    try {
      final response = await _dio.post(
        '/attendance/sync',
        data: {'records': recordsPayload},
      );

      if (response.statusCode == 200) {
        final syncedUuids =
            pending.map((r) => r['uuid_marca'] as String).toList();
        await _localDb.markAsSynced(syncedUuids);
        AppLogger.info(
            'Sincronización offline exitosa: ${syncedUuids.length} marcas procesadas.');
        return syncedUuids.length;
      }
    } catch (e) {
      AppLogger.warning(
          'Fallo durante sincronización de registros offline: $e');
    }
    return 0;
  }

  @override
  Future<int> getPendingCount() async {
    return await _localDb.countPendingOfflineAttendances();
  }

  @override
  Future<List<AttendanceEntity>> getByUser(int userId) async {
    try {
      AppLogger.logApiCall('GET', '/attendance/user/$userId');

      final response = await _dio.get('/attendance/user/$userId');

      final attendances = (response.data as List)
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.logApiResponse(response.statusCode ?? 200,
          '/attendance/user/$userId', attendances.length);
      return attendances;
    } on DioException catch (e) {
      AppLogger.error('Failed to get user attendances', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<AttendanceEntity>> getAll() async {
    try {
      AppLogger.logApiCall('GET', '/attendance/');

      final response = await _dio.get('/attendance/');

      final attendances = (response.data as List)
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.logApiResponse(
          response.statusCode ?? 200, '/attendance/', attendances.length);
      return attendances;
    } on DioException catch (e) {
      AppLogger.error('Failed to get all attendances', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<AttendanceEntity>> getAllWithUsers() async {
    try {
      AppLogger.logApiCall('GET', '/attendance/with-users');

      final response = await _dio.get('/attendance/with-users');

      final attendances = (response.data as List)
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.logApiResponse(response.statusCode ?? 200,
          '/attendance/with-users', attendances.length);
      return attendances;
    } on DioException catch (e) {
      AppLogger.error('Failed to get attendances with users', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<TodayEmployeeStatus>> getTodayStatus() async {
    try {
      AppLogger.logApiCall('GET', '/attendance/today-status');
      final response = await _dio.get('/attendance/today-status');
      final list = (response.data as List)
          .map((e) => TodayEmployeeStatus.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.logApiResponse(
          response.statusCode ?? 200, '/attendance/today-status', list.length);
      return list;
    } on DioException catch (e) {
      AppLogger.error('Failed to get today status', error: e);
      throw ErrorHandler.handle(e);
    }
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(localDatabaseServiceProvider),
  );
});
