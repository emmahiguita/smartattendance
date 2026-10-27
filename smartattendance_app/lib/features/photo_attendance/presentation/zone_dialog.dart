// ============================================================================
// ARCHIVO: zone_dialog.dart
// QUÉ HACE: Formulario interactivo de Geocerca GPS (`work_zones`) con visor de
//           mapa siempre visible, búsqueda de dirección física real hacia
//           coordenadas (`geocodeAddress`) y geocodificación inversa al tocar.
// CÓMO FUNCIONA:
// 1. Muestra siempre el mapa interactivo (centrado en la geocerca o Dosquebradas).
// 2. Permite escribir una dirección real y pulsar "Buscar dirección en mapa"
//    para ubicar automáticamente el punto GPS mediante `TraccarService`.
// 3. Permite tocar cualquier punto del mapa o usar "Autodetectar GPS actual".
// POR QUÉ: Garantiza que las direcciones y ubicaciones asignadas sean 100%
//          reales, verificables y visuales (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'local_providers.dart';

class ZoneDialog extends ConsumerStatefulWidget {
  const ZoneDialog({super.key, this.zone});
  final Map<String, Object?>? zone;
  @override
  ConsumerState<ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends ConsumerState<ZoneDialog> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _radius = TextEditingController(text: '100');
  final _mapController = MapController();
  LatLng _point = const LatLng(4.8333, -75.6833);
  bool _busy = false;
  String? _error;

  double get _visualRadius {
    final v = double.tryParse(_radius.text);
    return v == null || !v.isFinite ? 100 : v.clamp(20, 50000).toDouble();
  }

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    if (z != null) {
      _name.text = (z['name'] ?? '').toString();
      _address.text = (z['address'] ?? '').toString();
      _radius.text = '${z['radius_m'] ?? 100}';
      _point = LatLng((z['latitude'] as num).toDouble(), (z['longitude'] as num).toDouble());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _radius.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _moveMap(LatLng pt) {
    setState(() => _point = pt);
    try { _mapController.move(pt, 16.5); } catch (_) {}
  }

  /// QUÉ HACE: Busca la dirección física escrita y mueve el mapa a sus coordenadas.
  Future<void> _searchTypedAddress() async {
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'Escribe una dirección real para buscarla en el mapa.');
      return;
    }
    setState(() => (_busy = true, _error = null));
    final found = await const TraccarService().geocodeAddress(_address.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (found != null) {
      _moveMap(found);
      if (_name.text.trim().isEmpty) _name.text = _address.text.trim();
    } else {
      setState(() => _error = 'No se encontró la dirección. Toca el punto exacto en el mapa.');
    }
  }

  /// QUÉ HACE: Captura el GPS real del teléfono y actualiza mapa y dirección.
  Future<void> _locateGps() async {
    setState(() => (_busy = true, _error = null));
    try {
      final gps = await const LocationService().attendancePosition();
      final pt = LatLng(gps.latitude, gps.longitude);
      if (mounted) _moveMap(pt);
      final addr = await const TraccarService().reverseGeocode(pt.latitude, pt.longitude);
      if (mounted && addr != null) setState(() => _address.text = addr);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo obtener el GPS del teléfono.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el nombre oficial de la sede o geocerca.');
      return;
    }
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).saveZone({
        'name': _name.text.trim(),
        'address': _address.text.trim().isNotEmpty ? _address.text.trim() : 'Dosquebradas, Risaralda',
        'latitude': _point.latitude,
        'longitude': _point.longitude,
        'radius_m': double.tryParse(_radius.text) ?? 100,
      }, id: widget.zone?['id'] as int?);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo guardar la geocerca.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.zone?['id'] as int?;
    if (id == null) return;
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).deleteZone(id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo eliminar.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: IosFloatingModal(
          title: widget.zone == null ? 'Nueva Geocerca GPS' : 'Editar Geocerca GPS',
          isSaving: _busy,
          errorMessage: _error,
          onSave: _save,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            IosFormGroup(header: 'Identificación y Dirección Real', children: [
              IosFormFieldRow(label: 'Nombre Sede', placeholder: 'Ej. Planta Operativa Dosquebradas', controller: _name, textCapitalization: TextCapitalization.words),
              IosFormFieldRow(label: 'Dirección Real', placeholder: 'Ej. Calle 25 # 20-30, Dosquebradas', controller: _address, textCapitalization: TextCapitalization.sentences),
              IosFormFieldRow(label: 'Radio (m)', placeholder: '20 – 50000 metros', controller: _radius, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              Row(children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _searchTypedAddress,
                    icon: const Icon(CupertinoIcons.search, size: 15, color: AppColors.primary),
                    label: const Text('Buscar dirección', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _busy ? null : _locateGps,
                    icon: const Icon(CupertinoIcons.location_fill, size: 15, color: AppColors.success),
                    label: const Text('Mi GPS actual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 175,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 16.0,
                    onTap: (_, pt) async {
                      _moveMap(pt);
                      final addr = await const TraccarService().reverseGeocode(pt.latitude, pt.longitude);
                      if (mounted && addr != null) setState(() => _address.text = addr);
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'io.smartattendance.attendance'),
                    CircleLayer(circles: [CircleMarker(point: _point, useRadiusInMeter: true, radius: _visualRadius, color: AppColors.primary.withValues(alpha: 0.18), borderColor: AppColors.primary, borderStrokeWidth: 2)]),
                    MarkerLayer(markers: [Marker(point: _point, width: 36, height: 36, child: const Icon(CupertinoIcons.location_solid, color: AppColors.primary, size: 28))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('Coordenadas: ${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)} • Toca el mapa para mover la geocerca', style: TextStyle(fontSize: 10.5, color: context.cTextSecondary)),
            if (widget.zone != null) ...[
              const SizedBox(height: 10),
              CupertinoButton(
                color: AppColors.systemRed.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(vertical: 8),
                onPressed: _busy ? null : _delete,
                child: const Text('Eliminar Geocerca', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.systemRed)),
              ),
            ],
          ]),
        ),
      );
}
