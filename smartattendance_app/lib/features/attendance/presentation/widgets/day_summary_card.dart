// ============================================================================
// ARCHIVO: day_summary_card.dart
// QUÉ HACE: Tarjeta consolidada del ciclo laboral diario del colaborador:
//           Entrada, Inicio de almuerzo, Regreso de almuerzo y Salida con
//           cálculo de horas laboradas en tiempo real.
// CÓMO FUNCIONA: Identifica la jornada actual en hora local de Colombia, mapea
//                los 4 eventos reales y delega la cuadrícula táctil a
//                `DayMarksGrid` usando tokens de superficie unificados.
// POR QUÉ: Cumple con acceso instantáneo por toque directo, cero horas extras
//          manuales y coherencia cromática sobria (< 185 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../domain/entities/attendance_entity.dart';
import 'day_marks_grid.dart';

class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    super.key,
    required this.records,
    this.onMarkTap,
  });

  final List<AttendanceEntity> records;
  final ValueChanged<String>? onMarkTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final todayLocal = records.where((r) {
      final local = r.fecha.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));

    var inicio = 0;
    for (var i = 0; i < todayLocal.length; i++) {
      if (todayLocal[i].tipo == 'entrada') inicio = i;
    }
    final jornadaActual = todayLocal.sublist(inicio);

    final marksMap = <String, AttendanceEntity?>{
      'entrada': null,
      'salida_almuerzo': null,
      'regreso_almuerzo': null,
      'salida': null,
    };

    for (final r in jornadaActual) {
      if (marksMap.containsKey(r.tipo)) {
        marksMap[r.tipo] = r;
      }
    }

    final mEntrada = marksMap['entrada'];
    final mSalida = marksMap['salida'];
    final ultima = jornadaActual.isNotEmpty ? jornadaActual.last : null;
    final completada = mEntrada != null && mSalida != null;

    final String estadoTitulo;
    final Color dotColor;

    final Color badgeBg;
    final Color badgeBorder;
    if (completada) {
      estadoTitulo = 'Jornada completada';
      dotColor = AppColors.primary;
      badgeBg = AppColors.primary.withValues(alpha: 0.12);
      badgeBorder = AppColors.primary.withValues(alpha: 0.3);
    } else if (ultima != null) {
      estadoTitulo = 'En curso · ${attendanceTypeShort(ultima.tipo)}';
      dotColor = AppColors.systemGreen;
      badgeBg = AppColors.systemGreen.withValues(alpha: 0.12);
      badgeBorder = AppColors.systemGreen.withValues(alpha: 0.3);
    } else {
      estadoTitulo = 'Pendiente de registro';
      dotColor = AppColors.titanium;
      badgeBg = context.cSurface.withValues(alpha: 0.5);
      badgeBorder = context.cBorder.withValues(alpha: 0.5);
    }

    final workedLabel = calculateWorkedHoursLabel(todayLocal);

    return IosGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: context.cTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Registro de Jornada',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      estadoTitulo,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.8, color: context.cBorder),
          const SizedBox(height: 12),
          DayMarksGrid(marks: marksMap, onMarkTap: onMarkTap),
          if (todayLocal.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: context.cBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.cBorder, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiempo acumulado hoy',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.cTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    workedLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.cTextPrimary,
                      fontFeatures: AppDesignTokens.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
