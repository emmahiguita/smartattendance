// lib/core/exceptions/app_exception.dart

sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => '$runtimeType: $message';
}

final class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

final class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

final class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
  });
}

final class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    this.statusCode,
    super.originalError,
  }) : super(code: 'SERVER_ERROR_$statusCode');
}

final class UnknownException extends AppException {
  UnknownException({
    required super.message,
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
  });
}
