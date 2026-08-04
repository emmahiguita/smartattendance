// lib/core/logging/app_logger.dart
import 'package:logger/logger.dart';
import '../config/environment_config.dart';

final class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: EnvironmentConfig.enableLogging ? 2 : 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
    level: EnvironmentConfig.enableLogging ? Level.debug : Level.warning,
  );

  static void debug(String message) {
    if (EnvironmentConfig.enableLogging) _logger.d(message);
  }

  static void info(String message) {
    if (EnvironmentConfig.enableLogging) _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // API Logging
  static void logApiCall(
    String method,
    String endpoint, {
    dynamic data,
  }) {
    if (!EnvironmentConfig.enableLogging) return;
    info('→ [$method] $endpoint');
    if (data != null) {
      debug('  Data: $data');
    }
  }

  static void logApiResponse(
    int statusCode,
    String endpoint,
    dynamic response,
  ) {
    if (!EnvironmentConfig.enableLogging) return;
    info('← $statusCode $endpoint');
    debug('  Response: $response');
  }

  static void logApiError(
    String method,
    String endpoint,
    dynamic error,
  ) {
    AppLogger.error(
      '✗ [$method] $endpoint',
      error: error,
    );
  }

  // User actions
  static void logUserAction(String action) {
    if (!EnvironmentConfig.enableLogging) return;
    info('👤 Action: $action');
  }

  // Performance
  static void logPerformance(String operation, Duration duration) {
    if (!EnvironmentConfig.enableLogging) return;
    info('⏱️  $operation took ${duration.inMilliseconds}ms');
  }
}
