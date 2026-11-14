// QUÉ HACE: Resume las marcas reales de la jornada en una sección abierta.
// CÓMO: Reutiliza el cálculo de duración y separa acciones mediante divisores.
// POR QUÉ: Conserva información legible sin insignias de colores ni tarjetas.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../domain/entities/attendance_entity.dart';
import 'day_marks_grid.dart';

class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({super.key, required this.records, this.onMarkTap});
  final List<AttendanceEntity> records;
  final ValueChanged<String>? onMarkTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = records.where((r) {
      final date = r.fecha.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));
    var start = 0;
    for (var i = 0; i < today.length; i++) {
      if (today[i].tipo == 'entrada') start = i;
    }
    final current = today.sublist(start);
    final marks = <String, AttendanceEntity?>{
      'entrada': null,
      'salida_almuerzo': null,
      'regreso_almuerzo': null,
      'salida': null
    };
    for (final mark in current) {
      if (marks.containsKey(mark.tipo)) marks[mark.tipo] = mark;
    }
    final last = current.lastOrNull;
    final state = last == null
        ? 'Pendiente de registro'
        : last.tipo == 'salida'
            ? 'Jornada completada'
            : 'En curso · ${attendanceTypeShort(last.tipo)}';
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Registro de Jornada',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary)),
          const SizedBox(height: 6),
          Text(state,
              style: TextStyle(fontSize: 14, color: context.cTextSecondary)),
          const Divider(height: 24),
          DayMarksGrid(marks: marks, onMarkTap: onMarkTap),
          if (today.isNotEmpty) ...[
            const Divider(height: 24),
          Text('Tiempo acumulado hoy',
                style: TextStyle(fontSize: 15, color: context.cTextPrimary)),
          const SizedBox(height: 4),
          Text(calculateWorkedHoursLabel(today),
              style: TextStyle(fontSize: 16, color: context.cTextPrimary)),
          ],
        ]));
  }
}
