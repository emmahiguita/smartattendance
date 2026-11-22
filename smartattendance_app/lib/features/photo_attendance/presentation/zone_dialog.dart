// ============================================================================
// ARCHIVO: zone_dialog.dart
// QUÉ HACE: Formulario interactivo de Geocerca GPS (`work_zones`) con visor de
//           mapa multi-plano siempre visible, búsqueda de dirección física real
//           hacia coordenadas (`geocodeAddress`) y geocodificación inversa.
// CÓMO FUNCIONA: Muestra el mapa interactivo con selector de planos (Calles,
//                Satélite, Relieve, Nocturno), controles de zoom y GPS actual.
// POR QUÉ: Garantiza estabilidad cartográfica en iOS y Android (< 195 líneas).
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
import '../../attendance/presentation/widgets/map_carto_style.dart';
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
  MapCartoStyle? _manualStyle;
  bool _pointSelected = false, _busy = false;
  int _tapVersion = 0;
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
      _pointSelected = true;
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

  void _moveMap(LatLng pt, {double zoom = 16.5}) {
    setState(() => (_point = pt, _pointSelected = true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(pt, zoom);
      } catch (_) {}
    });
  }

  void _zoomBy(double delta) {
    try {
      final cam = _mapController.camera;
      _mapController.move(cam.center, (cam.zoom + delta).clamp(4.0, 20.0));
    } catch (_) {}
  }

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
    final radius = double.tryParse(_radius.text.trim());
    if (!_pointSelected || radius == null || !radius.isFinite || radius < 20 || radius > 50000) {
      setState(() => _error = 'Selecciona la ubicación en el mapa o con GPS e ingresa un radio de 20 a 50000 metros.');
      return;
    }
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).saveZone({
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'latitude': _point.latitude,
        'longitude': _point.longitude,
        'radius_m': radius,
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
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final style = _manualStyle ?? (isDark ? MapCartoStyle.dark : MapCartoStyle.streets);

    return PopScope(
      canPop: !_busy,
      child: IosFloatingModal(
        title: widget.zone == null ? 'Nueva Geocerca GPS' : 'Detalle de Geocerca GPS',
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
                  icon: const Icon(CupertinoIcons.search, size: 15, color: Color(0xFF007AFF)),
                  label: const Text('Buscar dirección', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF007AFF))),
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
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 185,
              child: Stack(children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 16.2,
                    minZoom: 4.0,
                    maxZoom: 20.0,
                    onTap: (_, pt) async {
                      final ver = ++_tapVersion;
                      _moveMap(pt);
                      final addr = await const TraccarService().reverseGeocode(pt.latitude, pt.longitude);
                      if (mounted && ver == _tapVersion && addr != null) setState(() => _address.text = addr);
                    },
                  ),
                  children: [
                    MapBaseTileLayer(style: style),
                    CircleLayer(circles: [
                      CircleMarker(
                        point: _point,
                        useRadiusInMeter: true,
                        radius: _visualRadius,
                        color: const Color(0xFF007AFF).withValues(alpha: 0.18),
                        borderColor: const Color(0xFF007AFF),
                        borderStrokeWidth: 2,
                      ),
                    ]),
                    MarkerLayer(markers: [
                      Marker(point: _point, width: 38, height: 38, child: const Icon(CupertinoIcons.location_solid, color: Color(0xFF007AFF), size: 30)),
                    ]),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _manualStyle = style.next),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(style.icon, size: 12, color: const Color(0xFF007AFF)),
                        const SizedBox(width: 4),
                        Text(style.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _zoomChip(context, CupertinoIcons.minus, () => _zoomBy(-1)),
                    const SizedBox(width: 5),
                    _zoomChip(context, CupertinoIcons.plus, () => _zoomBy(1)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 5),
          Text('Coordenadas: ${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)} · Toca el mapa para mover el punto',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.cTextSecondary)),
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

  Widget _zoomChip(BuildContext context, IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 14, color: context.cTextPrimary),
        ),
      );
}
