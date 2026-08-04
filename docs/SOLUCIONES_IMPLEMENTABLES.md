# SOLUCIONES RÁPIDAS - Implementables en 24 Horas

## 1. Estructura de Configuración Mejorada

### `lib/core/config/environment_config.dart`

```dart
enum Environment { development, staging, production }

final class EnvironmentConfig {
  static const Environment _environment = Environment.production;
  
  static final _configs = {
    Environment.development: _DevConfig(),
    Environment.staging: _StagingConfig(),
    Environment.production: _ProdConfig(),
  };
  
  static _BaseConfig get _current => _configs[_environment]!;
  
  static String get baseUrl => _current.baseUrl;
  static String get apiKey => _current.apiKey;
  static bool get enableLogging => _current.enableLogging;
  static bool get enableAnalytics => _current.enableAnalytics;
  static Duration get connectTimeout => _current.connectTimeout;
}

abstract base class _BaseConfig {
  String get baseUrl;
  String get apiKey;
  bool get enableLogging;
  bool get enableAnalytics;
  Duration get connectTimeout => const Duration(seconds: 10);
}

final class _DevConfig extends _BaseConfig {
  @override
  String get baseUrl => 'http://localhost:8000/api/v1';
  @override
  String get apiKey => 'dev-key-xxx';
  @override
  bool get enableLogging => true;
  @override
  bool get enableAnalytics => false;
}

final class _StagingConfig extends _BaseConfig {
  @override
  String get baseUrl => 'https://api-staging.smartattendance.io/api/v1';
  @override
  String get apiKey => const String.fromEnvironment('API_KEY');
  @override
  bool get enableLogging => true;
  @override
  bool get enableAnalytics => true;
}

final class _ProdConfig extends _BaseConfig {
  @override
  String get baseUrl => 'https://api.smartattendance.io/api/v1';
  @override
  String get apiKey => const String.fromEnvironment('API_KEY');
  @override
  bool get enableLogging => false;
  @override
  bool get enableAnalytics => true;
}
```

---

## 2. Error Handling Centralizado

### `lib/core/exceptions/app_exception.dart`

```dart
sealed class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException({
    required this.message,
    this.code,
  });
  
  @override
  String toString() => 'AppException: $message';
}

final class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
  });
}

final class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
  });
}

final class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
  });
}

final class ServerException extends AppException {
  final int? statusCode;
  
  ServerException({
    required String message,
    this.statusCode,
  }) : super(message: message, code: 'SERVER_ERROR_$statusCode');
}

final class UnknownException extends AppException {
  final dynamic originalError;
  
  UnknownException({
    required super.message,
    this.originalError,
  }) : super(code: 'UNKNOWN_ERROR');
}
```

### `lib/core/exceptions/error_handler.dart`

```dart
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
          message: 'Tiempo de espera agotado',
        );
      
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Tiempo de envío agotado',
        );
      
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Tiempo de recepción agotado',
        );
      
      case DioExceptionType.badResponse:
        return _handleBadResponse(error);
      
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Solicitud cancelada',
        );
      
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Certificado SSL inválido',
        );
      
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Error de conexión',
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
    
    if (responseData is Map<String, dynamic> && responseData['detail'] != null) {
      message = responseData['detail'].toString();
    }
    
    switch (statusCode) {
      case 400:
        return ValidationException(message: message);
      case 401:
        return AuthException(message: 'Sesión expirada');
      case 403:
        return AuthException(message: 'Acceso denegado');
      case 404:
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'El servidor no está disponible',
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
    }
  }
  
  static String _getMessageFromStatus(int statusCode) {
    return switch (statusCode) {
      400 => 'Solicitud inválida',
      401 => 'No autorizado',
      403 => 'Acceso prohibido',
      404 => 'No encontrado',
      429 => 'Demasiadas solicitudes',
      500 => 'Error interno del servidor',
      502 => 'Puerta de enlace incorrecta',
      503 => 'Servicio no disponible',
      _ => 'Error HTTP $statusCode',
    };
  }
}
```

---

## 3. Validadores Robustos

### `lib/core/validators/validators.dart`

```dart
abstract final class Validators {
  static String? validateCedula(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'La cédula no puede estar vacía';
    }
    
    final trimmed = input.trim();
    
    if (trimmed.length < 6) {
      return 'Mínimo 6 dígitos';
    }
    
    if (trimmed.length > 13) {
      return 'Máximo 13 dígitos';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return 'Solo se aceptan números';
    }
    
    return null;
  }
  
  static String? validateEmail(String? input) {
    if (input?.isEmpty ?? true) return null;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(input!)) {
      return 'Email inválido';
    }
    
    return null;
  }
  
  static String? validatePassword(String? input) {
    if (input == null || input.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (input.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    
    if (!input.contains(RegExp(r'[A-Z]'))) {
      return 'Requiere al menos una mayúscula';
    }
    
    if (!input.contains(RegExp(r'[a-z]'))) {
      return 'Requiere al menos una minúscula';
    }
    
    if (!input.contains(RegExp(r'[0-9]'))) {
      return 'Requiere al menos un número';
    }
    
    return null;
  }
}
```

---

## 4. Logging Estructurado

### `lib/core/logging/app_logger.dart`

```dart
import 'package:logger/logger.dart';

final class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );
  
  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) => _logger.e(
    message,
    error: error,
    stackTrace: stackTrace,
  );
  
  static void logApiCall(
    String method,
    String url, {
    dynamic data,
  }) {
    info('[$method] $url');
    if (data != null) {
      debug('Data: $data');
    }
  }
  
  static void logApiResponse(
    int statusCode,
    dynamic response,
  ) {
    info('Response: $statusCode');
    debug('Data: $response');
  }
  
  static void logApiError(
    String method,
    String url,
    dynamic error,
  ) {
    error('[$method] $url failed', error: error);
  }
}
```

---

## 5. Implementación Segura de DIO

### `lib/core/network/secure_dio_provider.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment_config.dart';
import '../exceptions/error_handler.dart';
import '../logging/app_logger.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvironmentConfig.baseUrl,
      connectTimeout: EnvironmentConfig.connectTimeout,
      receiveTimeout: EnvironmentConfig.connectTimeout,
      contentType: Headers.jsonContentType,
    ),
  );
  
  // Logging Interceptor
  if (EnvironmentConfig.enableLogging) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.logApiCall(options.method, options.path);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.logApiResponse(response.statusCode ?? 0, response.data);
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.logApiError(
            error.requestOptions.method,
            error.requestOptions.path,
            error,
          );
          return handler.next(error);
        },
      ),
    );
  }
  
  // Auth Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth para endpoints públicos
        if (options.path.contains('/auth/login')) {
          return handler.next(options);
        }
        
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Manejar token expirado
        if (error.response?.statusCode == 401) {
          await storage.delete(key: 'access_token');
          // Navegar a login (hacer a través de un callback)
        }
        
        final appError = ErrorHandler.handle(error);
        return handler.reject(error.copyWith(error: appError));
      },
    ),
  );
  
  return dio;
});
```

---

## 6. Rate Limiting

### `lib/core/network/rate_limiter.dart`

```dart
final class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final Duration _window;
  final int _maxRequests;
  
  RateLimiter({
    Duration window = const Duration(minutes: 1),
    int maxRequests = 100,
  })  : _window = window,
        _maxRequests = maxRequests;
  
  bool isAllowed(String key) {
    final now = DateTime.now();
    _requests[key] ??= [];
    
    // Eliminar requests fuera de la ventana temporal
    _requests[key]!.removeWhere(
      (timestamp) => now.difference(timestamp) > _window,
    );
    
    // Si se alcanzó el límite, denegar
    if (_requests[key]!.length >= _maxRequests) {
      return false;
    }
    
    // Registrar nuevo request
    _requests[key]!.add(now);
    return true;
  }
  
  void reset(String key) {
    _requests.remove(key);
  }
  
  void resetAll() {
    _requests.clear();
  }
}

// Provider
final rateLimiterProvider = Provider<RateLimiter>((ref) {
  return RateLimiter();
});
```

---

## 7. Tests Básicos

### `test/unit/auth/login_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';
import 'package:smartattendance/features/auth/domain/repositories/auth_repository.dart';
import 'package:smartattendance/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockRepository;
  
  const testCedula = '1234567890';
  const testUser = UserEntity(
    id: 1,
    nombre: 'Test',
    apellido: 'User',
    cedula: testCedula,
    correo: 'test@example.com',
    cargo: 'Developer',
  );
  const testToken = 'test-token';
  
  setUp(() {
    mockRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockRepository);
  });
  
  group('LoginUseCase', () {
    test('debe llamar al repository con la cédula correcta', () async {
      when(() => mockRepository.loginByCedula(testCedula))
          .thenAnswer((_) async => (testToken, testUser));
      
      final result = await loginUseCase(testCedula);
      
      expect(result.$1, testToken);
      expect(result.$2.cedula, testCedula);
      verify(() => mockRepository.loginByCedula(testCedula)).called(1);
    });
    
    test('debe lanzar ArgumentError si la cédula está vacía', () {
      expect(
        () => loginUseCase(''),
        throwsA(isA<ArgumentError>()),
      );
    });
    
    test('debe lanzar ArgumentError si la cédula es solo espacios', () {
      expect(
        () => loginUseCase('   '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### `test/unit/validators/validators_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/validators/validators.dart';

void main() {
  group('Validators', () {
    group('validateCedula', () {
      test('debe retornar null para cédula válida', () {
        expect(Validators.validateCedula('1234567890'), isNull);
      });
      
      test('debe rechazar cédula vacía', () {
        expect(
          Validators.validateCedula(''),
          isNotNull,
        );
      });
      
      test('debe rechazar cédula muy corta', () {
        expect(
          Validators.validateCedula('12345'),
          isNotNull,
        );
      });
      
      test('debe rechazar cédula no numérica', () {
        expect(
          Validators.validateCedula('abcdefghij'),
          isNotNull,
        );
      });
    });
  });
}
```

---

Esta es una guía de implementación rápida. Cada archivo es independiente y puede ser implementado en paralelo.

