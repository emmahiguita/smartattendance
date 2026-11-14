import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../auth/token_store.dart';
import '../config/app_config.dart';
import '../config/environment_config.dart';
import '../config/server_config_provider.dart';
import '../localstore/secure_storage_provider.dart';
import '../logging/app_logger.dart';
import 'single_flight.dart';
import 'token_refresh.dart';

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
  AppConfig.setCustomUrl(
      serverUrl != EnvironmentConfig.baseUrl ? serverUrl : '');

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
  final serverOrigin = Uri.parse(serverUrl).origin;
  var active = true;
  ref.onDispose(() {
    active = false;
    dio.close(force: true);
  });
  var refreshFlight = SingleFlight<RefreshStatus>();
  var refreshGeneration = tokens.generation;

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
      onRequest: (options, handler) {
        if (options.uri.path.contains('/auth/')) {
          options.followRedirects = false;
          return handler.next(options);
        }
        final generation =
            options.extra['sessionGeneration'] ?? tokens.generation;
        final token =
            tokens.serverUrl == serverUrl && options.uri.origin == serverOrigin
                ? tokens.accessToken
                : null;
        if (generation != tokens.generation) {
          return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'La sesión cambió.'));
        }
        options.extra['sessionGeneration'] = generation;
        options.extra['sessionAccess'] = token;
        if (token != null && !TokenStore.isLocalToken(token)) {
          options.headers['Authorization'] = 'Bearer $token';
          options.followRedirects = false;
        } else {
          options.headers.remove('Authorization');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final generation = request.extra['sessionGeneration'];
        final sent = request.extra['sessionAccess'] as String?;
        if (!active ||
            error.response?.statusCode != 401 ||
            generation != tokens.generation ||
            sent == null ||
            TokenStore.isLocalToken(sent) ||
            request.extra['authRetried'] == true) {
          return handler.next(error);
        }
        // QUÉ HACE: Un 401 tardío no renueva ni cierra una sesión distinta.
        if (refreshGeneration != generation) {
          refreshGeneration = tokens.generation;
          refreshFlight = SingleFlight<RefreshStatus>();
        }
        final alreadyRenewed =
            tokens.accessToken != null && tokens.accessToken != sent;
        final result = alreadyRenewed
            ? RefreshStatus.success
            : await refreshFlight
                .run(() => tryRefreshResult(storage, tokens, serverUrl));
        if (!active || generation != tokens.generation) {
          return handler.next(error);
        }
        if (result == RefreshStatus.success) {
          request.extra['authRetried'] = true;
          try {
            return handler.resolve(await dio.fetch(request));
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        } else if (result == RefreshStatus.rejected) {
          try {
            await ref.read(sessionControllerProvider.notifier).logout();
          } catch (e) {
            AppLogger.warning(
                'No se completó el borrado de sesión: ${e.runtimeType}');
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
