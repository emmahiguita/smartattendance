// ============================================================================
// ARCHIVO: serviciudad_status_grid.dart
// QUÉ HACE: Barra de estado 100% Apple Liquid Glass transparente con:
//           1. Indicador circular de estado de jornada (bullet verde/ámbar/azul).
//           2. Tiempo acumulado con tipografía editorial profesional en cTextPrimary.
//           3. Chip de geocerca GPS interactivo para inspección de mapa.
// CÓMO FUNCIONA: Usa `BackdropFilter` con desenfoque de 20px, gradiente de refracción
//                vítrea y jerarquía tipográfica sin colores de texto excesivos.
// POR QUÉ: Atiende la directiva "NO DEBE TENER COLORES DE TEXTO INNECESARIOS,
//          ORGANIZA DE FORMA PROFESIONAL, LIQUID GLASSED 100%" (< 160 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../domain/entities/attendance_entity.dart';
import 'explorable_map_dialog.dart';
import 'serviciudad_status_bar.dart';

class ServiciudadStatusGrid extends StatelessWidget {
  const ServiciudadStatusGrid({
    super.key,
    required this.records,
    this.isInsideZone,
    this.zoneName,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.assignedOvertimeMinutes = 0,
  });

  final List<AttendanceEntity> records;
  final bool? isInsideZone;
  final String? zoneName;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? zoneLat;
  final double? zoneLng;
  final double? zoneRadius;
  final int assignedOvertimeMinutes;

  void _openMap(BuildContext context) {
    if (latitude == null || longitude == null) return;
    ExplorableMapDialog.show(
      context,
      latitude: latitude!,
      longitude: longitude!,
      accuracy: accuracy,
      zoneLat: zoneLat,
      zoneLng: zoneLng,
      zoneRadius: zoneRadius,
      zoneName: zoneName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final success = isDark ? AppColors.successDark : AppColors.success;
    final now = DateTime.now();
    final today = records.where((r) {
      return ColombiaClock.day(r.fecha) == ColombiaClock.day(now);
    }).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));

    final lastMark = today.isNotEmpty ? today.last.tipo.toLowerCase() : '';
    final entrada =
        today.where((r) => r.tipo.toLowerCase() == 'entrada').firstOrNull;
    final salida =
        today.where((r) => r.tipo.toLowerCase() == 'salida').firstOrNull;

    final String statusText;
    final Color bulletColor;
    String tiempoTrabajado = '0h 00m';

    if (entrada != null) {
      if (salida != null) {
        statusText = 'Jornada finalizada';
        bulletColor = primary;
        tiempoTrabajado = calculateWorkedHoursLabel(today, now: now);
      } else if (lastMark == 'salida_almuerzo') {
        statusText = 'En almuerzo';
        bulletColor = const Color(0xFFF59E0B);
        tiempoTrabajado = calculateWorkedHoursLabel(today, now: now);
      } else {
        statusText = 'En curso';
        bulletColor = success;
        tiempoTrabajado = calculateWorkedHoursLabel(today, now: now);
      }
    } else {
      statusText = 'Por iniciar';
      bulletColor = context.cTextSecondary.withValues(alpha: 0.5);
    }

    final zoneLabel = isInsideZone == true
        ? '${zoneName ?? 'Sede'} (En geocerca)'
        : (zoneName ?? 'Sin sede asignada');

    return ServiciudadStatusBar(
      statusText: statusText,
      workedTime: tiempoTrabajado,
      zoneLabel: zoneLabel,
      bulletColor: bulletColor,
      primary: primary,
      isDark: isDark,
      onOpenMap: () => _openMap(context),
    );
  }
}
