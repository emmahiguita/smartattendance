// lib/core/auth/token_store.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Almacén en memoria de los tokens activos.
///
/// Soporta la sesión EFÍMERA ("Recordar sesión" desmarcado): cuando el usuario
/// no pide recordar la sesión, los tokens viven SOLO aquí y se pierden al
/// cerrar la app (el secure storage queda limpio). El interceptor de Dio y el
/// SessionController comparten esta instancia vía Riverpod.
final class TokenStore {
  String? accessToken;
  String? refreshToken;

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
