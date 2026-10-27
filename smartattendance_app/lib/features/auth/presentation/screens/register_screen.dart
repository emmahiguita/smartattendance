// ============================================================================
// ARCHIVO: register_screen.dart
// QUÉ HACE: Pantalla de registro de nuevo colaborador (`POST /auth/register`).
// CÓMO FUNCIONA: Captura datos básicos y bloquea el escalamiento de privilegios
//                forzando que ningún auto-registro pueda asignarse rol de
//                `Administrador` o `Supervisor` (esos roles solo los asigna un
//                Administrador autenticado desde adentro de la aplicación).
// POR QUÉ: Evita auto-promoción de permisos y cumple el límite de < 195 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../data/datasources/local_auth_datasource.dart';
import '../viewmodels/login_viewmodel.dart' show authRepositoryProvider;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController(), _apellido = TextEditingController();
  final _cedula = TextEditingController(), _correo = TextEditingController();
  final _telefono = TextEditingController(), _cargo = TextEditingController(text: 'Colaborador');
  final _password = TextEditingController(), _confirm = TextEditingController();
  DateTime? _fechaNac;
  bool _isLoading = false, _obscurePass = true, _obscureConf = true;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _cedula, _correo, _telefono, _cargo, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _fechaNac = picked);
  }

  /// QUÉ HACE: Sanitiza el cargo en auto-registro para impedir auto-asignación de Admin/Supervisor.
  String _safeCollaboratorRole(String rawCargo) {
    final trimmed = rawCargo.trim();
    if (trimmed.isEmpty || LocalAuthDataSource.isRoleAdmin(trimmed, '')) {
      return 'Colaborador';
    }
    return trimmed;
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final safeCargo = _safeCollaboratorRole(_cargo.text);
      final (_, user) = await ref.read(authRepositoryProvider).register(
            nombre: _nombre.text.trim(),
            apellido: _apellido.text.trim(),
            cedula: _cedula.text.trim(),
            correo: _correo.text.trim(),
            password: _password.text,
            telefono: _telefono.text.trim(),
            cargo: safeCargo,
            fechaNacimiento: _fechaNac == null ? null : DateFormat('yyyy-MM-dd').format(_fechaNac!),
          );
      await ref.read(sessionControllerProvider.notifier).authenticate(user);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(ErrorHandler.handle(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.systemRed, behavior: SnackBarBehavior.floating));
  }

  Widget _field(String label, TextEditingController ctrl, String hint, IconData icon, {TextInputType? type, List<TextInputFormatter>? fmt, String? Function(String?)? val, bool obscure = false, Widget? suffix}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            inputFormatters: fmt,
            obscureText: obscure,
            validator: val,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20, color: context.cGray),
              suffixIcon: suffix,
              filled: true,
              fillColor: context.cBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.cBorder)),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final fechaLabel = _fechaNac == null ? 'Seleccionar fecha' : DateFormat('dd/MM/yyyy').format(_fechaNac!);
    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.cTextPrimary), onPressed: () => context.go(AppRoutes.login)),
        title: Text('Registro de Colaborador', style: TextStyle(color: context.cTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.cBorder)),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Crea tu cuenta operativa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.cTextPrimary)),
                    const SizedBox(height: 4),
                    Text('Los permisos de Supervisor o Administrador solo son asignados internamente por RRHH.', style: TextStyle(fontSize: 12, color: context.cTextSecondary)),
                    const SizedBox(height: 18),
                    _field('Nombre', _nombre, 'Ej: Juan', Icons.person, val: (v) => InputValidators.validateRequired(v, 'Nombre')),
                    _field('Apellido', _apellido, 'Ej: Pérez', Icons.badge, val: (v) => InputValidators.validateRequired(v, 'Apellido')),
                    _field('Cédula de Identidad', _cedula, 'Ej: 1020304050', Icons.credit_card, type: TextInputType.number, fmt: [FilteringTextInputFormatter.digitsOnly], val: InputValidators.validateCedula),
                    _field('Correo Electrónico', _correo, 'correo@empresa.com', Icons.mail, type: TextInputType.emailAddress, val: InputValidators.validateEmail),
                    _field('Teléfono', _telefono, '+57 300 000 0000', Icons.call, type: TextInputType.phone),
                    InkWell(
                      onTap: _pickFecha,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: 'Fecha de Nacimiento', prefixIcon: const Icon(Icons.calendar_month, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          child: Text(fechaLabel),
                        ),
                      ),
                    ),
                    _field('Contraseña', _password, 'Mínimo 6 caracteres', Icons.lock, obscure: _obscurePass, suffix: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, size: 19), onPressed: () => setState(() => _obscurePass = !_obscurePass)), val: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null),
                    _field('Confirmar Contraseña', _confirm, 'Repite la contraseña', Icons.lock_open, obscure: _obscureConf, suffix: IconButton(icon: Icon(_obscureConf ? Icons.visibility_off : Icons.visibility, size: 19), onPressed: () => setState(() => _obscureConf = !_obscureConf)), val: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Registrarme como Colaborador', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
