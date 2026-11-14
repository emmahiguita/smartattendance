// ============================================================================
// ARCHIVO: map_weather_overlay.dart
// QUÉ HACE: Capa visual transparente de radar Doppler de lluvias y precipitaciones en vivo
//           para `FlutterMap` sobre cualquier estilo cartográfico (Calles, Nocturno, Satélite).
// CÓMO FUNCIONA: Inyecta `TileLayer` raster transparente con datos Doppler de RainViewer/SIATA
//                con opacidad calibrada para mantener la visibilidad de las vías.
// POR QUÉ: Permite verificar si llueve sobre la sede o la ruta del empleado en tiempo real (< 70 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapWeatherOverlay extends StatelessWidget {
  const MapWeatherOverlay({
    super.key,
    required this.enabled,
    this.radarTileUrl,
    this.opacity = 0.65,
  });

  final bool enabled;
  final String? radarTileUrl;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!enabled || radarTileUrl == null || radarTileUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    // QUÉ HACE: Despliega el radar Doppler de precipitaciones.
    // CÓMO: RainViewer genera compuestos de radar hasta zoom 7 (en 512px HD).
    //       Fijamos `maxNativeZoom: 7` para que FlutterMap escale la tesela
    //       en zooms 8-22 sin solicitar niveles que devuelven 'Zoom level not supported'.
    return Opacity(
      opacity: opacity.clamp(0.1, 1.0),
      child: TileLayer(
        key: ValueKey('radar_weather_$radarTileUrl'),
        urlTemplate: radarTileUrl!,
        tileDimension: 512,
        userAgentPackageName: 'io.smartattendance.attendance',
        maxNativeZoom: 7,
        maxZoom: 22,
      ),
    );
  }
}
