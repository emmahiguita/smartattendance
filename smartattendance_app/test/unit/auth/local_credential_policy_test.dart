import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/auth/data/datasources/local_auth_datasource.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('rechaza credenciales vacías o iguales al documento', () {
    expect(LocalAuthDataSource.verifyLocalCredential('123456', '', ''), isFalse);
    expect(LocalAuthDataSource.verifyLocalCredential('123456', '123456', '123456'), isFalse);
    expect(LocalAuthDataSource.verifyLocalCredential('123456', '123456', 'otra'), isFalse);
  });
  test('valida únicamente contra credenciales previamente guardadas', () {
    expect(LocalAuthDataSource.verifyLocalCredential('123456', 'clave-segura', 'clave-segura'), isTrue);
    expect(LocalAuthDataSource.verifyLocalCredential('123456', 'incorrecta', 'clave-segura'), isFalse);
    expect(LocalAuthDataSource.verifyLocalCredential('998877', 'incorrecta', '123456'), isFalse);
    expect(LocalAuthDataSource.verifyLocalCredential('998877', 'incorrecta', '998877'), isFalse);
  });
  test('verifica el hash existente sin permitir la cédula como contraseña', () {
    const uuid = Uuid();
    const document = '998877';
    final valid = uuid.v5(Namespace.oid.value, 'pwd:$document:clave-segura');
    final documentHash = uuid.v5(Namespace.oid.value, 'pwd:$document:$document');
    expect(LocalAuthDataSource.verifyLocalCredential(document, 'clave-segura', valid), isTrue);
    expect(LocalAuthDataSource.verifyLocalCredential(document, document, documentHash), isFalse);
  });
}
