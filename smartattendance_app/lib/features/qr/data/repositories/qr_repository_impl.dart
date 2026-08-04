// lib/features/qr/data/repositories/qr_repository_impl.dart
import 'package:dio/dio.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/qr_remote_datasource.dart';

final class QRRepositoryImpl implements QRRepository {
  const QRRepositoryImpl(this._remoteDataSource,
      {LocationService location = const LocationService()})
      : _location = location;

  final QRRemoteDataSource _remoteDataSource;
  final LocationService _location;

  @override
  Future<QRValidationResult> validateQR(String qrCode) async {
    try {
      // Ubicación en tiempo real del escaneo — misma política que la marca
      // manual: timeout duro, jamás bloquea la validación.
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
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
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
      throw ErrorHandler.handle(e);
    }
  }
}
