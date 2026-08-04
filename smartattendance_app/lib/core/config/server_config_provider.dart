// lib/core/config/server_config_provider.dart
// ===================================================================
// Permite al usuario cambiar la URL del backend en runtime sin
// recompilar la app. Persiste en secure storage. Al cambiar, el
// dioProvider se reconstruye automáticamente.
// ===================================================================
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'environment_config.dart';
import '../localstore/secure_storage_provider.dart';

/// Key en secure storage para la URL personalizada del servidor.
const _keyServerUrl = 'custom_server_url';

/// Provider que expone la URL actual del backend. Si el usuario ha
/// configurado una URL manual, la usa. Si no, usa el default por ambiente.
final serverUrlProvider = Provider<String>((ref) {
  final storage = ref.watch(secureStorageProvider);
  // Leer de storage una sola vez por ciclo de vida del provider.
  // Para cambios reactivos, usar serverConfigNotifierProvider.
  return EnvironmentConfig.baseUrl; // fallback compilado
});

/// Notifier que permite leer y escribir la URL del servidor.
class ServerConfigNotifier extends StateNotifier<String> {
  ServerConfigNotifier(this._storage) : super(EnvironmentConfig.baseUrl) {
    _load();
  }

  final FlutterSecureStorage _storage;

  Future<void> _load() async {
    final saved = await _storage.read(key: _keyServerUrl);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
    // Si no hay guardada, state ya es el default por ambiente.
  }

  /// URL actual (reactiva). Si el usuario la cambió manualmente,
  /// retorna la personalizada. Si no, el default compilado.
  String get currentUrl => state;

  /// True si el usuario sobrescribió la URL manualmente.
  bool get isCustom => state != EnvironmentConfig.baseUrl;

  /// Guarda una nueva URL y notifica a los listeners.
  Future<void> setUrl(String url) async {
    final trimmed = url.trim();
    // Normalizar: quitar trailing slash y forzar /api/v1 si no lo tiene
    String normalized = trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (!normalized.endsWith('/api/v1')) {
      if (normalized.endsWith('/api')) {
        normalized = '$normalized/v1';
      } else {
        normalized = '$normalized/api/v1';
      }
    }

    await _storage.write(key: _keyServerUrl, value: normalized);
    state = normalized;
  }

  /// Restaura la URL al default del ambiente (borra la personalizada).
  Future<void> resetToDefault() async {
    await _storage.delete(key: _keyServerUrl);
    state = EnvironmentConfig.baseUrl;
  }

  /// Prueba conectividad con el backend: GET /health.
  /// Retorna true si responde 200 en menos de 5 segundos.
  Future<bool> testConnection() async {
    try {
      final url = state.replaceAll('/api/v1', '');
      final uri = Uri.parse('$url/health');
      // Usamos dart:io HttpClient directamente para no depender de Dio
      // (evita referencias circulares con dioProvider).
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client.getUrl(uri);
        final response = await request.close().timeout(
          const Duration(seconds: 5),
        );
        return response.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }
}

final serverConfigNotifierProvider =
    StateNotifierProvider<ServerConfigNotifier, String>((ref) {
  return ServerConfigNotifier(ref.watch(secureStorageProvider));
});
