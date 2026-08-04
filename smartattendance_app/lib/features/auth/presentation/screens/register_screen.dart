// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../viewmodels/login_viewmodel.dart' show authRepositoryProvider;

/// Registro REAL de empleado: POST /auth/register.
/// El servidor crea la cuenta (contraseña bcrypt) y retorna tokens —
/// la sesión queda iniciada automáticamente.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cargoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  DateTime? _fechaNacimiento;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _cargoController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Calendario para fecha de nacimiento (rango realista 18–80 años).
  Future<void> _pickFechaNacimiento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      locale: const Locale('es'),
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final repository = ref.read(authRepositoryProvider);
      final (_, user) = await repository.register(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        cedula: _cedulaController.text,
        correo: _correoController.text,
        password: _passwordController.text,
        telefono: _telefonoController.text,
        cargo: _cargoController.text,
        fechaNacimiento: _fechaNacimiento == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_fechaNacimiento!),
      );

      // Sesión iniciada con los tokens REALES que retornó el servidor.
      await ref.read(sessionControllerProvider.notifier).authenticate(user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Cuenta creada. Bienvenido, ${user.nombre}.')),
            ],
          ),
          backgroundColor: AppColors.systemGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go(AppRoutes.home);
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(ErrorHandler.handle(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final fechaLabel = _fechaNacimiento == null
        ? 'Selecciona tu fecha de nacimiento'
        : DateFormat('dd/MM/yyyy').format(_fechaNacimiento!);

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.cTextPrimary),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: Text(
          'Registro de Usuario',
          style: TextStyle(
            color: context.cTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.cBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crea tu cuenta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.cTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tus datos se registran en el sistema de asistencia',
                        style: TextStyle(
                            fontSize: 13, color: context.cTextSecondary),
                      ),
                      const SizedBox(height: 24),

                      _field(
                        label: 'Nombre',
                        controller: _nombreController,
                        hint: 'Ej: Emmanuel',
                        icon: Icons.person,
                        validator: (v) =>
                            InputValidators.validateRequired(v, 'Nombre'),
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Apellido',
                        controller: _apellidoController,
                        hint: 'Ej: Higuita',
                        icon: Icons.badge,
                        validator: (v) =>
                            InputValidators.validateRequired(v, 'Apellido'),
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Cédula de Identidad',
                        controller: _cedulaController,
                        hint: 'Ej: 1007331963',
                        icon: Icons.badge,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) => InputValidators.validateCedula(v),
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Correo Electrónico',
                        controller: _correoController,
                        hint: 'correo@empresa.com',
                        icon: Icons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => InputValidators.validateEmail(v),
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Teléfono',
                        controller: _telefonoController,
                        hint: 'Ej: +57 300 123 4567',
                        icon: Icons.call,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Cargo / Posición',
                        controller: _cargoController,
                        hint: 'Ej: Desarrollador / Analista',
                        icon: Icons.work,
                      ),
                      const SizedBox(height: 16),

                      // ── Fecha de nacimiento con calendario ──
                      const Text('Fecha de Nacimiento',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickFechaNacimiento,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration:
                              _decoration('', Icons.calendar_month).copyWith(
                            suffixIcon: Icon(Icons.expand_more,
                                size: 20, color: context.cGray),
                          ),
                          child: Text(
                            fechaLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _fechaNacimiento == null
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: _fechaNacimiento == null
                                  ? context.cGray2
                                  : context.cTextPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Contraseña',
                        controller: _passwordController,
                        hint: 'Mínimo 6 caracteres',
                        icon: Icons.lock,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _field(
                        label: 'Confirmar Contraseña',
                        controller: _confirmController,
                        hint: 'Repite la contraseña',
                        icon: Icons.lock_open,
                        obscure: _obscureConfirm,
                        suffix: IconButton(
                          icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) => (v != _passwordController.text)
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Registrarme',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text.rich(
                            TextSpan(
                              text: '¿Ya tienes una cuenta? ',
                              style: TextStyle(
                                  color: context.cTextSecondary, fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: 'Inicia sesión',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscure,
          style: const TextStyle(fontSize: 15),
          decoration: _decoration(hint, icon).copyWith(suffixIcon: suffix),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: TextStyle(color: context.cGray2, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: context.cGray),
      filled: true,
      fillColor: context.cBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.cBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.cBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
