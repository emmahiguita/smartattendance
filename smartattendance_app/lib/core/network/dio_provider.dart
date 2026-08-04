import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/session_controller.dart';
import '../auth/token_store.dart';
import '../config/app_config.dart';
import '../config/environment_config.dart';
import '../config/server_config_provider.dart';
import '../localstore/secure_storage_provider.dart';
import '../logging/app_logger.dart';

/// Provides a globally configured Dio instance with Auth, Refresh & Error
/// interceptors.
///
/// Layering: this file must NOT depend on the router or on any feature.
/// On a failed refresh the session controller logs the user out; the router
/// reacts to the session state change (dependency inversion).
final dioProvider = Provider<Dio>((ref) {
  // Observer server URL changes — si el usuario cambia el servidor
  // en Settings, este provider se reconstruye automáticamente.
  final serverUrl = ref.watch(serverConfigNotifierProvider);
  // Sincronizar AppConfig.baseUrl para que fullPhotoUrl y otros
  // consumidores estáticos usen la URL correcta.
  AppConfig.setCustomUrl(serverUrl != EnvironmentConfig.baseUrl ? serverUrl : '');

  final dio = Dio(
    BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  final storage = ref.watch(secureStorageProvider);
  final tokens = ref.watch(tokenStoreProvider);

  // Logging Interceptor
  if (AppConfig.enableLogging) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.logApiCall(options.method, options.path,
              data: options.data);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.logApiResponse(
            response.statusCode ?? 200,
            response.requestOptions.path,
            response.data,
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.logApiError(
            error.requestOptions.method,
            error.requestOptions.path,
            error,
          );
          return handler.next(error);
        },
      ),
    );
  }

  // Auth + Refresh Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for credential endpoints
        if (options.path.contains('/auth/login') ||
            options.path.contains('/auth/refresh')) {
          return handler.next(options);
        }

        // Sesión efímera: token en memoria primero (TokenStore), storage como
        // fallback (sesión recordada restaurada tras reiniciar la app).
        final token = tokens.accessToken ??
            await storage.read(key: AppConfig.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final isCredentialCall =
            error.requestOptions.path.contains('/auth/login') ||
                error.requestOptions.path.contains('/auth/refresh');

        if (status == 401 && !isCredentialCall) {
          final refreshResult = await _tryRefreshResult(storage, tokens);
          if (refreshResult == _RefreshStatus.success) {
            // Retry the original request once with the new access token.
            try {
              final newToken = tokens.accessToken ??
                  await storage.read(key: AppConfig.keyAccessToken);
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              AppLogger.warning('Retry after refresh failed');
            }
          } else if (refreshResult == _RefreshStatus.networkError) {
            // Network failure during refresh — DO NOT LOG OUT!
            AppLogger.warning(
                'Refresh attempted while offline/unreachable. Preserving offline session.');
            return handler.next(error);
          }
          // Server explicitly rejected the refresh token (401/400) → end the session.
          await ref.read(sessionControllerProvider.notifier).logout();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});

enum _RefreshStatus { success, rejected, networkError }

/// Exchange the stored refresh token for a fresh access + refresh pair.
Future<_RefreshStatus> _tryRefreshResult(
  FlutterSecureStorage storage,
  TokenStore tokens,
) async {
  final refreshToken =
      tokens.refreshToken ?? await storage.read(key: AppConfig.keyRefreshToken);
  if (refreshToken == null || refreshToken.isEmpty) {
    return _RefreshStatus.rejected;
  }

  try {
    final response = await Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        contentType: Headers.jsonContentType,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    ).post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final data = response.data as Map<String, dynamic>;
    final newAccess = data['access_token'] as String;
    final newRefresh = data['refresh_token'] as String;
    await Future.wait([
      storage.write(key: AppConfig.keyAccessToken, value: newAccess),
      storage.write(key: AppConfig.keyRefreshToken, value: newRefresh),
    ]);
    tokens
      ..accessToken = newAccess
      ..refreshToken = newRefresh;
    AppLogger.info('Access token refreshed successfully');
    return _RefreshStatus.success;
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      AppLogger.warning(
          'Refresh token call failed due to network connectivity: ${e.message}');
      return _RefreshStatus.networkError;
    }
    AppLogger.warning('Refresh token rejected by server: $e');
    return _RefreshStatus.rejected;
  } catch (e) {
    AppLogger.warning('Refresh token rejected: $e');
    return _RefreshStatus.rejected;
  }
}
