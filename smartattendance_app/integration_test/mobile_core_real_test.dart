import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartattendance/main.dart' as app;

const adminCedula = '1007331963';

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

Future<void> tapHomeCard(WidgetTester tester, String label) async {
  final text = find.text(label);
  await tester.scrollUntilVisible(
    text,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 700));
  final card = find.ancestor(of: text, matching: find.byType(InkWell)).first;
  await tester.tap(card);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lógica móvil real: asistencia de hoy y mensajería',
      (tester) async {
    app.main();
    await waitFor(tester, find.text('Cédula de Identidad'));

    await tester.enterText(find.byType(TextFormField).first, adminCedula);
    tester.binding.focusManager.primaryFocus?.unfocus();
    final login = find.text('Iniciar sesión').last;
    await tester.scrollUntilVisible(
      login,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(login);
    await waitFor(tester, find.text('Estado del día'));
    expect(tester.takeException(), isNull);

    await tapHomeCard(tester, 'Asistencia de hoy');
    await waitFor(tester, find.text('Empleados'));
    expect(find.text('A tiempo'), findsWidgets);
    expect(find.text('Con retraso'), findsOneWidget);
    expect(find.text('Pendientes'), findsWidgets);
    expect(find.textContaining('Empleado'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await waitFor(tester, find.text('Estado del día'));

    await tapHomeCard(tester, 'Mensajería interna');
    await waitFor(tester, find.text('Buscar empleado o cargo'));
    expect(find.text('Empleado Test'), findsOneWidget);
    await tester.tap(find.text('Empleado Test'));
    await waitFor(tester, find.text('Escribe un mensaje profesional…'));

    final message = 'Validación móvil ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(find.byType(TextField).last, message);
    await tester.tap(find.byIcon(Icons.send_rounded));
    await waitFor(tester, find.text(message));
    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await waitFor(tester, find.text('Estado del día'));
    expect(tester.takeException(), isNull);
  });
}
