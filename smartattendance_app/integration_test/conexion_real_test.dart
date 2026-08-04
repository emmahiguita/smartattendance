// integration_test/conexion_real_test.dart
// Prueba automatizada de conexión REAL contra el backend.
// Verifica el flujo completo: login → home (datos reales) → asistencia hoy.
//
// Requisitos:
//   1. Backend corriendo en 127.0.0.1:8000 (adb reverse tcp:8000 tcp:8000)
//   2. Empleado admin con cédula 1007331963 sin contraseña
//   3. Dispositivo Android conectado con depuración USB
//
// Ejecutar:
//   flutter test integration_test/conexion_real_test.dart -d <DEVICE>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:smartattendance/main.dart' as app;

const _cedula = '1007331963';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prueba de conexión REAL end-to-end', () {
    testWidgets('Flujo completo: login → home → datos reales', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // ── 1. Verificar dónde aterrizamos (login o home con sesión) ──
      final isHome =
          find.text('UBICACIÓN GPS EN TIEMPO REAL').evaluate().isNotEmpty;

      if (!isHome) {
        // Login: cédula vacía (sin datos de demo).
        final cedulaField = find.byType(TextFormField).first;
        await tester.enterText(cedulaField, _cedula);
        await tester.pumpAndSettle();

        // Tocar "Iniciar sesión".
        final loginBtn = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
        await tester.tap(loginBtn);
        await tester.pumpAndSettle(const Duration(seconds: 8));
      }

      // ── 2. Verificar que estamos en home con datos reales ──
      expect(find.text('UBICACIÓN GPS EN TIEMPO REAL'), findsOneWidget,
          reason: 'La card GPS debe estar presente en el home');
      expect(find.textContaining('Emmanuel'), findsOneWidget,
          reason: 'Debe mostrar el nombre real desde la API');
      expect(find.text('Estado del día'), findsOneWidget,
          reason: 'El resumen de jornada debe cargarse de la API');

      // ── 3. Navegar a "Asistencia Hoy" ──
      await tester.scrollUntilVisible(find.text('Asistencia Hoy'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Asistencia Hoy'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── 4. Verificar pantalla de empleados (datos reales del backend) ──
      expect(find.text('Llegadas tarde'), findsOneWidget,
          reason: 'Encabezado de tardanza con datos reales');
      expect(find.text('Pendientes'), findsOneWidget,
          reason: 'Encabezado de sin marcar con datos reales');
      expect(find.text('A tiempo'), findsOneWidget,
          reason: 'Encabezado de a tiempo con datos reales');

      // KPIs con números reales (> 0 empleados en la BD).
      final kpiVals = find.text('6');
      expect(kpiVals.evaluate().isNotEmpty, isTrue,
          reason: 'Debe haber al menos 6 empleados (dato real del backend)');

      // Chips de área con datos reales.
      expect(find.text('Administrador'), findsOneWidget,
          reason: 'El chip de área Administrador debe aparecer');

      // ── 5. Verificar que los nombres de empleados son reales ──
      expect(find.textContaining('Emmanuel'), findsAtLeast(1),
          reason:
              'Emmanuel debe aparecer en la lista de empleados (dato real)');
    });
  });
}
