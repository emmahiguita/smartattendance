// ============================================================================
// ARCHIVO: serviciudad_status_grid.dart
// QUÉ HACE: Barra de estado transparente, compacta y no redundante.
// CÓMO FUNCIONA: Muestra en una sola fila minimalista y transparente:
//                1. Estado de jornada en vivo (bullet + En curso / En almuerzo).
//                2. Tiempo laborado acumulado.
//                3. Geocerca GPS con acceso al mapa interactivo.
// POR QUÉ: Atiende la directiva: "DEPURA ESA CARD DEBE SER TRANSPARENTE TODO,
//          CORRIGE COMPONENTES NO DEBEN SER REDUNDANTES" (< 130 líneas).
// ============================================================================

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
    final now = DateTime.now();
    final today = records.where((r) {
      final l = r.fecha.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }).toList()..sort((a, b) => a.hora.compareTo(b.hora));

    final lastMark = today.isNotEmpty ? today.last.tipo.toLowerCase() : '';
    final entrada = today.where((r) => r.tipo.toLowerCase() == 'entrada').firstOrNull;
    final salida = today.where((r) => r.tipo.toLowerCase() == 'salida').firstOrNull;

    final String statusText;
    final Color statusColor;
    String tiempoTrabajado = '0h 00m';

    if (entrada != null) {
      if (salida != null) {
        statusText = 'Jornada finalizada';
        statusColor = AppColors.primary;
        final diff = salida.hora.difference(entrada.hora);
        tiempoTrabajado = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      } else if (lastMark == 'salida_almuerzo') {
        statusText = 'En almuerzo';
        statusColor = const Color(0xFFF59E0B);
        final diff = today.last.hora.difference(entrada.hora);
        tiempoTrabajado = '${diff.inHours}h ${diff.inMinutes.remainder(60).abs()}m';
      } else {
        statusText = 'En curso';
        statusColor = AppColors.success;
        final diff = now.difference(entrada.hora.toLocal());
        tiempoTrabajado = '${diff.inHours}h ${diff.inMinutes.remainder(60).abs()}m';
      }
    } else {
      statusText = 'Por iniciar';
      statusColor = context.cTextSecondary;
    }

    final zoneLabel = isInsideZone == true
        ? '${zoneName ?? 'Sede'} (En geocerca)'
        : (zoneName ?? 'Sede Central');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.cBorder.withValues(alpha: context.isDark ? 0.35 : 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
          ),
          const SizedBox(width: 6),
          Text(
            '•  $tiempoTrabajado',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.cTextPrimary),
          ),
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
                    const Icon(CupertinoIcons.location_solid, size: 11, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        zoneLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(CupertinoIcons.chevron_forward, size: 9, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
