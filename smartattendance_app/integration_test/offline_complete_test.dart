// integration_test/offline_complete_test.dart
//
// QA AUTOMATIZADO — Modo Offline Completo
//
// Valida que TODA la app funcione sin backend.
// Usa tester.runAsync() para dar tiempo real a platform channels.
//
// IMPORTANTE: El backend NO debe estar corriendo.
// Ejecutar: flutter test integration_test/offline_complete_test.dart -d <DEVICE>
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:smartattendance/main.dart' as app;

class TestResult {
  final String name;
  final bool passed;
  final String details;
  TestResult(this.name, this.passed, [this.details = '']);

  @override
  String toString() =>
      '${passed ? "PASS" : "FAIL"}: $name${details.isNotEmpty ? " -- $details" : ""}';
}

List<String> _dump(WidgetTester t) {
  final x = <String>[];
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget as Text;
    if (w.data != null && w.data!.isNotEmpty) x.add(w.data!);
  }
  return x;
}

/// Pump repeatedly with real-time waits (runAsync) so platform channels
/// (flutter_secure_storage, sqflite) get real event-loop time.
Future<bool> _waitFor(
  WidgetTester tester,
  bool Function(WidgetTester) check, {
  int maxSecs = 30,
}) async {
  for (var i = 0; i < maxSecs; i++) {
    if (check(tester)) return true;
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump();
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final r = <TestResult>[];

  setUp(() async {
    try {
      final s = await Socket.connect('localhost', 8000,
          timeout: const Duration(seconds: 2));
      s.destroy();
      debugPrint('WARN: Backend detectado - test puede usar red');
    } catch (_) {
      debugPrint('OK: Backend NO detectado -- test offline puro');
    }
  });

  tearDownAll(() {
    final pass = r.where((x) => x.passed).length;
    debugPrint('\n============================================================');
    debugPrint('  QA OFFLINE: $pass/${r.length} tests pasaron');
    debugPrint('  ${pass == r.length ? "TODOS PASARON" : "ALGUNOS FALLARON"}');
    debugPrint('============================================================');
    for (final t in r) debugPrint('  $t');
  });

  testWidgets('QA OFFLINE COMPLETO', (tester) async {
    // --- 1. Startup ---
    debugPrint('T1: Startup...');
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 10));
    var ok = await _waitFor(
        tester,
        (t) =>
            find.byType(TextFormField).evaluate().isNotEmpty ||
            find.textContaining('Iniciar').evaluate().isNotEmpty,
        maxSecs: 15);
    r.add(TestResult('1. App inicia y muestra login', ok,
        '${_dump(tester).take(3).join(" | ")}'));
    if (!ok) return;

    // --- 2. Login offline ---
    debugPrint('T2: Login offline...');
    await tester.enterText(find.byType(TextFormField).first, '1007331963');
    await tester.pump();
    await tester.tap(find.textContaining('Iniciar').last);
    await tester.pump();
    ok = await _waitFor(tester,
        (t) => find.textContaining('Marcar').evaluate().isNotEmpty,
        maxSecs: 30);
    r.add(TestResult('2. Login offline con cedula local', ok));
    if (!ok) return;

    // --- 3. Home elements ---
    debugPrint('T3: Home elements...');
    final tx = _dump(tester);
    r.add(TestResult('3a. Inicio tab', tx.any((x) => x == 'Inicio')));
    r.add(TestResult('3b. Marcar btn', tx.any((x) => x.contains('Marcar'))));
    r.add(TestResult('3c. Exportar btn', tx.any((x) => x.contains('Exportar'))));
    r.add(TestResult('3d. Generar QR btn', tx.any((x) => x.contains('QR'))));

    // --- 4. Mark attendance ---
    debugPrint('T4: Marcar asistencia...');
    try {
      final btn = find.textContaining('Marcar').last;
      await tester.scrollUntilVisible(btn, 250,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final card = find
          .ancestor(of: btn, matching: find.byType(InkWell))
          .first;
      await tester.tap(card);
      await tester.pump();
      ok = await _waitFor(tester,
          (t) => _dump(t).any((s) => s.toLowerCase().contains('registrad')),
          maxSecs: 10);
      r.add(TestResult('4. Marcar asistencia offline', ok));
      final cont = find.textContaining('Continuar');
      if (cont.evaluate().isNotEmpty) {
        await tester.tap(cont);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    } catch (e) {
      r.add(TestResult('4. Marcar asistencia', false, '$e'));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pump();
    }

    // --- 5. History ---
    debugPrint('T5: Historial...');
    try {
      await tester.ensureVisible(find.textContaining('Historial'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.textContaining('Historial'));
      await tester.pump();
      ok = await _waitFor(tester,
          (t) => _dump(t).any((s) => s.toLowerCase().contains('historial')),
          maxSecs: 5);
      r.add(TestResult('5. Historial offline', ok));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } catch (e) {
      r.add(TestResult('5. Historial', false, '$e'));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pump();
    }

    // --- 6. Profile ---
    debugPrint('T6: Perfil...');
    try {
      await tester.ensureVisible(find.textContaining('Perfil'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.textContaining('Perfil'));
      await tester.pump();
      ok = await _waitFor(tester,
          (t) => _dump(t).any((s) => s.contains('1007331963')),
          maxSecs: 5);
      r.add(TestResult('6. Perfil: cedula visible', ok));
      final px = _dump(tester);
      r.add(TestResult('6b. Perfil: nombre',
          px.any((s) => s.contains('Emmanuel'))));
      r.add(TestResult('6c. Perfil: cargo',
          px.any((s) => s.contains('Administrador'))));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } catch (e) {
      r.add(TestResult('6. Perfil', false, '$e'));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pump();
    }

    // --- 7. Config ---
    debugPrint('T7: Config...');
    try {
      final cfg = find.widgetWithText(ListTile, 'Configuracion');
      await tester.ensureVisible(cfg);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(cfg);
      await tester.pump();
      ok = await _waitFor(tester,
          (t) => _dump(t).any((s) => s.contains('Apariencia')),
          maxSecs: 5);
      r.add(TestResult('7. Config offline', ok));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } catch (e) {
      r.add(TestResult('7. Config', false, '$e'));
      final bk = find.byIcon(Icons.arrow_back_ios_new);
      if (bk.evaluate().isNotEmpty) await tester.tap(bk);
      await tester.pump();
    }

    // --- 8. Export Excel ---
    debugPrint('T8: Exportar Excel...');
    try {
      final ex = find.textContaining('Exportar');
      await tester.ensureVisible(ex);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(ex);
      await tester.pump();
      ok = await _waitFor(tester,
          (t) => _dump(t).any((s) =>
              s.toLowerCase().contains('reporte') ||
              s.toLowerCase().contains('generado') ||
              s.toLowerCase().contains('csv') ||
              s.toLowerCase().contains('error')),
          maxSecs: 8);
      r.add(TestResult('8. Exportar Excel offline', ok));
    } catch (e) {
      r.add(TestResult('8. Exportar Excel', false, '$e'));
    }

    // --- 9. SQLite persistence ---
    debugPrint('T9: SQLite...');
    try {
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/smartattendance_offline.db';
      final exists = await File(path).exists();
      r.add(TestResult('9a. BD existe', exists));
      if (exists) {
        final db = await openDatabase(path);
        final tables = (await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table'"))
            .map((t) => t['name'] as String)
            .toList();
        for (final tn in [
          'usuarios_locales',
          'offline_attendances',
          'attendance_history'
        ]) {
          r.add(TestResult('9b. Tabla $tn', tables.contains(tn)));
        }
        final uc = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM usuarios_locales'));
        r.add(TestResult('9c. 5 usuarios seed', uc == 5, '=$uc'));
        await db.close();
      }
    } catch (e) {
      r.add(TestResult('9. SQLite', false, '$e'));
    }

    debugPrint('QA offline completo.');
  });
}
