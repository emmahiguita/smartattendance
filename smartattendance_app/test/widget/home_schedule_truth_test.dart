import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/attendance/presentation/widgets/home_schedule_card.dart';

void main() {
  testWidgets('sin horario asignado no inventa una jornada', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HomeScheduleCard(schedule: null))));
    expect(find.text('Sin horario asignado'), findsOneWidget);
    expect(find.textContaining('Turno Operativo'), findsNothing);
    expect(find.textContaining('08:00'), findsNothing);
  });
}
