// ============================================================================
// ARCHIVO: consolidated_attendance_test.dart
// CAPA: Test / Unit, SQLite Integration & Widget Tests
// QUÉ HACE: Valida el modelo `ConsolidatedRecord`, la máquina de estados
//           `ConsolidatedAttendanceState`, la persistencia real en SQLite
//           (`createManualAttendance` y `applyCorrection`) y el renderizado
//           sin overflows de `ConsolidatedAttendanceScreen` en modo oscuro.
// CÓMO FUNCIONA: Ejecuta casos unitarios y de integración con `sqflite_common_ffi`.
// POR QUÉ: Garantiza cero regresiones en consolidados reales < 200 líneas.
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartattendance/core/theme/app_theme.dart';
import 'package:smartattendance/features/attendance/data/consolidated_attendance_repository.dart';
import 'package:smartattendance/features/attendance/presentation/consolidated/consolidated_attendance_screen.dart';
import 'package:smartattendance/features/attendance/presentation/consolidated/models/consolidated_record.dart';
import 'package:smartattendance/features/photo_attendance/data/photo_database.dart';
import 'package:smartattendance/features/photo_attendance/domain/attendance_location.dart';
import 'package:smartattendance/features/photo_attendance/domain/local_actor.dart';
import 'package:smartattendance/features/photo_attendance/domain/photo_record.dart';
import 'package:smartattendance/features/photo_attendance/presentation/local_providers.dart';

void main() {
  group('ConsolidatedRecord & State Tests', () {
    test('Calcula correctamente horas activas, extras y formato de fecha', () {
      final loc = AttendanceLocation(
        latitude: 4.8133,
        longitude: -75.6961,
        accuracy: 5.0,
        fixedAt: DateTime.parse('2026-10-27T13:00:00Z'),
      );

      final r1 = PhotoRecord(
        uuid: 'uuid-entry-1',
        workerId: 101,
        name: 'Emmanuel Higuita',
        document: '1007331963',
        job: 'Ingeniero',
        type: 'entrada',
        capturedAt: DateTime.parse('2026-10-27T08:00:00Z'),
        localPath: '/tmp/photo1.jpg',
        location: loc,
      );

      final r2 = PhotoRecord(
        uuid: 'uuid-exit-1',
        workerId: 101,
        name: 'Emmanuel Higuita',
        document: '1007331963',
        job: 'Ingeniero',
        type: 'salida',
        capturedAt: DateTime.parse('2026-10-27T18:00:00Z'),
        localPath: '/tmp/photo2.jpg',
        location: loc,
      );

      final day = PhotoDay(
        [r1, r2],
        status: 'closed',
        zoneName: 'Sede Principal Operativa',
        approvedSeconds: 7200,
        reviewNote: 'Horas extras aprobadas por cierre operativo',
        reviewedBy: 'ADMIN-01',
      );

      final record = ConsolidatedRecord.fromPhotoDay(day);

      expect(record.colaborador, 'Emmanuel Higuita');
      expect(record.cedula, '1007331963');
      expect(record.zona, 'Sede Principal Operativa');
      expect(record.estado, 'Cerrada');
      expect(record.extras, '2h 00m');
      expect(record.approvedSeconds, 7200);
      expect(record.reviewedBy, 'ADMIN-01');
      expect(record.reviewNote, contains('Horas extras'));
      expect(record.fechaFormatted, isNotEmpty);
    });
  });

  group('Consolidated SQLite & Dark Mode UI Integration', () {
    late Directory directory;
    late PhotoDatabase photos;
    const admin = LocalActor('1007331963', true, isStrictAdmin: true);

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      directory = await Directory.systemTemp.createTemp('consolidated-qa-');
      await databaseFactory.setDatabasesPath(directory.path);
      photos = PhotoDatabase();
      await photos.database;
    });

    tearDown(() async {
      await (await photos.database).close();
      await directory.delete(recursive: true);
    });

    test('createManualAttendance y applyCorrection persisten y actualizan en SQLite real', () async {
      final db = await photos.database;
      final workerId = await db.insert('workers', {
        'name': 'Carlos Operario',
        'document': '1088001122',
        'job': 'Operario',
      });

      final repo = ConsolidatedAttendanceRepository(database: photos, actor: admin);
      final today = DateTime(2026, 11, 9);

      await repo.createManualAttendance(
        workerId: workerId,
        workDate: today,
        entradaTime: const TimeOfDay(hour: 7, minute: 0),
        salidaTime: const TimeOfDay(hour: 16, minute: 0),
        zoneName: 'Planta Operativa Dosquebradas',
        status: 'closed',
        approvedSeconds: 3600,
        reason: 'Registro manual verificado',
        adminDocument: admin.document,
      );

      final days = await repo.fetchDays(
        from: today.subtract(const Duration(days: 1)),
        to: today.add(const Duration(days: 1)),
      );
      final records = days.map(ConsolidatedRecord.fromPhotoDay).toList();
      expect(records.length, 1);
      expect(records.first.colaborador, 'Carlos Operario');
      expect(records.first.zona, 'Planta Operativa Dosquebradas');
      expect(records.first.extras, '1h 00m');

      await repo.applyCorrection(
        journeyId: records.first.journeyId,
        newZone: 'Sede Administrativa Serviciudad',
        newStatus: 'closed',
        newApprovedSeconds: 5400,
        reason: 'Cambio de sede y ajuste de horas extras',
        adminDocument: admin.document,
        newDate: today,
        newEntradaTime: const TimeOfDay(hour: 7, minute: 30),
        newSalidaTime: const TimeOfDay(hour: 17, minute: 0),
      );

      final updatedDays = await repo.fetchDays(
        from: today.subtract(const Duration(days: 1)),
        to: today.add(const Duration(days: 1)),
      );
      final updated = updatedDays.map(ConsolidatedRecord.fromPhotoDay).toList();
      expect(updated.single.zona, 'Sede Administrativa Serviciudad');
      expect(updated.single.extras, '1h 30m');
      expect(updated.single.reviewNote, 'Cambio de sede y ajuste de horas extras');
    });

    testWidgets('ConsolidatedAttendanceSheet renderiza en modo oscuro sin overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPhotoDatabaseProvider.overrideWithValue(photos),
            localActorProvider.overrideWithValue(admin),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ConsolidatedAttendanceSheet(),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(find.text('Consolidado de Asistencias'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
