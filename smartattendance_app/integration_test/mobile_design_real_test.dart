import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartattendance/main.dart' as app;

const employeeCedula = '111222333';

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timeout esperando $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('APK móvil real: login, inicio responsive y mensajería',
      (tester) async {
    app.main();
    await waitFor(tester, find.text('Cédula de Identidad'));

    await tester.enterText(find.byType(TextFormField).first, employeeCedula);
    tester.binding.focusManager.primaryFocus?.unfocus();
    final loginButton = find.text('Iniciar sesión').last;
    await tester.scrollUntilVisible(
      loginButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(loginButton);
    await waitFor(tester, find.text('Estado del día'));

    expect(find.text('Inicio'), findsWidgets);
    expect(tester.takeException(), isNull);

    final messagesLabel = find.text('Mensajería interna');
    await tester.scrollUntilVisible(
      messagesLabel,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(messagesLabel, findsOneWidget);
    expect(tester.takeException(), isNull);

    final messagesCard =
        find.ancestor(of: messagesLabel, matching: find.byType(InkWell)).first;
    await tester.tap(messagesCard);
    await waitFor(tester, find.text('Comunicación segura del equipo'));
    expect(find.text('Mensajería interna'), findsAtLeast(1));
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await waitFor(tester, find.text('Estado del día'));
    expect(tester.takeException(), isNull);
  });
}
