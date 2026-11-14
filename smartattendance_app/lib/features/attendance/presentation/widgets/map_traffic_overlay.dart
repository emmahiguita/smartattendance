// ============================================================================
// ARCHIVO: map_traffic_overlay.dart
// QUÉ HACE: Capa visual transparente de tráfico vehicular e incidentes en tiempo real
//           para `FlutterMap` sobre cualquier estilo base (Calles, Nocturno, Satélite).
// CÓMO FUNCIONA: Inyecta `TileLayer` raster transparente de TomTom Traffic Flow
//                y TomTom Incidents solo cuando el flag `enabled` es true.
// POR QUÉ: Permite ver el tráfico en vivo en Pereira/Dosquebradas sin recargar
//          el mapa base ni perder el modo oscuro nocturno (< 100 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/location/traffic_provider.dart';

class MapTrafficOverlay extends StatelessWidget {
  const MapTrafficOverlay({
    super.key,
    required this.enabled,
    this.apiKey,
    this.showIncidents = false,
  });

  final bool enabled;
  final String? apiKey;
  final bool showIncidents;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    // QUÉ HACE: Determina la fuente de tráfico en tiempo real.
    // CÓMO: Si hay una API Key válida de TomTom, consume sus tiles vector/raster.
    //       De lo contrario, usa Google Traffic real (capa transparente 200 OK
    //       para toda Colombia con colores de congestión verde, amarillo y rojo).
    final hasValidTomTom = apiKey != null &&
        apiKey!.isNotEmpty &&
        apiKey != TomTomTrafficProvider.defaultPublicDevKey;

    final trafficUrl = hasValidTomTom
        ? 'https://api.tomtom.com/traffic/map/4/tile/flow/relative/{z}/{x}/{y}.png?key=$apiKey&thickness=10'
        : 'https://mt1.google.com/vt?lyrs=h,traffic|seconds_into_future:0&x={x}&y={y}&z={z}';

    return Stack(
      children: [
        // ── Capa de Tráfico Vehicular en Tiempo Real ──
        TileLayer(
          key: ValueKey(hasValidTomTom ? 'tomtom_$apiKey' : 'google_traffic_live'),
          urlTemplate: trafficUrl,
          userAgentPackageName: 'io.smartattendance.attendance',
          maxNativeZoom: 19,
          maxZoom: 22,
        ),

        // ── Capa de Incidentes (Cierres y Obras de TomTom si está configurado) ──
        if (showIncidents && hasValidTomTom)
          TileLayer(
            key: ValueKey('tomtom_incidents_$apiKey'),
            urlTemplate:
                'https://api.tomtom.com/traffic/map/4/tile/incidents/s3/{z}/{x}/{y}.png?key=$apiKey',
            userAgentPackageName: 'io.smartattendance.attendance',
            maxNativeZoom: 18,
            maxZoom: 22,
          ),
      ],
    );
  }
}
