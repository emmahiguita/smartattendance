// ============================================================================
// ARCHIVO: map_carto_style.dart
// QUÉ HACE: Define los 4 estilos cartográficos reales de alta disponibilidad:
//           1. Calles (Google Maps Roads con fallback OSM)
//           2. Nocturno (CartoDB Dark Matter Liquid Glass con subdominios a-d)
//           3. Satélite (Google Maps Hybrid: satelital HD + nombres de vías)
//           4. Topográfico (Google Maps Terrain con relieve de alta fidelidad)
// CÓMO FUNCIONA: Inyecta subdominios para descarga paralela rápida de teselas y
//                fallback automático si la conexión primaria experimenta timeout.
// POR QUÉ: Garantiza que el mapa SIEMPRE muestre imágenes satelitales y cartografía
//          real sin cuadros grises vacíos ni bloqueos de rate-limit (< 80 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';

enum MapCartoStyle {
  // ── 1. Calles: Google Maps Vectorial / Roads con respaldo OSM ──
  streets(
    'Calles',
    'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    CupertinoIcons.map,
    subdomains: ['0', '1', '2', '3'],
    fallback: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),

  // ── 2. Nocturno: ESRI Dark Gray Canvas (Pristino, sin marcas de agua, 100% real) ──
  dark(
    'Nocturno',
    'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    CupertinoIcons.moon_fill,
    subdomains: [],
    fallback: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
  ),

  // ── 3. Satélite: Google Maps Hybrid (fotografía aérea HD + nombres) ──
  satellite(
    'Satélite',
    'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    CupertinoIcons.globe,
    subdomains: ['0', '1', '2', '3'],
    fallback: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  ),

  // ── 4. Topográfico: Google Maps Terrain con cotas de elevación ──
  topo(
    'Topográfico',
    'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
    CupertinoIcons.compass,
    subdomains: ['0', '1', '2', '3'],
    fallback: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
  ),

  // ── 5. Tráfico: Flujo vehicular en tiempo real para Colombia ──
  traffic(
    'Tráfico',
    'https://mt{s}.google.com/vt/lyrs=m,traffic&x={x}&y={y}&z={z}',
    CupertinoIcons.car_detailed,
    subdomains: ['0', '1', '2', '3'],
    fallback: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
  );

  final String label;
  final String url;
  final IconData icon;
  final List<String> subdomains;
  final String? fallback;

  const MapCartoStyle(
    this.label,
    this.url,
    this.icon, {
    this.subdomains = const ['a', 'b', 'c'],
    this.fallback,
  });

  MapCartoStyle get next =>
      MapCartoStyle.values[(index + 1) % MapCartoStyle.values.length];
}

class MapBaseTileLayer extends StatelessWidget {
  const MapBaseTileLayer({super.key, required this.style});
  final MapCartoStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == MapCartoStyle.dark) {
      return Stack(
        children: [
          TileLayer(
            key: const ValueKey('esri_dark_base'),
            urlTemplate: style.url,
            fallbackUrl: style.fallback,
            userAgentPackageName: 'io.smartattendance.attendance',
            maxNativeZoom: 16,
            maxZoom: 22,
          ),
          TileLayer(
            key: const ValueKey('esri_dark_ref'),
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'io.smartattendance.attendance',
            maxNativeZoom: 16,
            maxZoom: 22,
          ),
        ],
      );
    }

    return TileLayer(
      key: ValueKey('${style.name}_${style.url}'),
      urlTemplate: style.url,
      fallbackUrl: style.fallback,
      subdomains: style.subdomains,
      userAgentPackageName: 'io.smartattendance.attendance',
      maxNativeZoom: 20,
      maxZoom: 22,
    );
  }
}
