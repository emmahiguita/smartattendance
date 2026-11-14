// QUÉ HACE: Verifica la ruta real de login contra SQLite temporal.
// POR QUÉ: Una migración no debe aceptar contraseñas predeterminadas.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartattendance/core/localstore/local_database_service.dart';
import 'package:smartattendance/features/auth/data/datasources/local_auth_datasource.dart';

void main() {
  late Directory folder;
  late LocalDatabaseService accounts;
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    folder = await Directory.systemTemp.createTemp('legacy-login-');
    await databaseFactory.setDatabasesPath(folder.path);
    accounts = LocalDatabaseService();
  });
  tearDown(() async {
    await (await accounts.database).close();
    await folder.delete(recursive: true);
  });
  test('una cuenta con cédula-clave no acepta claves comunes ni el documento', () async {
    await accounts.insertLocalUser({'cedula': '99887766', 'nombre': 'QA',
      'apellido': 'Legado', 'cargo': 'Administrador', 'is_admin': 1,
      'password_hash': '99887766'});
    final auth = LocalAuthDataSource(accounts);
    for (final password in ['Admin2026*', '123456', '99887766']) {
      await expectLater(auth.loginByCedula('99887766', password: password), throwsFormatException);
    }
    expect((await accounts.getLocalUserByCedula('99887766'))!['password_hash'], '99887766');
  });
}
