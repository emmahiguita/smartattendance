// ============================================================================
// ARCHIVO: serviciudad_status_grid.dart
// QUÉ HACE: Barra de estado 100% iOS Liquid Glass transparente con:
//           1. Estado de jornada en vivo (bullet + En curso / Finalizada).
//           2. Tiempo laborado acumulado (sumando Horas Extras Asignadas).
//           3. Geocerca GPS con acceso al mapa interactivo.
// CÓMO FUNCIONA: Envuelve la barra en `BackdropFilter` con cristal translúcido
//                y borde especular iOS en Modo Oscuro.
// POR QUÉ: Integra el conteo automático de Horas Extras Asignadas y Modo Oscuro
//          100% iOS transparente profesional (< 160 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_entity.dart';
import 'explorable_map_dialog.dart';

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
    final activeBlue = isDark ? AppColors.primaryDark : AppColors.primary;
    final activeGreen = isDark ? AppColors.successDark : AppColors.success;
    final now = DateTime.now();
    final today = records.where((r) {
      final l = r.fecha.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }).toList()..sort((a, b) => a.hora.compareTo(b.hora));

    final lastMark = today.isNotEmpty ? today.last.tipo.toLowerCase() : '';
    final entrada = today.where((r) => r.tipo.toLowerCase() == 'entrada').firstOrNull;
    final salida = today.where((r) => r.tipo.toLowerCase() == 'salida').firstOrNull;
    final extraDur = Duration(minutes: assignedOvertimeMinutes);

    final String statusText;
    final Color statusColor;
    String tiempoTrabajado = '0h 00m';

    if (entrada != null) {
      if (salida != null) {
        statusText = assignedOvertimeMinutes > 0 ? 'Finalizada (+${assignedOvertimeMinutes ~/ 60}h Ext)' : 'Jornada finalizada';
        statusColor = activeBlue;
        final diff = salida.hora.difference(entrada.hora) + extraDur;
        tiempoTrabajado = '${diff.inHours}h ${diff.inMinutes.remainder(60).abs()}m';
      } else if (lastMark == 'salida_almuerzo') {
        statusText = 'En almuerzo';
        statusColor = const Color(0xFFF59E0B);
        final diff = today.last.hora.difference(entrada.hora);
        tiempoTrabajado = '${diff.inHours}h ${diff.inMinutes.remainder(60).abs()}m';
      } else {
        statusText = assignedOvertimeMinutes > 0 ? 'En curso (+${assignedOvertimeMinutes ~/ 60}h Ext)' : 'En curso';
        statusColor = activeGreen;
        final diff = now.difference(entrada.hora.toLocal());
        tiempoTrabajado = '${diff.inHours}h ${diff.inMinutes.remainder(60).abs()}m';
      }
    } else {
      statusText = assignedOvertimeMinutes > 0 ? 'Por iniciar (+${assignedOvertimeMinutes ~/ 60}h Ext)' : 'Por iniciar';
      statusColor = context.cTextSecondary;
    }

    final zoneLabel = isInsideZone == true
        ? '${zoneName ?? 'Sede'} (En geocerca)'
        : (zoneName ?? 'Sede Central');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.16) : context.cBorder.withValues(alpha: 0.4),
              width: 0.85,
            ),
          ),
          child: Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
              const SizedBox(width: 6),
              Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              const SizedBox(width: 6),
              Text('•  $tiempoTrabajado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
              const Spacer(),
              Flexible(
                child: InkWell(
                  onTap: () => _openMap(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.location_solid, size: 11, color: activeBlue),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            zoneLabel,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: activeBlue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(CupertinoIcons.chevron_forward, size: 9, color: activeBlue),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
