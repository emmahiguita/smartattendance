// ============================================================================
// ARCHIVO: forgot_password_screen.dart
// QUÉ HACE: Pantalla de recuperación y restablecimiento seguro de contraseña.
// CÓMO FUNCIONA:
// 1. Solicita código OTP al correo corporativo según la cédula.
// 2. Valida cédula, correo, OTP y nueva contraseña contra la API o SQLite.
// 3. Renderiza tarjeta Liquid Glass en Modo Oscuro sin textos malformados.
// POR QUÉ: Restaura tipografía limpia y diseño Material Expressive (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../viewmodels/login_viewmodel.dart' show authRepositoryProvider;
import '../widgets/forgot_password_success_card.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isRequestingCode = false;
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

  // QUÉ HACE: Solicita el envío del código OTP de 6 dígitos al correo registrado.
  Future<void> _requestCode() async {
    final ced = _cedulaController.text.trim();
    final mail = _correoController.text.trim();
    if (ced.isEmpty || mail.isEmpty) {
      _showMessage('Ingresa cédula y correo primero para recibir el código.', isError: true);
      return;
    }
    setState(() => _isRequestingCode = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final msg = await repo.requestPasswordResetCode(cedula: ced, correo: mail);
      _showMessage(msg.isNotEmpty ? msg : 'Código enviado a tu correo corporativo.', isError: false);
    } catch (e) {
      _showMessage(ErrorHandler.handle(e).message, isError: true);
    } finally {
      if (mounted) setState(() => _isRequestingCode = false);
    }
  }

  // QUÉ HACE: Valida las credenciales y ejecuta el restablecimiento en el repositorio.
  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final repo = ref.read(authRepositoryProvider);
      final msg = await repo.resetPassword(
        cedula: _cedulaController.text.trim(),
        correo: _correoController.text.trim(),
        newPassword: _passwordController.text,
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _done = true;
        _serverMessage = msg;
      });
    } on AppException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage(ErrorHandler.handle(e).message, isError: true);
    } finally {
      if (mounted && !_done) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.systemRed : AppColors.systemGreen,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = context.cPrimary;

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
          'Recuperar Contraseña',
          style: TextStyle(
            fontFamily: AppTheme.editorialSerif,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.cTextPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: context.cGradientBackground)),
          if (isDark) ...[
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [primaryColor.withValues(alpha: 0.16), Colors.transparent]),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _done ? ForgotPasswordSuccessCard(message: _serverMessage) : _buildFormCard(primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Color primaryColor) {
    return IosGlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restablece tu contraseña',
              style: TextStyle(
                fontFamily: AppTheme.editorialSerif,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.cTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verificamos tu identidad con la cédula y el correo registrados en tu cuenta.',
              style: TextStyle(fontSize: 13, color: context.cTextSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            _buildFieldLabel('Cédula de Identidad (CC)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: InputValidators.validateCedula,
              decoration: const InputDecoration(hintText: 'Ej: 1007331963', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Correo institucional'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              validator: InputValidators.validateEmail,
              decoration: const InputDecoration(hintText: 'correo@buentiempo.app', prefixIcon: Icon(Icons.mail_outline, size: 20)),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isRequestingCode ? null : _requestCode,
                icon: _isRequestingCode
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.send_rounded, size: 16, color: primaryColor),
                label: Text('Enviar código OTP al correo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryColor)),
              ),
            ),
            const SizedBox(height: 6),
            _buildFieldLabel('Código de 6 dígitos OTP'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (v) => (v == null || v.trim().length != 6) ? 'Ingresa el código OTP de 6 dígitos' : null,
              decoration: const InputDecoration(hintText: '123456', counterText: '', prefixIcon: Icon(Icons.pin_outlined, size: 20)),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Nueva contraseña'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              decoration: InputDecoration(
                hintText: 'Mínimo 6 caracteres',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('Confirmar nueva contraseña'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              validator: (v) => (v != _passwordController.text) ? 'Las contraseñas no coinciden' : null,
              decoration: InputDecoration(
                hintText: 'Repite la contraseña',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Restablecer contraseña', expanded: true, isLoading: _isLoading, onPressed: _handleReset),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.cTextPrimary));
  }
}
