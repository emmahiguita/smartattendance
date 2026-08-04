// lib/features/auth/presentation/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../viewmodels/login_viewmodel.dart' show authRepositoryProvider;

/// RecuperaciÃ³n REAL de contraseÃ±a: POST /auth/reset-password.
/// Identidad verificada server-side con cÃ©dula + correo registrado
/// (sin envÃ­o de email â€” no requiere SMTP).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _done = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _serverMessage = '';

  @override
  void dispose() {
    _cedulaController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final repository = ref.read(authRepositoryProvider);
      final mensaje = await repository.resetPassword(
        cedula: _cedulaController.text,
        correo: _correoController.text,
        newPassword: _passwordController.text,
        code: _codeController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _done = true;
        _serverMessage = mensaje;
      });
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(ErrorHandler.handle(e).message);
    } finally {
      if (mounted && !_done) setState(() => _isLoading = false);
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
          'Recuperar ContraseÃ±a',
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _done ? _successCard() : _formCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _successCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.systemGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                size: 48, color: AppColors.systemGreen),
          ),
          const SizedBox(height: 20),
          Text(
            'ContraseÃ±a actualizada',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.cTextPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _serverMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.cTextSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Ir a iniciar sesiÃ³n',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restablece tu contraseÃ±a',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.cTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Verificamos tu identidad con la cÃ©dula y el correo registrados en tu cuenta.',
              style: TextStyle(
                  fontSize: 13, color: context.cTextSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Text('CÃ©dula de Identidad',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15),
              decoration: _decoration('Ej: 1007331963', Icons.badge),
              validator: (v) => InputValidators.validateCedula(v),
            ),
            const SizedBox(height: 16),
            const Text('Correo registrado',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15),
              decoration: _decoration('correo@empresa.com', Icons.mail),
              validator: (v) => InputValidators.validateEmail(v),
            ),
            const SizedBox(height: 16),
            const Text('Nueva contraseÃ±a',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 15),
              decoration:
                  _decoration('MÃ­nimo 6 caracteres', Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'MÃ­nimo 6 caracteres' : null,
            ),
            const SizedBox(height: 16),
            const Text('Confirmar nueva contraseÃ±a',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              style: const TextStyle(fontSize: 15),
              decoration:
                  _decoration('Repite la contraseÃ±a', Icons.lock_open).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => (v != _passwordController.text)
                  ? 'Las contraseÃ±as no coinciden'
                  : null,
            ),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: _isLoading ? null : () async { if (_cedulaController.text.isEmpty || _correoController.text.isEmpty) { _showError('Ingresa cédula y correo primero'); return; } setState(() => _isLoading = true); try { final ds = ref.read(authRepositoryProvider); await ds.requestPasswordResetCode(cedula: _cedulaController.text, correo: _correoController.text); if (mounted) _showError('Código enviado al correo registrado.'); } catch (e) { if (mounted) _showError(ErrorHandler.handle(e).message); } finally { if (mounted) setState(() => _isLoading = false); } }, icon: const Icon(Icons.email_outlined), label: const Text('Enviar código al correo')),
            const SizedBox(height: 8),            TextFormField(controller: _codeController, keyboardType: TextInputType.number, decoration: _decoration('Código de 6 dígitos recibido por correo', Icons.verified), validator: (v) => (v == null || v.length != 6) ? 'Ingresa el código OTP' : null),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Restablecer contraseÃ±a',
              expanded: true,
              isLoading: _isLoading,
              onPressed: _handleReset,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
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
      );

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
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


