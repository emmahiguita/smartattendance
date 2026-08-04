import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/attendance/data/models/today_employee_status.dart';

void main() {
  final emps = [
    const TodayEmployeeStatus(id: 1, nombre: 'Emmanuel', apellido: 'Admin', cedula: '100', cargo: 'Administrador', estado: 'tarde', horaEntrada: '22:06:26', minutosTarde: 816),
    const TodayEmployeeStatus(id: 2, nombre: 'Valeria Andrea', apellido: 'Gomez Restrepo', cedula: '200', cargo: 'Disenadora UX Senior', estado: 'tarde', horaEntrada: '08:45:00', minutosTarde: 15),
    const TodayEmployeeStatus(id: 3, nombre: 'Juan Carlos', apellido: 'Perez Lopez', cedula: '300', cargo: 'Desarrollador Senior', estado: 'a_tiempo', horaEntrada: '08:05:00', minutosTarde: 0),
    const TodayEmployeeStatus(id: 4, nombre: 'Maria', apellido: 'Garcia', cedula: '400', cargo: 'Analista de Datos', estado: 'sin_marcar', horaEntrada: null, minutosTarde: 0),
  ];

  testWidgets('EmployeeRow sin overlap a 360dp con nombres largos', (tester) async {
    await tester.pumpWidget(wrap(360, emps));
    expect(tester.takeException(), isNull, reason: 'Overflow en fila a 360dp');
  });

  testWidgets('EmployeeRow sin overlap a 280dp', (tester) async {
    await tester.pumpWidget(wrap(280, emps));
    expect(tester.takeException(), isNull, reason: 'Overflow en fila a 280dp');
  });
}

Widget wrap(double width, List<TodayEmployeeStatus> emps) => MediaQuery(
  data: MediaQueryData(size: Size(width, 900), alwaysUse24HourFormat: true),
  child: MaterialApp(home: Scaffold(body: SizedBox(width: width, child: ListView(children: emps.map((e) => _Row(e: e)).toList())))),
);

class _Row extends StatelessWidget {
  final TodayEmployeeStatus e;
  const _Row({required this.e});

  @override
  Widget build(BuildContext context) {
    final color = switch (e.estado) {'tarde' => const Color(0xFFF59E0B), 'sin_marcar' => const Color(0xFF64748B), _ => const Color(0xFF22C55E)};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: 0.15), child: Text(e.initials.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(e.cargo ?? '', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (e.horaEntrada != null) ...[
            Text(e.horaEntrada!.substring(0, 5), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
          ],
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(e.estado == 'tarde' ? '+${e.minutosTarde} min' : (e.estado == 'sin_marcar' ? '--:--' : 'A tiempo'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      ]),
    );
  }
}
