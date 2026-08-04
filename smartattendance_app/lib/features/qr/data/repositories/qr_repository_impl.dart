// lib/features/qr/data/repositories/qr_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
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
    try {
      final location = await _location.capture();

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
    } on DioException catch (_) {
      // Offline: validate QR from local DB
      AppLogger.info('Offline mode: validating QR from local database');
      final qrRow = await _localDb.getValidQR(qrCode);
      if (qrRow == null) {
        throw ValidationException(
            message: 'QR no válido o ya fue usado (offline).');
      }
      await _localDb.markQRAsUsed(qrCode);
      final userId = qrRow['usuario_id'] as int;
      final now = DateTime.now();
      return (
        userId: userId,
        tipo: 'entrada',
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
    } on DioException catch (_) {
      // Offline: generate QR locally
      AppLogger.info('Offline mode: generating QR locally');
      final codigo = 'QR-${userId}-${const Uuid().v4().substring(0, 8)}';
      await _localDb.insertLocalQR(userId, codigo);
      return codigo;
    }
  }
}
