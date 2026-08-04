// lib/core/exceptions/error_handler.dart
import 'package:dio/dio.dart';
import 'app_exception.dart';

final class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return ValidationException(
        message: 'Formato de respuesta inválido',
        originalError: error,
      );
    }

    return UnknownException(
      message: error.toString(),
      originalError: error,
    );
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          message: 'Tiempo de conexión agotado',
          originalError: error,
        );

      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Tiempo de envío agotado',
          originalError: error,
        );

      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Tiempo de recepción agotado',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Solicitud cancelada',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Certificado SSL inválido',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Error de conexión',
          originalError: error,
        );

      case DioExceptionType.unknown:
        return UnknownException(
          message: error.message ?? 'Error desconocido',
          originalError: error.error,
        );
    }
  }

  static AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    String message = _getMessageFromStatus(statusCode);

    if (responseData is Map<String, dynamic>) {
      if (responseData['detail'] != null) {
        message = responseData['detail'].toString();
      } else if (responseData['message'] != null) {
        message = responseData['message'].toString();
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message,
          originalError: error,
        );
      case 401:
        return AuthException(
          message: 'Sesión expirada. Por favor inicia sesión nuevamente',
          originalError: error,
        );
      case 403:
        return AuthException(
          message: 'Acceso denegado',
          originalError: error,
        );
      case 404:
        return ServerException(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
      case 429:
        return NetworkException(
          message: 'Demasiadas solicitudes. Intenta más tarde',
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'El servidor no está disponible. Intenta más tarde',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  static String _getMessageFromStatus(int statusCode) {
    return switch (statusCode) {
      400 => 'Solicitud inválida',
      401 => 'No autorizado',
      403 => 'Acceso prohibido',
      404 => 'Recurso no encontrado',
      429 => 'Demasiadas solicitudes',
      500 => 'Error interno del servidor',
      502 => 'Puerta de enlace incorrecta',
      503 => 'Servicio no disponible',
      _ => 'Error HTTP $statusCode',
    };
  }
}
