// ============================================================================
// ARCHIVO: serviciudad_assigned_location_card.dart
// QUÉ HACE: Tarjeta de Ubicación Asignada idéntica al diseño iOS de Serviciudad,
//           con sede/zona, dirección y miniatura de mapa GPS interactivo.
// CÓMO FUNCIONA: Muestra pin de localización, nombre de zona y estado GPS Activo
//                con apertura directa del visor cartográfico a pantalla completa.
// POR QUÉ: Réplica exacta del módulo de ubicación de la imagen (< 160 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'explorable_map_dialog.dart';

class ServiciudadAssignedLocationCard extends StatelessWidget {
  const ServiciudadAssignedLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.zoneName,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.isInsideZone,
    this.onRefresh,
  });

  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? zoneName;
  final double? zoneLat;
  final double? zoneLng;
  final double? zoneRadius;
  final bool? isInsideZone;
  final VoidCallback? onRefresh;

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
    final hasFix = latitude != null && longitude != null;
    final centerPoint = hasFix ? LatLng(latitude!, longitude!) : const LatLng(4.8333, -75.6833);

    return IosGlassCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _openMap(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ubicación asignada', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: context.cTextSecondary)),
                const SizedBox(height: 2),
                Text(
                  zoneName ?? 'Zona Centro Operativo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.cTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  'Dosquebradas, Risaralda · E.S.P.',
                  style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 116,
              height: 68,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'io.smartattendance.attendance',
                      ),
                      CircleLayer(circles: [
                        CircleMarker(
                          point: centerPoint,
                          radius: 35,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ]),
                    ],
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                          const SizedBox(width: 4),
                          const Text('GPS Activo', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.graphite)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
