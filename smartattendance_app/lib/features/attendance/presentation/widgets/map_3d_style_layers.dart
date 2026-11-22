// ============================================================================
// ARCHIVO: map_3d_style_layers.dart
// QUÉ HACE: Gestiona los planos cartográficos nativos en MapLibre 3D (Calles,
//           Satélite Híbrido HD, Relieve Topográfico y Nocturno 3D), extrusión
//           de edificios 3D, tráfico en vivo y radar Doppler.
// CÓMO FUNCIONA: Serializa todas las mutaciones de capas mediante `_syncChain`
//                sobre un único estilo base estable (`lightStyleUrl`).
// POR QUÉ: Estabilidad 100% libre de condiciones de carrera JNI (< 180 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'map_carto_style.dart';

abstract final class Map3DStyleLayers {
  static const lightStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const darkStyleUrl = 'https://tiles.openfreemap.org/styles/dark';
  static const _planeSrc = 'buentiempo-plane-src';
  static const _planeLyr = 'buentiempo-plane-lyr';
  static const _planeBldLyr = 'buentiempo-plane-buildings-3d';
  static const _trafficSrc = 'buentiempo-traffic-src';
  static const _trafficLyr = 'buentiempo-traffic-lyr';
  static const _rainSrc = 'buentiempo-rain-src';
  static const _rainLyr = 'buentiempo-rain-lyr';

  static Future<void> _syncChain = Future<void>.value();

  static Future<void> syncOverlays({
    required ml.StyleController style,
    required MapCartoStyle cartoStyle,
    required bool trafficEnabled,
    required bool rainEnabled,
    String? radarTileUrl,
  }) {
    _syncChain = _syncChain
        .then((_) => _applyOverlays(
              style: style,
              cartoStyle: cartoStyle,
              trafficEnabled: trafficEnabled,
              rainEnabled: rainEnabled,
              radarTileUrl: radarTileUrl,
            ))
        .catchError((_) {});
    return _syncChain;
  }

  static Future<void> _applyOverlays({
    required ml.StyleController style,
    required MapCartoStyle cartoStyle,
    required bool trafficEnabled,
    required bool rainEnabled,
    String? radarTileUrl,
  }) async {
    final planeUrl = switch (cartoStyle) {
      MapCartoStyle.satellite => 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
      MapCartoStyle.topo => 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      MapCartoStyle.dark => 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
      _ => '',
    };

    try {
      await style.removeLayer(_planeBldLyr);
    } catch (_) {}

    await _toggleRaster(
      style: style,
      sourceId: _planeSrc,
      layerId: _planeLyr,
      enabled: planeUrl.isNotEmpty,
      tileUrl: planeUrl,
      opacity: 1.0,
      maxZoom: 20,
      tileSize: 256,
    );

    if (planeUrl.isNotEmpty) {
      final isDarkPlane = cartoStyle == MapCartoStyle.dark;
      try {
        await style.addLayer(ml.FillExtrusionStyleLayer(
          id: _planeBldLyr,
          sourceId: 'openmaptiles',
          sourceLayerId: 'building',
          minZoom: 14.2,
          paint: {
            'fill-extrusion-color': isDarkPlane
                ? '#1E293B'
                : (cartoStyle == MapCartoStyle.satellite ? '#F8FAFC' : '#CBD5E1'),
            'fill-extrusion-opacity': isDarkPlane ? 0.72 : 0.40,
            'fill-extrusion-height': ['coalesce', ['get', 'render_height'], 12],
            'fill-extrusion-base': ['coalesce', ['get', 'render_min_height'], 0],
          },
        ));
      } catch (_) {}
    }

    await _toggleRaster(
      style: style,
      sourceId: _trafficSrc,
      layerId: _trafficLyr,
      enabled: trafficEnabled,
      tileUrl: 'https://mt1.google.com/vt?lyrs=h,traffic|seconds_into_future:0&x={x}&y={y}&z={z}',
      opacity: 0.80,
      maxZoom: 19,
      tileSize: 256,
    );

    await _toggleRaster(
      style: style,
      sourceId: _rainSrc,
      layerId: _rainLyr,
      enabled: rainEnabled && (radarTileUrl?.isNotEmpty ?? false),
      tileUrl: radarTileUrl ?? '',
      opacity: 0.52,
      maxZoom: 7,
      tileSize: 512,
    );
  }

  static Future<void> _toggleRaster({
    required ml.StyleController style,
    required String sourceId,
    required String layerId,
    required bool enabled,
    required String tileUrl,
    required double opacity,
    required double maxZoom,
    required int tileSize,
  }) async {
    try {
      await style.removeLayer(layerId);
    } catch (_) {}
    try {
      await style.removeSource(sourceId);
    } catch (_) {}
    if (!enabled || tileUrl.isEmpty) return;
    try {
      await style.addSource(ml.RasterSource(id: sourceId, tiles: [tileUrl], tileSize: tileSize, maxZoom: maxZoom));
      await style.addLayer(ml.RasterStyleLayer(id: layerId, sourceId: sourceId, paint: {'raster-opacity': opacity}));
    } catch (_) {}
  }
}

class Map3DPinBadge extends StatelessWidget {
  const Map3DPinBadge({super.key, required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white, width: 0.9),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.24), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.2, letterSpacing: -0.1, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(height: 2.5),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)],
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
      ]);
}
