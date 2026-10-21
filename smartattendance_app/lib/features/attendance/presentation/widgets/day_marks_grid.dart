// lib/features/attendance/presentation/widgets/day_marks_grid.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/entities/attendance_entity.dart';
import 'mark_chip.dart';

/// ============================================================================
/// COMPONENTE: DayMarksGrid (Cuadrícula de las 4 Marcas de Jornada)
/// ============================================================================
/// QUÉ HACE:
/// Despliega las 4 marcas fundamentales de la jornada laboral:
/// 1. Entrada
/// 2. Inicio de almuerzo
/// 3. Regreso de almuerzo
/// 4. Salida
///
/// CÓMO FUNCIONA:
/// Elimina horas extras (las cuales son administradas por reglas del supervisor).
/// Tocar directamente cualquiera de las 4 tarjetas miniatura abre la cámara frontal
/// de reconocimiento facial con la posición GPS real.
///
/// POR QUÉ:
/// Cero redundancias, cero simulaciones y estricto cumplimiento SOLID (< 200 líneas).
/// ============================================================================
class DayMarksGrid extends StatelessWidget {
  const DayMarksGrid({
    super.key,
    required this.marks,
    this.onMarkTap,
  });

  final Map<String, AttendanceEntity?> marks;
  final ValueChanged<String>? onMarkTap;

  @override
  Widget build(BuildContext context) {
    const types = [
      'entrada',
      'salida_almuerzo',
      'regreso_almuerzo',
      'salida',
    ];

    final hasEntrada = marks['entrada'] != null;
    final hasAlmuerzo = marks['salida_almuerzo'] != null;
    final hasRegreso = marks['regreso_almuerzo'] != null;
    final hasSalida = marks['salida'] != null;

    final nextTypes = <String>{};
    if (!hasEntrada) {
      nextTypes.add('entrada');
    } else if (!hasSalida) {
      if (!hasAlmuerzo) {
        nextTypes.add('salida_almuerzo');
        nextTypes.add('salida');
      } else if (!hasRegreso) {
        nextTypes.add('regreso_almuerzo');
      } else {
        nextTypes.add('salida');
      }
    }

    return LayoutBuilder(builder: (context, size) {
      final width = (size.maxWidth - 8) / 2;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: types.map((type) {
          final record = marks[type];
          final info = attendanceTypeInfo(type);
          final isRecorded = record != null;
          final isNext = nextTypes.contains(type) && !isRecorded;

          final horaTexto = isRecorded ? formatTimeOfDay(context, record.hora) : '--:--';

          return SizedBox(
            width: width,
            child: MarkChip(
              label: info.label,
              hora: horaTexto,
              color: info.color,
              icon: info.icon,
              active: isRecorded,
              isNext: isNext,
              onTap: () => onMarkTap?.call(type),
            ),
          );
        }).toList(),
      );
    });
  }
}
