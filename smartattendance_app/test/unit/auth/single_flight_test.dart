// Verifica exclusión y liberación real de operaciones asíncronas de renovación.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/network/single_flight.dart';
import 'package:smartattendance/core/auth/token_store.dart';

void main() {
  test('distingue sesiones locales para no renovar una credencial offline', () {
    expect(TokenStore.isLocalToken('local_jwt_identificador'), isTrue);
    expect(TokenStore.isLocalToken('local-offline-token'), isTrue);
    expect(TokenStore.isLocalToken('eyJ.jwt.servidor'), isFalse);
    expect(TokenStore.isLocalToken(null), isFalse);
  });
  test('solicitudes concurrentes comparten una sola renovación', () async {
    final flight = SingleFlight<int>();
    final gate = Completer<int>();
    var calls = 0;
    Future<int> operation() { calls++; return gate.future; }
    final first = flight.run(operation), second = flight.run(operation);
    expect(calls, 1);
    gate.complete(7);
    expect(await Future.wait([first, second]), [7, 7]);
    expect(await flight.run(() async { calls++; return 8; }), 8);
    expect(calls, 2);
  });
  test('una renovación fallida libera el bloqueo para un intento posterior', () async {
    final flight = SingleFlight<int>();
    await expectLater(flight.run(() async => throw StateError('sin red')), throwsStateError);
    expect(await flight.run(() async => 9), 9);
  });
}
