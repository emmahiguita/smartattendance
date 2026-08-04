// lib/core/config/app_config.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'environment_config.dart';

/// Application-wide configuration constants.
/// baseUrl, connectTimeout y receiveTimeout se resuelven desde
/// [ServerConfig] que permite override en runtime por el usuario.
class AppConfig {
  AppConfig._();

  // ── App ─────────────────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static const String companyName = 'CONTROL AI';

  static const String keyNotificationsEnabled = 'key_notifications_enabled';

  // ── API ──────────────────────────────────────────────────────
  /// URL del backend. Si el usuario configuró una manual en Settings,
  /// se usa esa. Si no, el default del ambiente compilado.
  static String _customUrl = '';
  static String get baseUrl =>
      _customUrl.isNotEmpty ? _customUrl : EnvironmentConfig.baseUrl;

  /// Permite que ServerConfigNotifier inyecte la URL personalizada.
  static void setCustomUrl(String url) {
    _customUrl = url;
  }

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
  static const String keyCustomServerUrl = 'custom_server_url';

  static String fullPhotoUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base$relativePath';
  }
}
