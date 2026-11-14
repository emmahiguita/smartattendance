// ============================================================================
// ARCHIVO: crew_members_list_test.dart
// QUÉ HACE: Prueba unitaria y de widget para `CrewMembersList`:
//           - Valida que al proporcionar un `crewId` válido se filtren y muestren
//             únicamente los trabajadores pertenecientes a ese equipo.
//           - Valida el estado visual informativo cuando la cuadrilla no tiene personal.
// CÓMO FUNCIONA: Inyecta `localWorkersProvider` con fixtures simulados y verifica
//                la presencia de textos, avatares y etiquetas de estado.
// POR QUÉ: Asegura la no regresión del requerimiento: "al tocar el equipo debe
//          mostrar el personal del equipo" (< 140 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/photo_attendance/domain/photo_record.dart';
import 'package:smartattendance/features/photo_attendance/presentation/local_providers.dart';
import 'package:smartattendance/features/photo_attendance/presentation/widgets/crew_members_list.dart';

void main() {
  const workerCrew1 = LocalWorker(
    id: 1,
    name: 'Carlos Mendoza',
    document: '2026001005',
    job: 'Operario',
    crewId: 1,
    crewName: 'Equipo Operativo Central',
  );

  const workerCrew2 = LocalWorker(
    id: 2,
    name: 'Juan Perez',
    document: '2026001001',
    job: 'Operario',
    crewId: 2,
    crewName: 'Cuadrilla Norte',
  );

  testWidgets('CrewMembersList despliega los trabajadores de la cuadrilla seleccionada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localWorkersProvider.overrideWith((ref) => Future.value([workerCrew1, workerCrew2])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrewMembersList(crewId: 1),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PERSONAL DEL EQUIPO (1)'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Operario · C.C. 2026001005'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.minus_circle), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);
    // No debe mostrar el trabajador de la cuadrilla 2
    expect(find.text('Juan Perez'), findsNothing);
  });

  testWidgets('CrewMembersList muestra estado vacío cuando el equipo no tiene miembros', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localWorkersProvider.overrideWith((ref) => Future.value([workerCrew1])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrewMembersList(crewId: 99),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PERSONAL DEL EQUIPO (0)'), findsOneWidget);
    expect(find.textContaining('Sin personal adscrito a esta cuadrilla'), findsOneWidget);
  });
}
