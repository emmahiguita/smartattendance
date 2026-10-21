import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../../../shared/widgets/control_ai_logo.dart';
import 'admin_access.dart';

/// Identifica al encargado de ESTE dispositivo. Es un perfil local, no una
/// autenticación contra un servidor; nunca fabrica JWT ni usuarios de ejemplo.
class LocalOperatorScreen extends ConsumerStatefulWidget {
  const LocalOperatorScreen({super.key});
  @override
  ConsumerState<LocalOperatorScreen> createState() =>
      _LocalOperatorScreenState();
}

class _LocalOperatorScreenState extends ConsumerState<LocalOperatorScreen> {
  final _name = TextEditingController();
  final _document = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty ||
        !RegExp(r'^\d{3,20}$').hasMatch(_document.text.trim())) {
      setState(() => _error = 'Escribe tu nombre y una cédula válida.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionControllerProvider);
      if(session is SessionAuthenticated&&session.user.isAdmin&&!ref.read(adminAccessProvider)){
        throw const FormatException('Desbloquea la administración para editar el encargado.');
      }
      // El primer perfil configura este dispositivo. Después se conserva el rol;
      // cambiar un nombre no convierte a un encargado en administrador.
      if (session is SessionAuthenticated &&
          !session.user.isAdmin &&
          session.user.cedula != _document.text.trim()) {
        throw const FormatException(
            'Solo el administrador puede cambiar el encargado del dispositivo.');
      }
      await ref.read(sessionControllerProvider.notifier).authenticate(
          UserEntity(
              id: 1,
              nombre: _name.text.trim(),
              apellido: '',
              cedula: _document.text.trim(),
              correo: '',
              cargo: 'Encargado local',
              isAdmin: session is SessionAuthenticated
                  ? session.user.isAdmin
                  : true),
          remember: false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'No se pudo guardar el perfil local.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Center(child: ControlAiLogo(size: 48)),
                            const SizedBox(height: 32),
                            Text('Encargado del dispositivo',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            const Text(
                                'Configura tu perfil local. No necesitas internet para registrar asistencia con fotos.'),
                            const SizedBox(height: 24),
                            TextField(
                                controller: _name,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                    labelText: 'Nombre completo')),
                            const SizedBox(height: 12),
                            TextField(
                                controller: _document,
                                maxLength: 20,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Cédula')),
                            if (_error != null)
                              Text(_error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                            const SizedBox(height: 16),
                            FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(_saving
                                    ? 'Guardando…'
                                    : 'Continuar sin conexión')),
                          ]))))));
}
