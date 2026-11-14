// ============================================================================
// ARCHIVO: home_visual_map_card.dart
// QUÉ HACE: Mapa de posición real y sede asignada en una sección abierta iOS.
// CÓMO FUNCIONA: Dibuja coordenadas verificadas, controles compactos en la
//                cabecera y visor de mapa con bordes limpios sin superposiciones.
// POR QUÉ: Aprovecha el espacio vertical en Inicio sin tarjetas decorativas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import 'explorable_map_dialog.dart';
import 'map_sonar_layer.dart';

class HomeVisualMapCard extends StatelessWidget {
  const HomeVisualMapCard({
    super.key,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.zoneName,
    this.isInsideZone,
    this.distanceMeters,
    this.onRefresh,
  });

  final double? latitude,
      longitude,
      accuracy,
      zoneLat,
      zoneLng,
      zoneRadius,
      distanceMeters;
  final String? zoneName;
  final bool? isInsideZone;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final userPoint = latitude != null && longitude != null
        ? LatLng(latitude!, longitude!)
        : null;
    final zonePoint =
        zoneLat != null && zoneLng != null ? LatLng(zoneLat!, zoneLng!) : null;
    final center = userPoint ?? zonePoint;
    final foreground = context.cTextPrimary;
    final state = userPoint == null
        ? 'Ubicación no disponible'
        : zonePoint == null
            ? 'Sin sede asignada'
            : isInsideZone == true
                ? 'Dentro de geocerca'
                : 'Fuera de geocerca';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      state,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Actualizar ubicación',
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, size: 20, color: foreground),
              ),
              if (userPoint != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Ampliar mapa',
                  icon: Icon(Icons.open_in_full, size: 19, color: foreground),
                  onPressed: () => ExplorableMapDialog.show(
                    context,
                    latitude: userPoint.latitude,
                    longitude: userPoint.longitude,
                    accuracy: accuracy,
                    zoneLat: zoneLat,
                    zoneLng: zoneLng,
                    zoneRadius: zoneRadius,
                    zoneName: zoneName,
                    initialStyle: context.isDark
                        ? MapCartoStyle.dark
                        : MapCartoStyle.streets,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (center == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Activa la ubicación para consultar el mapa.',
                style: TextStyle(fontSize: 13, color: context.cTextSecondary),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 185,
                child: FlutterMap(
                  key: ValueKey('${center.latitude}:${center.longitude}'),
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 16,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    MapBaseTileLayer(
                      style: context.isDark
                          ? MapCartoStyle.dark
                          : MapCartoStyle.streets,
                    ),
                    if (zonePoint != null && zoneRadius != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: zonePoint,
                            radius: zoneRadius!,
                            useRadiusInMeter: true,
                            color: foreground.withValues(alpha: 0.08),
                            borderColor: foreground.withValues(alpha: 0.7),
                            borderStrokeWidth: 1,
                          ),
                        ],
                      ),
                    if (userPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userPoint,
                            width: 32,
                            height: 32,
                            child: Semantics(
                              label: 'Tu ubicación',
                              child: Icon(
                                Icons.my_location,
                                size: 24,
                                color: foreground,
                              ),
                            ),
                          ),
                        ],
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
