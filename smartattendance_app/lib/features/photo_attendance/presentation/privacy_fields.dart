import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_providers.dart';

/// Datos reales del responsable definidos por el administrador. No genera una
/// autorización ficticia ni presenta estos campos como certificación legal.
class PrivacyFields extends ConsumerStatefulWidget {
  const PrivacyFields({super.key});
  @override
  ConsumerState<PrivacyFields> createState() => _PrivacyFieldsState();
}

class _PrivacyFieldsState extends ConsumerState<PrivacyFields> {
  static const _labels = {
    'company': 'Razón social del responsable',
    'email': 'Correo para ejercer derechos',
    'phone': 'Teléfono de contacto',
    'address': 'Dirección del responsable',
    'purpose': 'Finalidad y usos autorizados',
    'retention': 'Criterio o plazo de conservación',
  };
  late final _fields = {
    for (final key in _labels.keys) key: TextEditingController()
  };
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await ref.read(localAdminStoreProvider).setting('privacy');
      if (!mounted) return;
      if (text != null) {
        final values = jsonDecode(text) as Map<String, dynamic>;
        for (final e in _fields.entries) {
          e.value.text = values[e.key] as String? ?? '';
        }
      }
    } catch (_) {
      if (mounted) _error = 'No se pudo cargar la configuración.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(localAdminStoreProvider).savePrivacy(
          {for (final e in _fields.entries) e.key: e.value.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos del responsable guardados.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e is FormatException ? e.message : 'No se pudo guardar.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
          title: const Text('Tratamiento de datos'),
          leading: const Icon(Icons.privacy_tip_outlined),
          children: [
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                          'Se guardan documento, foto de evidencia, horas y ubicación cuando el equipo tiene geocerca. '
                          'El trabajador puede conocer, actualizar y rectificar sus datos y solicitar prueba de autorización; '
                          'la revocatoria y supresión proceden en los casos aplicables. La autorización de datos sensibles es facultativa. '
                          'La empresa debe ofrecer un procedimiento alternativo cuando corresponda.'),
                      if (_loading) const LinearProgressIndicator(),
                      for (final e in _fields.entries)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                                controller: e.value,
                                enabled: !_loading && !_saving,
                                maxLength:
                                    e.key == 'purpose' || e.key == 'retention'
                                        ? 1000
                                        : 200,
                                maxLines:
                                    e.key == 'purpose' || e.key == 'retention'
                                        ? 3
                                        : 1,
                                decoration: InputDecoration(
                                    labelText: _labels[e.key]))),
                      const Text(
                          'La autorización individual y su soporte se registran al asignar cada trabajador. '
                          'Definir un plazo aquí no elimina automáticamente registros laborales.'),
                      if (_error != null)
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      FilledButton(
                          onPressed: _loading || _saving ? null : _save,
                          child: Text(_saving
                              ? 'Guardando…'
                              : 'Guardar responsable y política')),
                    ]))
          ]);
}
