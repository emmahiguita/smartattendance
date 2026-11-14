// ============================================================================
// ARCHIVO: location_address_map_picker.dart
// QUÉ HACE: Selector visual de ubicación física y geocerca con mapa Google Maps / OSM:
//           - Barra de búsqueda de dirección física con geocodificación en tiempo real.
//           - Visor de mapa interactivo para centrar y colocar pines con un toque.
//           - Geocodificación inversa automática y autodetección por sensor GPS del móvil.
// CÓMO FUNCIONA:
//   1. Al escribir una dirección y pulsar buscar, consulta `TraccarService.geocodeAddress`
//      y traslada el mapa a las coordenadas encontradas.
//   2. Al tocar el mapa, reposiciona el pin y traduce las coordenadas a texto legible.
//   3. Notifica cambios de coordenadas (`LatLng`) y dirección hacia el formulario padre.
// POR QUÉ: Permite fijar y validar la ubicación real del operario o sede (< 200 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_service.dart';
import '../../core/location/traccar_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/attendance/presentation/widgets/map_carto_style.dart';

class LocationAddressMapPicker extends StatefulWidget {
  const LocationAddressMapPicker({
    super.key,
    required this.addressCtrl,
    this.initialPoint,
    this.onLocationChanged,
    this.radiusMeters = 100.0,
    this.mapHeight = 160.0,
  });

  final TextEditingController addressCtrl;
  final LatLng? initialPoint;
  final void Function(LatLng point, String address)? onLocationChanged;
  final double radiusMeters;
  final double mapHeight;

  @override
  State<LocationAddressMapPicker> createState() => _LocationAddressMapPickerState();
}

class _LocationAddressMapPickerState extends State<LocationAddressMapPicker> {
  final MapController _mapController = MapController();
  late LatLng _point;
  bool _searching = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _point = widget.initialPoint ?? const LatLng(4.8333, -75.6833);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _updatePosition(LatLng pt, {String? newAddress}) {
    setState(() => _point = pt);
    try {
      _mapController.move(pt, 16.5);
    } catch (_) {}
    final addr = newAddress ?? widget.addressCtrl.text.trim();
    widget.onLocationChanged?.call(pt, addr);
  }

  /// QUÉ HACE: Geocodifica la dirección ingresada y traslada el mapa a su sitio exacto.
  Future<void> _searchAddressOnMap() async {
    final query = widget.addressCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _feedback = 'Ingresa una dirección para ubicarla en el mapa.');
      return;
    }
    setState(() {
      _searching = true;
      _feedback = null;
    });

    final found = await const TraccarService().geocodeAddress(query);
    if (!mounted) return;
    setState(() => _searching = false);

    if (found != null) {
      _updatePosition(found);
      setState(() => _feedback = 'Ubicación localizada con éxito.');
    } else {
      setState(() => _feedback = 'No se encontró la dirección. Toca el punto exacto en el mapa.');
    }
  }

  /// QUÉ HACE: Lee el sensor GPS del móvil y coloca el marcador en la posición física actual.
  Future<void> _useCurrentGps() async {
    setState(() {
      _searching = true;
      _feedback = null;
    });
    try {
      final pos = await const LocationService().attendancePosition();
      final pt = LatLng(pos.latitude, pos.longitude);
      final addr = await const TraccarService().reverseGeocode(pt.latitude, pt.longitude);
      if (!mounted) return;
      if (addr != null && addr.isNotEmpty) {
        widget.addressCtrl.text = addr;
      }
      _updatePosition(pt, newAddress: addr);
      setState(() => _feedback = 'GPS detectado: ${_point.latitude.toStringAsFixed(4)}, ${_point.longitude.toStringAsFixed(4)}');
    } catch (_) {
      if (mounted) setState(() => _feedback = 'No se obtuvo señal GPS en este móvil.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de dirección con acción directa de búsqueda tipo Google Maps
        TextFormField(
          controller: widget.addressCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Dirección o Sede de Trabajo',
            hintText: 'Ej. Calle 25 # 20-30, Dosquebradas',
            prefixIcon: const Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 20),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(CupertinoIcons.search, color: AppColors.primary),
                    tooltip: 'Buscar en mapa',
                    onPressed: _searchAddressOnMap,
                  ),
            filled: true,
            fillColor: context.cSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.cGray4.withValues(alpha: 0.5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          onFieldSubmitted: (_) => _searchAddressOnMap(),
        ),
        const SizedBox(height: 8),

        // Botonera de acciones rápidas para el mapa
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _searching ? null : _searchAddressOnMap,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(CupertinoIcons.search_circle_fill, size: 16, color: AppColors.primary),
                label: const Text('Ubicar en Mapa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _searching ? null : _useCurrentGps,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(CupertinoIcons.location_fill, size: 16, color: AppColors.success),
                label: const Text('Mi GPS Actual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ),
          ],
        ),

        if (_feedback != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _feedback!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _feedback!.contains('éxito') || _feedback!.contains('GPS') ? AppColors.success : AppColors.systemRed,
              ),
            ),
          ),
        ],

        // Visor de mapa interactivo con capa satélite/calles Google Maps
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: widget.mapHeight,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 16.0,
                    onTap: (_, tappedPt) async {
                      final addr = await const TraccarService().reverseGeocode(tappedPt.latitude, tappedPt.longitude);
                      if (!mounted) return;
                      if (addr != null && addr.isNotEmpty) {
                        widget.addressCtrl.text = addr;
                      }
                      _updatePosition(tappedPt, newAddress: addr);
                    },
                  ),
                  children: [
                    const MapBaseTileLayer(style: MapCartoStyle.streets),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _point,
                          useRadiusInMeter: true,
                          radius: widget.radiusMeters,
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point,
                          width: 38,
                          height: 38,
                          child: const Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 6,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${_point.latitude.toStringAsFixed(4)}, ${_point.longitude.toStringAsFixed(4)} (Toca para mover)',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
