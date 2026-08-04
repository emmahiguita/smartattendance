// lib/core/config/app_config.dart
import 'environment_config.dart';

/// Application-wide configuration constants.
/// Utiliza EnvironmentConfig para manejar diferentes ambientes.
class AppConfig {
  AppConfig._();

  // ── App ─────────────────────────────────────────────────────────
  /// Versión mostrada en Configuración → Acerca de (sincronizada con pubspec).
  static const String appVersion = '1.0.0';

  /// Nombre de la empresa — branding mostrado en escáner QR y textos.
  static const String companyName = 'CONTROL AI';

  /// Preferencia de recordatorios de jornada (settings la escribe, home la lee).
  static const String keyNotificationsEnabled = 'key_notifications_enabled';

  // ── API ──────────────────────────────────────────────────────
  static String get baseUrl => EnvironmentConfig.baseUrl;
  static Duration get connectTimeout => EnvironmentConfig.connectTimeout;
  static Duration get receiveTimeout => EnvironmentConfig.receiveTimeout;
  static bool get enableLogging => EnvironmentConfig.enableLogging;

  // ── Storage Keys ─────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserCedula = 'user_cedula';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';
  static const String keyUserJson = 'user_json';
  static const String keySavedCedula = 'saved_cedula';
  static const String keySavedPassword = 'saved_password';

  /// Construye la URL completa de la foto de perfil a partir de la ruta
  /// relativa del servidor (/static/fotos/{filename}).
  static String fullPhotoUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base$relativePath';
  }
}
