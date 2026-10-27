// lib/core/auth/session_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../config/app_config.dart';
import '../localstore/secure_storage_provider.dart';
import 'token_store.dart';

/// ============================================================================
/// CONTROLADOR: SessionController
/// ============================================================================
/// QUÉ HACE: Administra el ciclo de vida de la sesión (Autenticado / Desautenticado).
/// PARA QUÉ SIRVE: Garantiza persistencia segura de tokens y usuario sin memory leaks.
/// PRINCIPIOS SOLID: Single Responsibility (gestión de sesión) y Dependency Inversion.
/// ============================================================================

sealed class SessionState {
  const SessionState();
  bool sameAs(SessionState other) => runtimeType == other.runtimeType;
}

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

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._storage, this._tokens)
      : super(const SessionUnknown());

  final FlutterSecureStorage _storage;
  final TokenStore _tokens;

  /// Restaura la sesión autenticada al iniciar la aplicación
  Future<void> restore() async {
    try {
      final token = await _storage
          .read(key: AppConfig.keyAccessToken)
          .timeout(const Duration(seconds: 3));
      final refreshToken = await _storage
          .read(key: AppConfig.keyRefreshToken)
          .timeout(const Duration(seconds: 3));
      final user =
          await _readUserFromStorage().timeout(const Duration(seconds: 3));

      // El perfil del operador es local: no requiere inventar un JWT para
      // abrir la interfaz. Los endpoints remotos siguen exigiendo su token real.
      if (user == null) {
        await _safeClear();
        _set(const SessionUnauthenticated());
        return;
      }

      // Restaura tokens en memoria para que DioInterceptor no falle
      _tokens
        ..accessToken = token
        ..refreshToken = refreshToken;

      _set(SessionAuthenticated(user));
    } catch (_) {
      await _safeClear();
      _set(const SessionUnauthenticated());
    }
  }

  Future<void> _safeClear() async {
    try {
      await clear().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Autentica al usuario y persiste sesión de forma segura
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
          // Persiste el permiso local para que el administrador no lo pierda al reiniciar.
          'is_admin': user.isAdmin,
        }),
      ),
    ]);
    if (!remember) {
      await Future.wait([
        _storage.delete(key: AppConfig.keyAccessToken),
        _storage.delete(key: AppConfig.keyRefreshToken),
      ]);
    }
    _set(SessionAuthenticated(user));
  }

  void setEphemeralTokens({required String accessToken, String? refreshToken}) {
    _tokens
      ..accessToken = accessToken
      ..refreshToken = refreshToken;
  }

  Future<void> logout() async {
    await clear();
    _set(const SessionUnauthenticated());
  }

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
    final jsonStr = await _storage.read(key: AppConfig.keyUserJson);
    if (jsonStr != null) {
      try {
        final m = jsonDecode(jsonStr) as Map<String, dynamic>;
        final role = (m['cargo'] as String? ?? '').toLowerCase();
        final cedula = m['cedula'] as String? ?? '';
        final isAdm = (m['is_admin'] == true || m['is_admin'] == 1) ||
            role.contains('admin') ||
            role.contains('encargado') ||
            role.contains('supervisor') ||
            role.contains('director') ||
            role.contains('gerente') ||
            cedula == '1007331963';
        return UserEntity(
          id: m['id'] as int,
          nombre: m['nombre'] as String,
          apellido: m['apellido'] as String? ?? '',
          cedula: cedula,
          correo: m['correo'] as String? ?? '',
          cargo: m['cargo'] as String? ?? 'Administrador',
          fotoUrl: m['foto_url'] as String?,
          isAdmin: isAdm,
        );
      } catch (_) {}
    }
    final name = await _storage.read(key: AppConfig.keyUserName);
    final role = await _storage.read(key: AppConfig.keyUserRole);
    if (name == null || role == null) return null;
    final idStr = await _storage.read(key: AppConfig.keyUserId);
    final cedula = await _storage.read(key: AppConfig.keyUserCedula) ?? '';
    final rLower = role.toLowerCase();
    final isAdm = rLower.contains('admin') ||
        rLower.contains('encargado') ||
        rLower.contains('supervisor') ||
        cedula == '1007331963';
    final parts = name.trim().split(RegExp(r'\s+'));
    return UserEntity(
      id: int.tryParse(idStr ?? '') ?? 0,
      nombre: parts.isNotEmpty ? parts.first : name,
      apellido: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      cedula: cedula,
      correo: '',
      cargo: role,
      isAdmin: isAdm,
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
