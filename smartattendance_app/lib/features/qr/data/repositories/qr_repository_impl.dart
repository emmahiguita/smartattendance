// lib/features/qr/data/repositories/qr_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/qr_remote_datasource.dart';

final class QRRepositoryImpl implements QRRepository {
  const QRRepositoryImpl(this._remoteDataSource, this._localDb,
      {LocationService location = const LocationService()})
      : _location = location;

  final QRRemoteDataSource _remoteDataSource;
  final LocalDatabaseService _localDb;
  final LocationService _location;

  @override
  Future<QRValidationResult> validateQR(String qrCode) async {
    // Capturar ubicación ANTES del try/catch — la usan ambos caminos.
    final location = await _location.capture();

    try {
      final result = await _remoteDataSource.validateQR(
        qrCode,
        latitud: location?.lat,
        longitud: location?.lng,
        direccion: location?.dir,
      );
      if (!result.valid) {
        throw ValidationException(message: result.mensaje);
      }
      final userId = result.usuarioId;
      if (userId == null) {
        throw ValidationException(message: 'Respuesta inválida del servidor.');
      }
      return (
        userId: userId,
        tipo: result.tipo ?? 'entrada',
        fechaRegistro: result.fechaRegistro,
        horaRegistro: result.horaRegistro,
      );
    } on DioException catch (e) {
      // Solo hacer fallback offline si es error de red. Si el servidor
      // respondió (badResponse), el error es real y debe propagarse.
      if (!_isNetworkError(e)) rethrow;
      AppLogger.info('Offline mode: validating QR from local database');
      final qrRow = await _localDb.getValidQR(qrCode);
      if (qrRow == null) {
        throw ValidationException(
            message: 'QR no válido o ya fue usado (offline).');
      }
      await _localDb.markQRAsUsed(qrCode);

      final userId = qrRow['usuario_id'] as int;
      
      // Fix P0: Forzar zona horaria del negocio (UTC-05) para la máquina de estados
      // y registros offline, evitando saltos de estado si el reloj está alterado.
      final utc = DateTime.now().toUtc();
      final utc5 = utc.subtract(const Duration(hours: 5));
      final now = DateTime(
        utc5.year, utc5.month, utc5.day,
        utc5.hour, utc5.minute, utc5.second, utc5.millisecond
      );
      final tipo = await _decideTipoOffline(userId, now);
      final uuidMarca = 'qr-${const Uuid().v4()}';

      // Guardar registro de asistencia offline (para sincronizar después)
      await _localDb.insertOfflineAttendance({
        'uuid_marca': uuidMarca,
        'usuario_id': userId,
        'fecha_hora_local': now.toIso8601String(),
        'tipo': tipo,
        'latitud': location?.lat,
        'longitud': location?.lng,
        'direccion': location?.dir,
        'sincronizado': 0,
        'created_at': now.toIso8601String(),
      });

      // Guardar en historial local (para mostrar inmediatamente en UI)
      await _localDb.insertAttendanceRecord({
        'id': uuidMarca.hashCode,
        'usuario_id': userId,
        'tipo': tipo,
        'fecha': now.toIso8601String(),
        'hora':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        'latitud': location?.lat,
        'longitud': location?.lng,
        'direccion': location?.dir,
        'created_at': now.toIso8601String(),
      });

      return (
        userId: userId,
        tipo: tipo,
        fechaRegistro:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        horaRegistro:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Future<String> generateQR(int userId) async {
    try {
      final result = await _remoteDataSource.generateQR(userId);
      if (result.codigo.isEmpty) {
        throw UnknownException(message: 'Respuesta inválida del servidor.');
      }
      return result.codigo;
    } on DioException catch (e) {
      if (!_isNetworkError(e)) rethrow;
      // Offline: generate QR locally
      AppLogger.info('Offline mode: generating QR locally');
      final codigo = 'QR-$userId-${const Uuid().v4().substring(0, 8)}';
      await _localDb.insertLocalQR(userId, codigo);
      return codigo;
    }
  }

  /// Detecta si el error de Dio es exclusivamente de conectividad.
  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown &&
            e.error != null &&
            e.error.toString().contains('SocketException'));
  }

  /// Máquina de estado offline: determina el próximo tipo según los registros
  /// de HOY del usuario. Espejo del server `_decide_tipo()`.
  Future<String> _decideTipoOffline(int userId, DateTime now) async {
    final history = await _localDb.getAttendanceHistory(userId);

    // Último registro de HOY (más reciente primero)
    for (final row in history) {
      final fecha = DateTime.parse(row['fecha'] as String);
      if (fecha.year == now.year &&
          fecha.month == now.month &&
          fecha.day == now.day) {
        return const {
              'entrada': 'salida_almuerzo',
              'salida_almuerzo': 'regreso_almuerzo',
              'regreso_almuerzo': 'salida',
              'salida': 'entrada',
            }[row['tipo'] as String] ??
            'entrada';
      }
    }

    return 'entrada'; // Sin registros hoy → primera marca
  }
}
