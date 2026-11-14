// QUÉ HACE: Comprueba restauración de sesión sin depender de un teléfono.
// CÓMO: Usa el adaptador de pruebas oficial del almacén seguro; no prueba
// Keystore/Keychain ni sustituye la prueba real de inicio de sesión.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/auth/session_controller.dart';
import 'package:smartattendance/core/auth/token_store.dart';
import 'package:smartattendance/core/config/app_config.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const user = UserEntity(id: 1, nombre: 'QA', apellido: 'Sesión',
      cedula: 'QA-SESSION', correo: '', cargo: 'Supervisor');

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('perfil guardado sin credencial no restaura una sesión', () async {
    final original = SessionController(storage, TokenStore());
    await original.authenticate(user);
    final restarted = SessionController(storage, TokenStore());
    await restarted.restore();
    expect(restarted.state, isA<SessionUnauthenticated>());
    expect(await storage.read(key: AppConfig.keyUserJson), isNull);
    original.dispose(); restarted.dispose();
  });

  test('no recordar sesión exige autenticarse al reiniciar', () async {
    final tokens = TokenStore();
    final original = SessionController(storage, tokens);
    original.setEphemeralTokens(accessToken: 'local_jwt_QA');
    await original.authenticate(user, remember: false);
    expect(original.state, isA<SessionAuthenticated>());
    expect(tokens.accessToken, 'local_jwt_QA');
    final restarted = SessionController(storage, TokenStore());
    await restarted.restore();
    expect(restarted.state, isA<SessionUnauthenticated>());
    original.dispose(); restarted.dispose();
  });

  test('perfil con credencial local recordada permite restaurar', () async {
    final original = SessionController(storage, TokenStore());
    await original.authenticate(user);
    await storage.write(key: AppConfig.keyAccessToken, value: 'local_jwt_QA');
    final tokens = TokenStore();
    final restarted = SessionController(storage, tokens);
    await restarted.restore();
    expect(restarted.state, isA<SessionAuthenticated>());
    expect(tokens.accessToken, 'local_jwt_QA');
    original.dispose(); restarted.dispose();
  });
}
