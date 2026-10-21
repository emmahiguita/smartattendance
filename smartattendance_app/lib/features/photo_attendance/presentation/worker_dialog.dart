import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_providers.dart';

/// Formulario local real, sin usuarios de ejemplo. Libera sus controladores al
/// cerrar y evita doble envío. La validación final también vive en el repositorio.
class WorkerDialog extends ConsumerStatefulWidget {
  const WorkerDialog({super.key});
  @override
  ConsumerState<WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends ConsumerState<WorkerDialog> {
  final _name = TextEditingController();
  final _document = TextEditingController();
  final _job = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _document.dispose();
    _job.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(localPhotoRepositoryProvider)
          .addWorker(_name.text, _document.text, _job.text);
      if (!mounted) return;
      ref.invalidate(localWorkersProvider);
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('Crear trabajador'),
        content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  decoration:
                      const InputDecoration(labelText: 'Nombre completo')),
              const SizedBox(height: 12),
              TextField(
                  controller: _document,
                  keyboardType: TextInputType.number,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'Cédula')),
              const SizedBox(height: 12),
              TextField(
                  controller: _job,
                  maxLength: 100,
                  decoration:
                      const InputDecoration(labelText: 'Cargo (opcional)')),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
            ]))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar'))
        ],
      ));
}
