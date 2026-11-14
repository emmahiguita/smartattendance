// QUÉ HACE: Protege contraseñas locales individuales con sal aleatoria.
// CÓMO: PBKDF2-HMAC-SHA256 en un isolate, sin guardar ni registrar la clave.
// POR QUÉ: Un documento público o una clave compartida no activa una cuenta.
import 'dart:convert';
import 'dart:isolate';
import 'package:cryptography/cryptography.dart';

abstract final class LocalPassword {
  static const _iterations = 600000;

  static Future<String> hash(String password) => Isolate.run(() async {
    final salt = SecretKeyData.random(length: 16).bytes;
    final algorithm = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _iterations, bits: 256);
    final key = await algorithm.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return 'pbkdf2-sha256\$$_iterations\$${base64Encode(salt)}\$${base64Encode(await key.extractBytes())}';
  });

  static Future<bool> verify(String password, String stored) => Isolate.run(() async {
    try {
      final fields = stored.split('\$');
      if (fields.length != 4 || fields[0] != 'pbkdf2-sha256') return false;
      final iterations = int.parse(fields[1]);
      if (iterations < 100000 || iterations > 1000000) return false;
      final expected = base64Decode(fields[3]), salt = base64Decode(fields[2]);
      if (expected.length != 32 || salt.length != 16) return false;
      final algorithm = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
      final actual = await (await algorithm.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt)).extractBytes();
      var difference = 0;
      for (var i = 0; i < expected.length; i++) { difference |= expected[i] ^ actual[i]; }
      return difference == 0;
    } catch (_) { return false; }
  });
}
