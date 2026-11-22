// ============================================================================
// ARCHIVO: home_schedule_card.dart
// QUÉ HACE: Bloque limpio de "Horario asignado" con icono de calendario azul,
//           textos nítidos sin errores y proporciones compactas.
// CÓMO FUNCIONA: Se integra con separadores limpios sobre el lienzo de Inicio
//                sin bordes gruesos que causen desorientación de color.
// POR QUÉ: Permite que las tarjetas y el mapa miniatura quepan en pantalla (< 95 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';

class HomeScheduleCard extends StatelessWidget {
  const HomeScheduleCard({
    super.key,
    required this.schedule,
    this.assignedOvertimeMinutes = 0,
  });

  final WorkSchedule? schedule;
  final int assignedOvertimeMinutes;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final value = schedule;
    final extra = value?.assignedOvertimeMinutes ?? assignedOvertimeMinutes;
    final primaryTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTxt =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final iconColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF00439C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E30) : const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(CupertinoIcons.calendar, size: 19, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Horario asignado',
                      style: TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: primaryTxt,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        value == null
                            ? 'Sin horario asignado'
                            : '${value.shiftName ?? 'Jornada'} · ${value.timeWindowFormattedDual}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: primaryTxt,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1.5),
                Text(
                  value == null
                      ? 'Consulta con tu administrador'
                      : 'Ventana permitida: ${value.markWindowFormatted}${extra > 0 ? ' · +${extra ~/ 60}h ${extra % 60}m extra' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w500,
                    color: secondaryTxt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
