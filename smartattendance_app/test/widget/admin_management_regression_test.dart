// test/widget/admin_management_regression_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartattendance/features/attendance/presentation/screens/admin_management_screen.dart';
import 'package:smartattendance/features/photo_attendance/presentation/local_providers.dart';
import 'package:smartattendance/features/photo_attendance/domain/photo_record.dart';
import 'package:smartattendance/features/photo_attendance/domain/work_schedule.dart';
import 'package:smartattendance/features/photo_attendance/domain/shift_template.dart';
import 'package:smartattendance/features/photo_attendance/domain/local_actor.dart';

void main() {
  testWidgets(
      'AdminManagementScreen sin overflow a 320x640 con textScaleFactor 1.5',
      (tester) async {
    await initializeDateFormatting('es');
    tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockWorkers = [
      const LocalWorker(
        id: 1,
        name: 'Carlos Mendoza',
        document: '10203040',
        job: 'Operador de Planta',
        schedule: WorkSchedule(
          480,
          true,
          shiftName: 'Turno Mañana',
          startMinute: 360,
          endMinute: 840,
        ),
      ),
      const LocalWorker(
        id: 2,
        name: 'Ana Gómez',
        document: '50607080',
        job: 'Supervisora de Calidad',
      ),
    ];

    final mockTemplates = [
      const ShiftTemplate(
        id: 1,
        name: 'Turno Mañana (06:00 - 14:00)',
        startMinute: 360,
        endMinute: 840,
        dailyMinutes: 480,
      ),
      const ShiftTemplate(
        id: 2,
        name: 'Turno Ordinario (08:00 - 17:00)',
        startMinute: 480,
        endMinute: 1020,
        dailyMinutes: 480,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localWorkersProvider.overrideWith((ref) => Future.value(mockWorkers)),
          localActorProvider.overrideWithValue(
            const LocalActor('1007331963', true, isStrictAdmin: true),
          ),
          shiftTemplatesProvider
              .overrideWith((ref) => Future.value(mockTemplates)),
          allOvertimeDaysProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(1.4),
              size: Size(320, 640),
            ),
            child: Scaffold(body: AdminManagementScreen()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Equipos'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Horarios'), findsOneWidget);
    expect(find.text('Extras'), findsOneWidget);
    // Hacer scroll hasta el selector para tocar Horarios.
    await tester.ensureVisible(find.text('Horarios'));
    await tester.pumpAndSettle();

    // Cambiar a pestaña Horarios.
    await tester.tap(find.text('Horarios'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('PLANTILLAS DE HORARIO'), findsOneWidget);

    // Cambiar a pestaña Extras
    await tester.tap(find.text('Extras'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Volver a la pestaña Equipos.
    await tester.tap(find.text('Equipos'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
