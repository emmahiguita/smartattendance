import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/location_service.dart';
import 'local_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Edita una zona real desde el mapa. Sin GPS ni centro guardado no inventa una
/// ciudad: permite solicitar ubicación. El radio dibujado es el que se valida.
class ZoneDialog extends ConsumerStatefulWidget {
  const ZoneDialog({super.key, this.zone});
  final Map<String, Object?>? zone;
  @override
  ConsumerState<ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends ConsumerState<ZoneDialog> {
  final _name = TextEditingController(), _radius = TextEditingController();
  LatLng? _point;
  bool _busy = false;
  String? _error;
  double get _visualRadius {
    final value = double.tryParse(_radius.text);
    return value == null || !value.isFinite
        ? 0
        : value.clamp(0, 50000).toDouble();
  }

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    if (z != null) {
      _name.text = z['name'] as String;
      _radius.text = '${z['radius_m']}';
      _point = LatLng((z['latitude'] as num).toDouble(),
          (z['longitude'] as num).toDouble());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final gps = await const LocationService().attendancePosition();
      if (mounted) setState(() => _point = LatLng(gps.latitude, gps.longitude));
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is FormatException ? e.message : 'No se pudo obtener GPS.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_point == null) {
      setState(() => _error = 'Selecciona el centro de la zona.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(localAdminStoreProvider).saveZone({
        'name': _name.text.trim(),
        'latitude': _point!.latitude,
        'longitude': _point!.longitude,
        'radius_m': double.tryParse(_radius.text) ?? 0,
      }, id: widget.zone?['id'] as int?);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is FormatException ? e.message : 'No se pudo guardar la zona.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(widget.zone == null ? 'Crear zona' : 'Editar zona'),
        content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  TextField(
                      controller: _name,
                      maxLength: 100,
                      decoration:
                          const InputDecoration(labelText: 'Nombre de zona')),
                  TextField(
                      controller: _radius,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Radio en metros (20–50000)')),
                  OutlinedButton.icon(
                      onPressed: _busy ? null : _locate,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Usar ubicación actual')),
                  if (_point != null) ...[
                    const Text('Toca el mapa para ajustar el centro.'),
                    SizedBox(
                        height: 180,
                        child: FlutterMap(
                            options: MapOptions(
                                initialCenter: _point!,
                                initialZoom: 15,
                                onTap: (_, point) =>
                                    setState(() => _point = point)),
                            children: [
                              TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'io.smartattendance.attendance'),
                              CircleLayer(circles: [
                                CircleMarker(
                                    point: _point!,
                                    useRadiusInMeter: true,
                                    radius: _visualRadius,
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderColor: Colors.blue,
                                    borderStrokeWidth: 2)
                              ]),
                            ])),
                    TextButton(
                        onPressed: () => launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/copyright')),
                        child: const Text('© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 11))),
                    Text(
                        '${_point!.latitude.toStringAsFixed(6)}, ${_point!.longitude.toStringAsFixed(6)}'),
                  ],
                  if (_error != null)
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ]))),
        actions: [
          TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Procesando…' : 'Guardar'))
        ],
      ));
}
