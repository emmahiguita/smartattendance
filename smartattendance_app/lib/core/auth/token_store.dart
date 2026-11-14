// lib/core/auth/token_store.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Almacén en memoria de los tokens activos.
///
/// Soporta la sesión EFÍMERA ("Recordar sesión" desmarcado): cuando el usuario
/// no pide recordar la sesión, los tokens viven SOLO aquí y se pierden al
/// cerrar la app (el secure storage queda limpio). El interceptor de Dio y el
/// SessionController comparten esta instancia vía Riverpod.
final class TokenStore {
  // Identifica credenciales locales, que no son JWT válidos del servidor.
  static bool isLocalToken(String? token) =>
      token == 'local-offline-token' ||
      (token?.startsWith('local_jwt_') ?? false);
  String? accessToken;
  String? refreshToken;
  String? serverUrl;
  int _generation = 0;
  Future<void> _pending = Future<void>.value();

  int get generation => _generation;

  // QUÉ HACE: Ordena escrituras y borrados sin retener el bloqueo durante HTTP.
  // CÓMO: Un fallo se entrega al llamante y no bloquea operaciones posteriores.
  Future<T> serialize<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void clear() {
    _generation++;
    accessToken = null;
    refreshToken = null;
    serverUrl = null;
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
