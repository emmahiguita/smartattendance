// lib/features/qr/data/datasources/qr_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/qr_generate_model.dart';
import '../models/qr_model.dart';

/// Sin fallbacks locales: una validación QR "exitosa" sin servidor marcaría
/// asistencia inexistente. El error real siempre llega al usuario.
final class QRRemoteDataSource {
  const QRRemoteDataSource(this._dio);

  final Dio _dio;

  Future<QRValidateModel> validateQR(
    String qrCode, {
    double? latitud,
    double? longitud,
    String? direccion,
  }) async {
    try {
      final response = await _dio.post(
        '/qr/validate',
        data: {
          'codigo': qrCode,
          if (latitud != null) 'latitud': latitud,
          if (longitud != null) 'longitud': longitud,
          if (direccion != null) 'direccion': direccion,
        },
      );
      return QRValidateModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('QR validation failed', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  /// Genera un QR nuevo para un empleado (admin only). El backend desactiva
  /// cualquier QR activo previo del mismo usuario (single-active policy).
  Future<QRGenerateModel> generateQR(int usuarioId) async {
    try {
      final response = await _dio.post(
        '/qr/generate',
        data: {'usuario_id': usuarioId},
      );
      return QRGenerateModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('QR generation failed', error: e);
      throw ErrorHandler.handle(e);
    }
  }
}
