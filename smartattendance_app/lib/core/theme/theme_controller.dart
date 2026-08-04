// lib/core/theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../localstore/secure_storage_provider.dart';

/// Persiste la preferencia de tema del usuario (sistema / claro / oscuro).
/// Usa FlutterSecureStorage (ya presente en el proyecto y estable en Android).
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._storage) : super(ThemeMode.system) {
    _restore();
  }

  final FlutterSecureStorage _storage;

  static const _prefKey = 'theme_mode';
  static const _values = {
    'system': ThemeMode.system,
    'light': ThemeMode.light,
    'dark': ThemeMode.dark
  };

  Future<void> _restore() async {
    try {
      final saved = await _storage.read(key: _prefKey);
      if (saved != null && _values.containsKey(saved)) {
        state = _values[saved]!;
      }
    } catch (_) {
      // sin preferencia guardada → system
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(
        key: _prefKey,
        value: _values.entries.firstWhere((e) => e.value == mode).key,
      );
    } catch (_) {
      // no persistido → solo aplica en esta sesión
    }
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(ref.watch(secureStorageProvider)),
);
