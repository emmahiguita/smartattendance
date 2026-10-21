import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/theme/app_theme.dart';
import 'package:smartattendance/features/attendance/presentation/widgets/home_dashboard_body.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';
import 'package:smartattendance/features/photo_attendance/domain/photo_record.dart';
import 'package:smartattendance/features/photo_attendance/presentation/photo_capture_screen.dart';

/// Regresiones de los flujos observados en Android. Flutter permite localizar
/// widgets por tipo/texto; estas pruebas no dependen de coordenadas del teléfono.
void main() {
  const operator = UserEntity(id: 1, nombre: 'Operador de prueba',
    apellido: 'Nombre largo para verificar ajuste', cedula: '999000001',
    correo: '', cargo: 'Encargado local');

  Widget home() => HomeDashboardBody(user: operator, address: 'Sin ubicación',
    coords: 'No disponible', hasFix: false, isLoadingLocation: false,
    onRefreshLocation: () {}, records: const [], nextTipo: 'entrada',
    registering: false, onRegisterAttendance: () {}, onSelectMark: (_) {});

  Future<void> show(WidgetTester tester, Widget child, Size size, double scale) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: AppTheme.lightTheme,
      home: MediaQuery(data: MediaQueryData(size: size,
        textScaler: TextScaler.linear(scale)), child: Scaffold(body: child)))));
    await tester.pump();
  }

  testWidgets('horizontal conserva columnas independientes y acciones visibles', (tester) async {
    await show(tester, home(), const Size(900, 360), 1);
    final left = find.byKey(const PageStorageKey('home-location-wide'));
    final right = find.byKey(const PageStorageKey('home-actions-wide'));
    expect(left, findsOneWidget);
    expect(right, findsOneWidget);
    await tester.drag(left, const Offset(0, -400));
    await tester.pump();
    expect(right, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); // dispose cancela el reloj.
  });

  testWidgets('vertical estrecho con letra grande no desborda tarjetas', (tester) async {
    await show(tester, home(), const Size(320, 640), 1.8);
    expect(find.byKey(const PageStorageKey('home-portrait')), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -900));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no permite guardar una asistencia antes de tomar su foto', (tester) async {
    await show(tester, const PhotoCaptureScreen(worker: LocalWorker(id: 1,
      name: 'Trabajador de prueba', document: '999000001', job: 'Prueba')),
      const Size(360, 740), 1);
    final button = tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
