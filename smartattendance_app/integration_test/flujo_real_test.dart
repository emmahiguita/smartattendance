// integration_test/flujo_real_test.dart
//
// Prueba de interacción REAL: ejecuta la app completa contra el backend
// local y verifica que cada pantalla dispara llamadas HTTP reales.
//
// Requiere el backend corriendo en 0.0.0.0:8000 (accesible desde el device).
// Ejecutar (Android físico):
//   flutter test integration_test/flujo_real_test.dart -d <DEVICE> \
//     --dart-define=API_BASE_URL=http://<IP-LAN>:8000/api/v1
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:smartattendance/main.dart' as app;

// Cédula del empleado activo de prueba (NO admin).
const _empleadoCedula = '111222333';

/// Bombea frames hasta que [finder] aparezca, o falla al agotar [timeout].
/// Más robusto que pumpAndSettle: tolera spinners/animaciones infinitas
/// mientras corren llamadas HTTP reales.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail(reason ?? 'Timeout esperando widget: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Flujo real: login -> asistencia -> historial -> perfil -> config -> editar -> logout',
      (tester) async {
    app.main();

    // ── 1. Splash → Login (restore real: sin sesión previa → login)
    await _waitFor(tester, find.text('Cédula de Identidad'),
        timeout: const Duration(seconds: 60));

    // ── 2. Login real contra el backend
    await tester.enterText(find.byType(TextFormField).first, _empleadoCedula);
    await tester.tap(find.text('Iniciar sesión').last);

    await _waitFor(tester, find.textContaining('Marcar '),
        timeout: const Duration(seconds: 60));
    expect(find.text('Inicio'), findsWidgets);

    // ── 3. Resumen del día (datos reales de la API)
    expect(find.text('Estado del día'), findsOneWidget);

    // ── 4. Marcar Asistencia → POST /attendance/ real (tipo decidido por el servidor)
    final markAction = find.textContaining('Marcar ').last;
    await tester.scrollUntilVisible(
      markAction,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final markCard = find
        .ancestor(
          of: markAction,
          matching: find.byType(InkWell),
        )
        .first;
    await tester.tap(markCard);
    await _waitFor(tester, find.text('Confirmación'),
        timeout: const Duration(seconds: 90));
    // 'registrad' cubre 'registrada' y 'registrado' (según el género del tipo).
    expect(find.textContaining('registrad'), findsOneWidget);
    // El tipo (cualquiera de los 4 de la jornada) lo decide el servidor.
    expect(
        find.textContaining('Entrada').evaluate().isNotEmpty ||
            find.textContaining('almuerzo').evaluate().isNotEmpty ||
            find.textContaining('Salida').evaluate().isNotEmpty,
        isTrue,
        reason: 'Debe mostrar el tipo de marca decidido por el servidor');
    // ── 5. Historial → GET /attendance/user/:id real
    await tester.tap(find.text('Continuar'));
    await _waitFor(tester, find.textContaining('Marcar '));
    final historialCard = find.text('Historial');
    await tester.ensureVisible(historialCard);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(historialCard);
    await _waitFor(tester, find.textContaining('Registrada'));
    // Filtro por rango funcional (chips)
    expect(find.text('Mes'), findsOneWidget);
    await tester.tap(find.text('Hoy'));
    await tester.pump(const Duration(milliseconds: 400));

    // ── 6. Perfil: datos reales
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _waitFor(tester, find.text('Perfil'));
    await tester.tap(find.text('Perfil'));
    await _waitFor(tester, find.text(_empleadoCedula),
        reason: 'El perfil debe mostrar la cédula real del usuario');

    // ── 7. Configuración (módulo nuevo)
    await tester.tap(find.widgetWithText(ListTile, 'Configuración'));
    await _waitFor(tester, find.text('Tema'));
    // Tema funcional: cambiar a oscuro y volver a sistema
    await tester.tap(find.text('Oscuro'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Auto'));
    await tester.pump(const Duration(milliseconds: 400));
    // Scroll hasta "Acerca de" (ListView lazy — la versión no existe hasta scroll)
    await tester.scrollUntilVisible(find.text('Versión'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Versión'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _waitFor(tester, find.text('Editar Perfil'));

    // ── 8. Editar perfil → PUT /users/me real, luego restaurar
    await tester.tap(find.widgetWithText(ListTile, 'Editar Perfil'));
    await _waitFor(tester, find.text('GUARDAR CAMBIOS'));

    // Cambiar apellido (segundo campo)
    await tester.enterText(find.byType(TextFormField).at(1), 'Torres');
    await tester.tap(find.text('GUARDAR CAMBIOS'));
    await _waitFor(tester, find.text('Empleado Torres'),
        timeout: const Duration(seconds: 30),
        reason: 'El perfil debe reflejar el apellido guardado en el backend');
    // Esperar a que desaparezca el snackbar (tapa los tiles)
    await tester.pump(const Duration(seconds: 4));

    // Restaurar apellido original (no ensuciar la BD)
    await tester.tap(find.widgetWithText(ListTile, 'Editar Perfil'));
    await _waitFor(tester, find.text('GUARDAR CAMBIOS'));
    await tester.enterText(find.byType(TextFormField).at(1), 'Test');
    await tester.tap(find.text('GUARDAR CAMBIOS'));
    await _waitFor(tester, find.text('Empleado Test'),
        timeout: const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 4));

    // ── 9. Cerrar sesión (perfil → logout)
    // El tile puede estar fuera del viewport → scroll hasta él.
    final logoutTile = find.widgetWithText(ListTile, 'Cerrar Sesión');
    await tester.ensureVisible(logoutTile);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(logoutTile);
    await _waitFor(tester, find.text('Salir'));
    await tester.tap(find.text('Salir'));

    // De vuelta en login (sesión limpiada de verdad)
    await _waitFor(tester, find.text('Cédula de Identidad'),
        timeout: const Duration(seconds: 60));
  });
}
