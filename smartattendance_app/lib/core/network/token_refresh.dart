// QUÉ HACE: Renueva credenciales conservando el carácter efímero de la sesión.
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/token_store.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';

enum RefreshStatus { success, rejected, networkError, superseded }

/// Exchange the stored refresh token for a fresh access + refresh pair.
Future<RefreshStatus> tryRefreshResult(
  FlutterSecureStorage storage,
  TokenStore tokens,
  String baseUrl,
) async {
  final generation = tokens.generation;
  if (tokens.serverUrl != baseUrl) return RefreshStatus.superseded;
  final refreshToken = tokens.refreshToken;
  if (refreshToken == null ||
      refreshToken.isEmpty ||
      TokenStore.isLocalToken(tokens.accessToken)) {
    return RefreshStatus.rejected;
  }

  final client = Dio(BaseOptions(
      contentType: Headers.jsonContentType,
      followRedirects: false,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5)));
  try {
    final refreshUrl = baseUrl.endsWith('/')
        ? '${baseUrl}auth/refresh'
        : '$baseUrl/auth/refresh';
    final response = await client.post(
      refreshUrl,
      data: {'refresh_token': refreshToken},
    );

    final data = response.data as Map<String, dynamic>;
    final newAccess = data['access_token'] as String;
    final newRefresh = data['refresh_token'] as String;
    if (newAccess.isEmpty || newRefresh.isEmpty) return RefreshStatus.rejected;
    return await tokens.serialize(() async {
      if (tokens.generation != generation) return RefreshStatus.superseded;
      final persisted = await storage.read(key: AppConfig.keyRefreshToken);
      if (tokens.generation != generation) return RefreshStatus.superseded;
      if (persisted == refreshToken) {
        await Future.wait([
          storage.write(key: AppConfig.keyAccessToken, value: newAccess),
          storage.write(key: AppConfig.keyRefreshToken, value: newRefresh),
        ]);
      }
      // Logout puede invalidar mientras escribe; su borrado ya está en la cola.
      if (tokens.generation != generation) return RefreshStatus.superseded;
      tokens
        ..accessToken = newAccess
        ..refreshToken = newRefresh;
      return RefreshStatus.success;
    });
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    AppLogger.warning('Refresh failed: ${status ?? e.type.name}');
    return const {400, 401, 403}.contains(status)
        ? RefreshStatus.rejected
        : RefreshStatus.networkError;
  } catch (e) {
    AppLogger.warning('Refresh token rejected: ${e.runtimeType}');
    return RefreshStatus.networkError;
  } finally {
    client.close(force: true);
  }
}
