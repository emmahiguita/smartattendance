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

      // Also save to attendance_history for local display
      await _localDb.insertAttendanceRecord({
        'id': -1 * DateTime.now().millisecondsSinceEpoch,
        'usuario_id': userId,
        'tipo': tipo ?? 'entrada',
        'fecha': now.toIso8601String(),
        'hora':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        'latitud': location?.lat,
        'longitud': location?.lng,
        'direccion': location?.dir,
        'nombre': null,
        'apellido': null,
        'cedula': null,
        'cargo': null,
        'created_at': now.toIso8601String(),
      });

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

      // Cache locally for offline access
      for (final a in attendances) {
        await _localDb.insertAttendanceRecord({
          'id': a.id,
          'usuario_id': a.usuarioId,
          'tipo': a.tipo,
          'fecha': a.fecha.toIso8601String(),
          'hora':
              '${a.hora.hour.toString().padLeft(2, '0')}:${a.hora.minute.toString().padLeft(2, '0')}:${a.hora.second.toString().padLeft(2, '0')}',
          'latitud': a.latitud,
          'longitud': a.longitud,
          'direccion': a.direccion,
          'nombre': a.nombreEmpleado,
          'apellido': a.apellidoEmpleado,
          'cedula': a.cedulaEmpleado,
          'cargo': a.cargoEmpleado,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      AppLogger.logApiResponse(response.statusCode ?? 200,
          '/attendance/user/$userId', attendances.length);
      return attendances;
    } on DioException catch (_) {
      // Offline: use local cache
      AppLogger.info('Offline mode: loading attendance from local cache');
      return _localDb.getAttendanceHistory(userId).then((rows) => rows
          .map((r) => AttendanceModel(
                id: r['id'] as int,
                usuarioId: r['usuario_id'] as int,
                tipo: r['tipo'] as String,
                fecha: DateTime.parse(r['fecha'] as String),
                hora: _parseHora(r['hora'] as String),
                latitud: (r['latitud'] as num?)?.toDouble(),
                longitud: (r['longitud'] as num?)?.toDouble(),
                direccion: r['direccion'] as String?,
                nombreEmpleado: r['nombre'] as String?,
                apellidoEmpleado: r['apellido'] as String?,
                cedulaEmpleado: r['cedula'] as String?,
                cargoEmpleado: r['cargo'] as String?,
              ))
          .toList());
    }
  }

  DateTime _parseHora(String h) {
    final parts = h.split(':');
    return DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0);
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
    } on DioException catch (_) {
      AppLogger.info('Offline mode: loading all attendance from local cache');
      return _localDb.getAllAttendanceHistory().then((rows) => rows
          .map((r) => AttendanceModel(
                id: r['id'] as int,
                usuarioId: r['usuario_id'] as int,
                tipo: r['tipo'] as String,
                fecha: DateTime.parse(r['fecha'] as String),
                hora: _parseHora(r['hora'] as String),
                latitud: (r['latitud'] as num?)?.toDouble(),
                longitud: (r['longitud'] as num?)?.toDouble(),
                direccion: r['direccion'] as String?,
                nombreEmpleado: r['nombre'] as String?,
                apellidoEmpleado: r['apellido'] as String?,
                cedulaEmpleado: r['cedula'] as String?,
                cargoEmpleado: r['cargo'] as String?,
              ))
          .toList());
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
    } on DioException catch (_) {
      AppLogger.info(
          'Offline mode: loading attendances with users from local cache');
      return getAll(); // same local cache
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
    } on DioException catch (_) {
      AppLogger.info('Offline mode: building today status from local data');
      return _buildLocalTodayStatus();
    }
  }

  /// Construye el estado de hoy desde el cache local.
  Future<List<TodayEmployeeStatus>> _buildLocalTodayStatus() async {
    var empleados = await _localDb.getCachedEmpleados();
    if (empleados.isEmpty) {
      empleados = await _localDb.getAllLocalUsers();
    }
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final allHistory = await _localDb.getAllAttendanceHistory();
    final todayRecords = allHistory
        .where((r) => (r['fecha'] as String).startsWith(todayStr))
        .toList();

    final Map<int, List<Map<String, dynamic>>> byUser = {};
    for (final r in todayRecords) {
      final uid = r['usuario_id'] as int;
      byUser.putIfAbsent(uid, () => []).add(r);
    }

    final statuses = <TodayEmployeeStatus>[];
    for (final emp in empleados) {
      final uid = emp['id'] as int;
      final records = byUser[uid] ?? [];
      String estado = 'sin_marcar';
      String? horaEntrada;
      int minutosTarde = 0;

      if (records.isNotEmpty) {
        // Find entrance
        final entrance = records.firstWhere(
          (r) => r['tipo'] == 'entrada',
          orElse: () => records.first,
        );
        horaEntrada = entrance['hora'] as String;
        estado = 'a_tiempo';
      }

      statuses.add(TodayEmployeeStatus(
        id: uid,
        nombre: emp['nombre'] as String,
        apellido: emp['apellido'] as String,
        cedula: emp['cedula'] as String,
        cargo: emp['cargo'] as String? ?? 'Empleado',
        fotoUrl: emp['foto_url'] as String?,
        estado: estado,
        horaEntrada: horaEntrada,
        minutosTarde: minutosTarde,
      ));
    }
    return statuses;
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(localDatabaseServiceProvider),
  );
});
