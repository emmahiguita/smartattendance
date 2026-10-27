// ============================================================================
// ARCHIVO: zone_dialog.dart
// QUÉ HACE: Formulario completo de Geocerca GPS (`work_zones`) con dirección
//           física real, geocodificación inversa y delimitación en mapa.
// CÓMO FUNCIONA: Captura ubicación GPS real o toque en mapa, resuelve dirección
//                física y guarda en SQLite vía `LocalAdminStore.saveZone`.
// POR QUÉ: Garantiza recolección de datos real y código limpio (< 190 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'local_providers.dart';

/// Componente modal para crear o editar una Geocerca GPS administrativa.
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
  LatLng? _point;
  bool _busy = false;
  String? _error;

  double get _visualRadius {
    final v = double.tryParse(_radius.text);
    return v == null || !v.isFinite ? 100 : v.clamp(20, 50000).toDouble();
  }

  /// QUÉ HACE: Precarga nombre, dirección, radio y coordenadas si se edita una zona.
  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    if (z != null) {
      _name.text = z['name'] as String;
      _address.text = z['address'] as String? ?? '';
      _radius.text = '${z['radius_m']}';
      _point = LatLng((z['latitude'] as num).toDouble(), (z['longitude'] as num).toDouble());
    }
  }

  /// QUÉ HACE: Libera los controladores de texto al cerrar el diálogo.
  @override
  void dispose() { _name.dispose(); _address.dispose(); _radius.dispose(); super.dispose(); }

  /// QUÉ HACE: Convierte coordenadas GPS en una dirección física legible.
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 2));
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        final parts = [p.street, p.locality ?? p.subAdministrativeArea, p.administrativeArea].where((s) => s != null && s.isNotEmpty);
        if (parts.isNotEmpty) setState(() => _address.text = parts.join(', '));
      }
    } catch (_) {}
  }

  /// QUÉ HACE: Captura la posición GPS real del dispositivo y resuelve su dirección.
  Future<void> _locate() async {
    setState(() => (_busy = true, _error = null));
    try {
      final gps = await const LocationService().attendancePosition();
      if (mounted) {
        setState(() => _point = LatLng(gps.latitude, gps.longitude));
        await _reverseGeocode(gps.latitude, gps.longitude);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo obtener GPS.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// QUÉ HACE: Valida y guarda la geocerca en SQLite exigiendo permisos de Admin.
  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _point == null) {
      setState(() => _error = _name.text.trim().isEmpty ? 'Ingresa el nombre oficial de la sede.' : 'Selecciona el centro GPS de la geocerca.');
      return;
    }
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).saveZone({
        'name': _name.text.trim(),
        'address': _address.text.trim().isNotEmpty ? _address.text.trim() : 'Dosquebradas, Risaralda',
        'latitude': _point!.latitude,
        'longitude': _point!.longitude,
        'radius_m': double.tryParse(_radius.text) ?? 100,
      }, id: widget.zone?['id'] as int?);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo guardar la zona.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// QUÉ HACE: Elimina la geocerca si no tiene cuadrillas activas vinculadas.
  Future<void> _delete() async {
    final id = widget.zone?['id'] as int?;
    if (id == null) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar Geocerca'),
        content: Text('¿Deseas eliminar la geocerca "${_name.text}"?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => (_busy = true, _error = null));
      try {
        await ref.read(localAdminStoreProvider).deleteZone(id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo eliminar la zona.');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: IosFloatingModal(
          title: widget.zone == null ? 'Nueva Geocerca' : 'Editar Geocerca',
          isSaving: _busy,
          errorMessage: _error,
          onSave: _save,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            IosFormGroup(header: 'Datos de Identificación y Perímetro', children: [
              IosFormFieldRow(label: 'Nombre Sede', placeholder: 'Ej. Sede Principal Operativa', controller: _name, textCapitalization: TextCapitalization.words),
              IosFormFieldRow(label: 'Dirección Real', placeholder: 'Ej. Calle 25 # 20-30, Dosquebradas', controller: _address, textCapitalization: TextCapitalization.sentences),
              IosFormFieldRow(label: 'Radio (m)', placeholder: '20 – 50000 metros', controller: _radius, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              InkWell(
                onTap: _busy ? null : _locate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(CupertinoIcons.location_fill, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Autodetectar GPS y dirección', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
                    if (_point != null) Text('${_point!.latitude.toStringAsFixed(4)}, ${_point!.longitude.toStringAsFixed(4)}', style: TextStyle(fontSize: 11, color: context.cTextSecondary)),
                  ]),
                ),
              ),
            ]),
            if (_point != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 155,
                  child: FlutterMap(
                    options: MapOptions(initialCenter: _point!, initialZoom: 15.5, onTap: (_, pt) { setState(() => _point = pt); _reverseGeocode(pt.latitude, pt.longitude); }),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'io.smartattendance.attendance'),
                      CircleLayer(circles: [CircleMarker(point: _point!, useRadiusInMeter: true, radius: _visualRadius, color: AppColors.primary.withValues(alpha: 0.16), borderColor: AppColors.primary, borderStrokeWidth: 2)]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text('Toca el mapa para ajustar centro y dirección física.', style: TextStyle(fontSize: 10.5, color: context.cTextSecondary)),
            ],
            if (widget.zone != null) ...[
              const SizedBox(height: 16),
              CupertinoButton(
                color: AppColors.systemRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: _busy ? null : _delete,
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.trash, size: 15, color: AppColors.systemRed), SizedBox(width: 6), Text('Eliminar Geocerca', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemRed))]),
              ),
            ],
          ]),
        ),
      );
}
