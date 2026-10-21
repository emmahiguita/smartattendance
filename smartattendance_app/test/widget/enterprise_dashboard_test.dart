import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/theme/app_theme.dart';
import 'package:smartattendance/features/attendance/presentation/widgets/attendance_kpi_grid.dart';
import 'package:smartattendance/features/attendance/presentation/widgets/dashboard_staff_status.dart';
import 'package:smartattendance/features/photo_attendance/domain/photo_record.dart';
import 'package:smartattendance/features/photo_attendance/domain/work_schedule.dart';
import 'package:smartattendance/features/photo_attendance/presentation/local_providers.dart';

void main() {
  final today = ColombiaClock.day(DateTime.now());
  final yesterday = ColombiaClock.day(DateTime.now().subtract(const Duration(days: 1)));
  final sampleWorkers = [
    LocalWorker(
      id: 1,
      name: 'Emmanuel Higuita',
      document: '1007331963',
      job: 'Principal Engineer',
      lastMark: 'entrada',
      lastWorkDate: today,
      lastJourneyStatus: 'open',
    ),
    LocalWorker(
      id: 2,
      name: 'Valeria Gomez',
      document: '1098765432',
      job: 'Product Design Lead',
      lastMark: 'salida',
      lastWorkDate: today,
      lastJourneyStatus: 'closed',
    ),
    LocalWorker(
      id: 3,
      name: 'Carlos Ruiz',
      document: '1012345678',
      job: 'Operador de Planta',
      lastMark: null,
      lastWorkDate: yesterday,
      lastJourneyStatus: 'closed',
    ),
  ];

  Widget buildScope({required Widget child, bool isDark = false}) {
    return ProviderScope(
      overrides: [
        localWorkersProvider.overrideWith((ref) => Future.value(sampleWorkers)),
      ],
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('Enterprise Dashboard - AttendanceKpiGrid', () {
    testWidgets('Muestra las 4 tarjetas de métricas reales calculadas desde SQLite', (tester) async {
      await tester.pumpWidget(buildScope(child: const AttendanceKpiGrid()));
      await tester.pumpAndSettle();

      expect(find.text('Empleados activos'), findsOneWidget);
      expect(find.text('En jornada'), findsOneWidget);
      expect(find.text('Sin entrada'), findsOneWidget);
      expect(find.text('Jornadas cerradas'), findsOneWidget);

      // Verificamos que los números reales coincidan con los datos de muestra
      expect(find.text('3'), findsOneWidget); // total activos
    });
  });

  group('Enterprise Dashboard - DashboardStaffStatus', () {
    testWidgets('Filtra trabajadores en vivo por búsqueda de texto y chip', (tester) async {
      await tester.pumpWidget(
        buildScope(
          child: DashboardStaffStatus(onOpenAll: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estado del personal'), findsOneWidget);
      expect(find.text('Emmanuel Higuita'), findsOneWidget);
      expect(find.text('Valeria Gomez'), findsOneWidget);
      expect(find.text('Carlos Ruiz'), findsOneWidget);

      // Escribir en la barra de búsqueda
      await tester.enterText(find.byType(TextField), 'Emmanuel');
      await tester.pumpAndSettle();

      expect(find.text('Emmanuel Higuita'), findsOneWidget);
      expect(find.text('Valeria Gomez'), findsNothing);
      expect(find.text('Carlos Ruiz'), findsNothing);

      // Limpiar búsqueda
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Valeria Gomez'), findsOneWidget);

      // Filtrar por chip "Jornada cerrada"
      await tester.tap(find.text('Jornada cerrada').first);
      await tester.pumpAndSettle();

      expect(find.text('Valeria Gomez'), findsOneWidget);
      expect(find.text('Carlos Ruiz'), findsNothing);
    });

    testWidgets('Tocar un trabajador abre la credencial 3D con diferenciación de estados', (tester) async {
      await tester.pumpWidget(
        buildScope(
          child: DashboardStaffStatus(onOpenAll: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Tocar en la fila de Emmanuel Higuita
      await tester.tap(find.text('Emmanuel Higuita'));
      await tester.pumpAndSettle();

      // Se abre el modal con la credencial digital
      expect(find.text('CREDENCIAL DIGITAL DE ASISTENCIA'), findsOneWidget);
      expect(find.text('EMPLEADO ACTIVO'), findsOneWidget);
      expect(find.text('Estado laboral (Contrato)'), findsOneWidget);
      expect(find.text('Estado de asistencia hoy'), findsOneWidget);
    });
  });
}
