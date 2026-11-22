// ============================================================================
// ARCHIVO: login_screen.dart
// QUÉ HACE: Pantalla de inicio de sesión de BuenTiempo con Liquid Glass,
//           acceso con documento y contraseña propia u OAuth Google.
// CÓMO FUNCIONA: Enlaza `LoginFormCard` con `LoginViewModel` y `SessionController`.
// POR QUÉ: Cumple estrictamente la regla modular < 160 líneas bajo Clean Architecture.
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../viewmodels/login_viewmodel.dart';
import '../widgets/login_form_card.dart';
import '../widgets/login_header_logo.dart';
import '../widgets/login_role_toggle.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberSession = true;
  LoginRole _selectedRole = LoginRole.user;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final saved = await ref.read(secureStorageProvider).read(key: AppConfig.keySavedCedula).timeout(const Duration(seconds: 3));
      if (mounted && saved != null && saved.isNotEmpty) {
        setState(() {
          _cedulaController.text = saved;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final pwd = _passwordController.text;
    ref.read(loginViewModelProvider.notifier).login(_cedulaController.text, password: pwd.isEmpty ? null : pwd);
  }

  Future<void> _completeLogin(LoginSuccess next) async {
    await ref.read(sessionControllerProvider.notifier).authenticate(next.user, remember: _rememberSession);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = context.cPrimary;
    final loginState = ref.watch(loginViewModelProvider);

    ref.listen(loginViewModelProvider, (_, next) {
      if (next is LoginSuccess) _completeLogin(next);
      if (next is LoginError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message), backgroundColor: AppColors.systemRed, behavior: SnackBarBehavior.floating));
        ref.read(loginViewModelProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.fondoPantalla,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF060E1C).withValues(alpha: 0.85)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          ),
          if (isDark) ...[
            Positioned(
              top: -50, right: -40,
              child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [primaryColor.withValues(alpha: 0.18), Colors.transparent]))),
            ),
            Positioned(
              bottom: 40, left: -50,
              child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.accent.withValues(alpha: 0.14), Colors.transparent]))),
            ),
          ],
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoginHeaderLogo(),
                      const SizedBox(height: 20),
                      LoginFormCard(
                        formKey: _formKey,
                        cedulaController: _cedulaController,
                        passwordController: _passwordController,
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) => setState(() {
                          _selectedRole = role;
                        }),
                        obscurePassword: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        rememberSession: _rememberSession,
                        onRememberChanged: (v) => setState(() => _rememberSession = v ?? true),
                        isLoading: loginState is LoginLoading,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 16),
                      AppButtons.googleAuth(
                        context: context,
                        onPressed: loginState is LoginLoading ? null : () => ref.read(loginViewModelProvider.notifier).loginWithGoogle(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
