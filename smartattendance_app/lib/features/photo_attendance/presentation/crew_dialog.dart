import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_providers.dart';

/// Configura un equipo, sus responsables, fechas y una geocerca opcional.
class CrewDialog extends ConsumerStatefulWidget {
  const CrewDialog({super.key, this.crew, required this.zones});
  final Map<String, Object?>? crew;
  final List<Map<String, Object?>> zones;
  @override
  ConsumerState<CrewDialog> createState() => _CrewDialogState();
}

class _CrewDialogState extends ConsumerState<CrewDialog> {
  final _name = TextEditingController();
  final _supervisor = TextEditingController();
  final _alternate = TextEditingController();
  String? _from, _until, _error;
  int? _zone;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final team = widget.crew;
    if (team == null) return;
    _name.text = team['name'] as String;
    _supervisor.text = team['supervisor_document'] as String;
    _alternate.text = team['driver_document'] as String? ?? '';
    _zone = team['zone_id'] as int?;
    _from = team['valid_from'] as String;
    _until = team['valid_until'] as String;
  }

  @override
  void dispose() {
    _name.dispose();
    _supervisor.dispose();
    _alternate.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final current = start ? _from : _until;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current ?? '') ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final value = date.toIso8601String().split('T').first;
    setState(() => start ? _from = value : _until = value);
  }

  Future<void> _save() async {
    if (_from == null || _until == null) {
      setState(() => _error = 'Selecciona el período del equipo.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(localAdminStoreProvider).saveCrew({
        'name': _name.text.trim(),
        'supervisor_document': _supervisor.text.trim(),
        'driver_document': _alternate.text.trim(),
        'zone_id': _zone,
        'valid_from': _from,
        'valid_until': _until,
      }, id: widget.crew?['id'] as int?);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'No se pudo guardar el equipo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: AlertDialog(
          title: Text(widget.crew == null ? 'Crear equipo' : 'Editar equipo'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _name,
                    maxLength: 100,
                    decoration:
                        const InputDecoration(labelText: 'Nombre del equipo'),
                  ),
                  TextField(
                    controller: _supervisor,
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                    decoration: const InputDecoration(
                        labelText: 'Cédula del supervisor o encargado'),
                  ),
                  TextField(
                    controller: _alternate,
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                    decoration: const InputDecoration(
                        labelText: 'Responsable adicional (opcional)'),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _zone,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Geocerca (opcional)'),
                    items: [
                      const DropdownMenuItem<int>(
                          value: null, child: Text('Sin geocerca')),
                      for (final zone in widget.zones)
                        DropdownMenuItem(
                            value: zone['id'] as int,
                            child: Text(zone['name'] as String)),
                    ],
                    onChanged:
                        _busy ? null : (value) => setState(() => _zone = value),
                  ),
                  Wrap(spacing: 8, children: [
                    TextButton(
                        onPressed: _busy ? null : () => _pickDate(true),
                        child: Text('Desde: ${_from ?? 'Elegir'}')),
                    TextButton(
                        onPressed: _busy ? null : () => _pickDate(false),
                        child: Text('Hasta: ${_until ?? 'Elegir'}')),
                  ]),
                  if (_zone == null)
                    const Text(
                        'Sin geocerca, las marcas guardan GPS si está disponible, pero no restringen la ubicación.'),
                  if (_error != null)
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Guardando…' : 'Guardar')),
          ],
        ),
      );
}
