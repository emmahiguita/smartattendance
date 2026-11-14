// QUÉ HACE: Reproduce límites de autenticación con HTTP y SQLite locales.
// CÓMO: El adaptador de SecureStorage permite detener una escritura sin esperar
// por tiempos del dispositivo. No representa una prueba de Keystore/Keychain.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/auth/session_controller.dart';
import 'package:smartattendance/core/auth/token_store.dart';
import 'package:smartattendance/core/config/app_config.dart';
import 'package:smartattendance/core/exceptions/app_exception.dart';
import 'package:smartattendance/core/localstore/local_database_service.dart';
import 'package:smartattendance/core/network/token_refresh.dart';
import 'package:smartattendance/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smartattendance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class _RealHttp extends HttpOverrides {}

// Controla el instante de escritura usando el almacén oficial de pruebas.
class _PausedStorage extends FlutterSecureStorage {
  final writing = Completer<void>();
  final resume = Completer<void>();

  @override
  Future<void> write({required String key, required String? value,
      IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions,
      WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (key == AppConfig.keyAccessToken && value == 'rotated-access') {
      writing.complete();
      await resume.future;
    }
    await super.write(key: key, value: value, iOptions: iOptions,
        aOptions: aOptions, lOptions: lOptions, webOptions: webOptions,
        mOptions: mOptions, wOptions: wOptions);
  }
}

Future<HttpServer> _serve(int status, Map<String, String> response, {void Function()? received}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    received?.call();
    await request.drain<void>();
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response));
    await request.response.close();
  });
  return server;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('cerrar sesión durante una escritura impide recuperar tokens', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final server = await _serve(200, {'access_token': 'rotated-access',
        'refresh_token': 'rotated-refresh'});
      addTearDown(() => server.close(force: true));
      final storage = _PausedStorage();
      final tokens = TokenStore()..accessToken = 'old-access'
        ..refreshToken = 'old-refresh'..serverUrl = 'http://127.0.0.1:${server.port}';
      final session = SessionController(storage, tokens);
      addTearDown(session.dispose);
      await storage.write(key: AppConfig.keyRefreshToken, value: 'old-refresh');
      final renewal = tryRefreshResult(storage, tokens, 'http://127.0.0.1:${server.port}');
      await storage.writing.future.timeout(const Duration(seconds: 5));
      final logout = session.logout();
      storage.resume.complete();
      await logout;
      await renewal;
      expect(tokens.accessToken, isNull);
      expect(tokens.refreshToken, isNull);
      expect(await storage.read(key: AppConfig.keyAccessToken), isNull);
      expect(await storage.read(key: AppConfig.keyRefreshToken), isNull);
    }, _RealHttp());
  });

  test('una renovación no entrega el refresco a otro servidor', () async {
    var requests = 0;
    final server = await _serve(401, {}, received: () => requests++);
    addTearDown(() => server.close(force: true));
    final tokens = TokenStore()..accessToken = 'access'
      ..refreshToken = 'refresh'..serverUrl = 'https://emisor.example/api/v1';
    final result = await HttpOverrides.runWithHttpOverrides(() => tryRefreshResult(
        const FlutterSecureStorage(), tokens, 'http://127.0.0.1:${server.port}'), _RealHttp());
    expect(result, RefreshStatus.superseded);
    expect(requests, 0);
    expect(tokens.refreshToken, 'refresh');
  });

  test('HTTP 503 durante la renovación conserva las credenciales', () async {
    final server = await _serve(503, {});
    addTearDown(() => server.close(force: true));
    final url = 'http://127.0.0.1:${server.port}';
    final tokens = TokenStore()..accessToken = 'access'
      ..refreshToken = 'refresh'..serverUrl = url;
    final result = await HttpOverrides.runWithHttpOverrides(() => tryRefreshResult(
        const FlutterSecureStorage(), tokens, url), _RealHttp());
    expect(result, RefreshStatus.networkError);
    expect(tokens.accessToken, 'access');
    expect(tokens.refreshToken, 'refresh');
  });

  for (final status in [401, 403, 429]) {
    test('HTTP $status no admite una contraseña local anterior', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final server = await _serve(status, {'detail': 'Acceso rechazado'});
        addTearDown(() => server.close(force: true));
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        final directory = await Directory.systemTemp.createTemp('attendance-auth-');
        await databaseFactory.setDatabasesPath(directory.path);
        final database = LocalDatabaseService();
        addTearDown(() async {
          await (await database.database).close();
          await directory.delete(recursive: true);
        });
        const document = '910000010', password = 'AnteriorSegura9';
        await database.insertLocalUser({'cedula': document, 'nombre': 'QA',
          'apellido': 'Acceso', 'cargo': 'Supervisor', 'is_admin': 0,
          'password_hash': const Uuid().v5(Namespace.oid.value, 'pwd:$document:$password')});
        final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}'));
        addTearDown(() => dio.close(force: true));
        const storage = FlutterSecureStorage();
        final repo = AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource(dio),
            storage: storage, localDb: database, tokens: TokenStore());
        await expectLater(repo.loginByCedula(document, password: password),
            throwsA(isA<AppException>()));
        expect(await storage.read(key: AppConfig.keyAccessToken), isNull);
        final local = await repo.loginByCedula(document, password: password, isOffline: true);
        expect(TokenStore.isLocalToken(local.$1), isTrue);
      }, _RealHttp());
    });
  }
}
