// test/widget/responsive_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/attendance/domain/entities/attendance_entity.dart';
import 'package:smartattendance/features/attendance/presentation/screens/home_screen.dart';

/// Verifica que el resumen del día y el selector de tema NO desborden
/// (textos cortados) en pantallas angostas de móvil (360dp).
void main() {
  AttendanceEntity marca({
    required int id,
    required DateTime fecha,
    required int h,
    required int m,
    required String tipo,
  }) =>
      AttendanceEntity(
        id: id,
        usuarioId: 1,
        tipo: tipo,
        fecha: fecha,
        hora: DateTime(fecha.year, fecha.month, fecha.day, h, m),
      );

  final hoy = DateTime.now();

  final jornadaCompleta = [
    marca(id: 1, fecha: hoy, h: 8, m: 0, tipo: 'entrada'),
    marca(id: 2, fecha: hoy, h: 12, m: 0, tipo: 'salida_almuerzo'),
    marca(id: 3, fecha: hoy, h: 13, m: 0, tipo: 'regreso_almuerzo'),
    marca(id: 4, fecha: hoy, h: 17, m: 0, tipo: 'salida'),
  ];

  Widget wrap(Widget child, {double width = 360}) => MediaQuery(
        data: const MediaQueryData(size: Size(360, 800), alwaysUse24HourFormat: true),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
          ),
        ),
      );

  testWidgets('2 jornadas el mismo día: el resumen muestra la ACTUAL sin mezclar', (tester) async {
    final records = [
      // Jornada 1 completa: 8:00 → 17:00
      marca(id: 1, fecha: hoy, h: 8, m: 0, tipo: 'entrada'),
      marca(id: 2, fecha: hoy, h: 12, m: 0, tipo: 'salida_almuerzo'),
      marca(id: 3, fecha: hoy, h: 13, m: 0, tipo: 'regreso_almuerzo'),
      marca(id: 4, fecha: hoy, h: 17, m: 0, tipo: 'salida'),
      // Jornada 2 en curso: 18:00 → 19:00 (solo entrada + almuerzo)
      marca(id: 5, fecha: hoy, h: 18, m: 0, tipo: 'entrada'),
      marca(id: 6, fecha: hoy, h: 19, m: 0, tipo: 'salida_almuerzo'),
    ];
    await tester.pumpWidget(wrap(DaySummaryCard(records: records)));
    expect(tester.takeException(), isNull);

    // Estado = jornada ACTUAL en curso (NO "Jornada completada" por mezcla).
    expect(find.text('Activa · Almuerzo'), findsOneWidget);
    // Horas de la jornada ACTUAL (18:00 / 19:00), no las de la jornada 1.
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    // Regreso y Salida sin marca en la jornada actual → '--:--'.
    expect(find.text('--:--'), findsNWidgets(2));
    // La jornada 1 (8:00/17:00) NO debe aparecer mezclada.
    expect(find.text('8:00'), findsNothing);
  });

  testWidgets('DaySummaryCard sin overflow a 360dp (grid 2x2, etiquetas completas)', (tester) async {
    await tester.pumpWidget(wrap(DaySummaryCard(records: jornadaCompleta)));
    expect(tester.takeException(), isNull, reason: 'Overflow en 360dp con jornada completa');
    // Etiquetas completas visibles (grid 2x2, no cortadas).
    expect(find.text('Inicio de almuerzo'), findsOneWidget);
    expect(find.text('Regreso de almuerzo'), findsOneWidget);
    expect(find.text('Tiempo Laborado Hoy: '), findsOneWidget);
  });

  testWidgets('DaySummaryCard sin overflow en pantalla ancha (fila de 4)', (tester) async {
    await tester.pumpWidget(wrap(DaySummaryCard(records: jornadaCompleta), width: 600));
    expect(tester.takeException(), isNull, reason: 'Overflow en 600dp');
    expect(find.text('Inicio de almuerzo'), findsOneWidget);
  });

  testWidgets('DaySummaryCard vacío (sin marcas) sin overflow', (tester) async {
    await tester.pumpWidget(wrap(const DaySummaryCard(records: [])));
    expect(tester.takeException(), isNull);
    expect(find.text('Sin registrar hoy'), findsOneWidget);
  });

  testWidgets('Selector de tema no corta "Oscuro" a 360dp', (tester) async {
    await tester.pumpWidget(wrap(const _ThemeSelector()));
    expect(tester.takeException(), isNull, reason: 'Overflow en el selector de tema');
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
  });
}

/// Selector de tema idéntico al de Configuración (sin providers: solo UI).
class _ThemeSelector extends StatefulWidget {
  const _ThemeSelector();

  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        onSelectionChanged: (sel) => setState(() => _mode = sel.first),
      );
}
