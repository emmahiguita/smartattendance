// lib/core/auth/session_controller.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../config/app_config.dart';
import '../localstore/secure_storage_provider.dart';
import 'token_store.dart';

/// Application session state.
///
/// `sameAs` evita notificaciones espurias: objetos equivalentes (p. ej.
/// re-restaurar una sesión ya autenticada) no deben reconstruir el router.
sealed class SessionState {
  const SessionState();

  bool sameAs(SessionState other) => runtimeType == other.runtimeType;
}

/// Session still being restored from storage — UI should not decide yet.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);
  final UserEntity user;

  @override
  bool sameAs(SessionState other) =>
      other is SessionAuthenticated && other.user == user;
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Single source of truth for the authenticated session.
///
/// - Restores the session from secure storage on app start.
/// - `logout()` clears every session key — providers that watch
///   [sessionControllerProvider] rebuild automatically, so no state
///   leaks between users on the same device (H2).
/// - Never depends on the router or on feature providers: layers stay
///   inverted-free. Navigation reacts to the state, not the other way.
class SessionController extends StateNotifier<SessionState> {
  SessionController(this._storage, this._tokens)
      : super(const SessionUnknown());

  final FlutterSecureStorage _storage;
  final TokenStore _tokens;

  Future<void> restore() async {
    final token = await _storage.read(key: AppConfig.keyAccessToken);
    final user = await _readUserFromStorage();

    if (token == null || user == null) {
      // Incomplete session → clean slate.
      await clear();
      _set(const SessionUnauthenticated());
      return;
    }

    _set(SessionAuthenticated(user));
  }

  /// Inicia sesión y persiste el estado.
  ///
  /// [remember] controla la sesión EFÍMERA: cuando es false, los tokens se
  /// mantienen SOLO en memoria ([TokenStore]) y se borran del secure storage —
  /// al reiniciar la app no hay sesión restaurable. El interceptor de Dio lee
  /// primero la memoria y luego el storage, así las peticiones funcionan
  /// igual mientras la app esté abierta.
  Future<void> authenticate(UserEntity user, {bool remember = true}) async {
    await Future.wait([
      _storage.write(key: AppConfig.keyUserId, value: user.id.toString()),
      _storage.write(key: AppConfig.keyUserCedula, value: user.cedula),
      _storage.write(key: AppConfig.keyUserName, value: user.fullName),
      _storage.write(key: AppConfig.keyUserRole, value: user.cargo),
      _storage.write(
        key: AppConfig.keyUserJson,
        value: jsonEncode({
          'id': user.id,
          'nombre': user.nombre,
          'apellido': user.apellido,
          'cedula': user.cedula,
          'correo': user.correo,
          'cargo': user.cargo,
          'foto_url': user.fotoUrl,
        }),
      ),
    ]);
    if (!remember) {
      // Los datos del perfil persisten (no hay nada sensible en ellos), pero
      // los tokens NO: la sesión muere al cerrar la app.
      await Future.wait([
        _storage.delete(key: AppConfig.keyAccessToken),
        _storage.delete(key: AppConfig.keyRefreshToken),
      ]);
    }
    _set(SessionAuthenticated(user));
  }

  /// Guarda los tokens EFÍMEROS (solo memoria) para una sesión no recordada.
  /// El token llega por este canal porque `authenticate` recibe solo el user.
  void setEphemeralTokens({required String accessToken, String? refreshToken}) {
    _tokens
      ..accessToken = accessToken
      ..refreshToken = refreshToken;
  }

  Future<void> logout() async {
    await clear();
    _set(const SessionUnauthenticated());
  }

  /// Solo notifica cuando el estado realmente cambió (evita rebuilds en loop).
  void _set(SessionState next) {
    if (next.sameAs(state)) return;
    state = next;
  }

  Future<void> clear() async {
    _tokens.clear();
    await Future.wait([
      _storage.delete(key: AppConfig.keyAccessToken),
      _storage.delete(key: AppConfig.keyRefreshToken),
      _storage.delete(key: AppConfig.keyUserName),
      _storage.delete(key: AppConfig.keyUserId),
      _storage.delete(key: AppConfig.keyUserCedula),
      _storage.delete(key: AppConfig.keyUserRole),
      _storage.delete(key: AppConfig.keyUserJson),
    ]);
  }

  Future<UserEntity?> _readUserFromStorage() async {
    // Primary: serialized user JSON.
    final jsonStr = await _storage.read(key: AppConfig.keyUserJson);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserEntity(
          id: map['id'] as int,
          nombre: map['nombre'] as String,
          apellido: map['apellido'] as String? ?? '',
          cedula: map['cedula'] as String? ?? '',
          correo: map['correo'] as String? ?? '',
          cargo: map['cargo'] as String,
          fotoUrl: map['foto_url'] as String?,
        );
      } catch (_) {
        return null;
      }
    }

    // Fallback: legacy individual keys (user_name holds the full name).
    final name = await _storage.read(key: AppConfig.keyUserName);
    final role = await _storage.read(key: AppConfig.keyUserRole);
    if (name == null || role == null) return null;

    final cedula = await _storage.read(key: AppConfig.keyUserCedula) ?? '';
    final idStr = await _storage.read(key: AppConfig.keyUserId);
    final parts = name.trim().split(RegExp(r'\s+'));
    return UserEntity(
      id: int.tryParse(idStr ?? '') ?? 0,
      nombre: parts.isNotEmpty ? parts.first : name,
      apellido: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      cedula: cedula,
      correo: '',
      cargo: role,
    );
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(
    ref.watch(secureStorageProvider),
    ref.watch(tokenStoreProvider),
  );
});
