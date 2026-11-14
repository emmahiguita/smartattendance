// QUÉ HACE: Permite a un mando autorizado establecer una contraseña local.
// CÓMO: Solicita dos entradas protegidas y delega autorización y guardado al almacén.
// POR QUÉ: Proporciona recuperación real sin códigos ni credenciales compartidas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

class WorkerPasswordDialog extends ConsumerStatefulWidget {
  const WorkerPasswordDialog({super.key, required this.worker});
  final LocalWorker worker;
  static Future<bool?> show(BuildContext context, LocalWorker worker) =>
    showDialog<bool>(context: context, barrierDismissible: false,
      builder: (_) => WorkerPasswordDialog(worker: worker));
  @override
  ConsumerState<WorkerPasswordDialog> createState() => _WorkerPasswordDialogState();
}
class _WorkerPasswordDialogState extends ConsumerState<WorkerPasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController(), _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _password.dispose(); _confirmation.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(localAdminStoreProvider).setWorkerPassword(widget.worker.id, _password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'No se pudo establecer la contraseña.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving,
    child: AlertDialog(
      title: const Text('Establecer contraseña'),
      content: SingleChildScrollView(child: Form(key: _form,
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.worker.name, style: TextStyle(color: context.cTextSecondary)),
          const SizedBox(height: 16),
          TextFormField(controller: _password, obscureText: true,
            autocorrect: false, enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Nueva contraseña',
              helperText: '8 o más caracteres, mayúscula, minúscula y número.',
              helperMaxLines: 3),
            validator: (value) => value == widget.worker.document ?
              'La contraseña debe ser diferente del documento.' :
              InputValidators.validatePassword(value)),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmation, obscureText: true,
            autocorrect: false, enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
            validator: (value) => value == _password.text ? null : 'Las contraseñas no coinciden.'),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: Text(_error!, style: TextStyle(color: context.cTextPrimary))),
        ]))),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar')),
      ],
    ),
  );
}

