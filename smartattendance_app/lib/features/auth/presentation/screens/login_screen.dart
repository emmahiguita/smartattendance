// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../presentation/viewmodels/login_viewmodel.dart';

/// Login screen — autenticación REAL contra el backend.
/// Cédula + contraseña. Autocompleta y recuerda credenciales automáticamente.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focusNodeCedula = FocusNode();
  final _focusNodePassword = FocusNode();

  bool _isFocusedCedula = false;
  bool _isFocusedPassword = false;
  bool _obscurePassword = true;
  bool _rememberSession = true;

  @override
  void initState() {
    super.initState();
    _focusNodeCedula.addListener(() {
      setState(() {
        _isFocusedCedula = _focusNodeCedula.hasFocus;
      });
    });
    _focusNodePassword.addListener(() {
      setState(() {
        _isFocusedPassword = _focusNodePassword.hasFocus;
      });
    });
    _loadSavedCredentials();
    _tryRestoreSession();
  }

  /// Prefill de la cédula si existe una guardada con "Recordar sesión".
  ///
  /// La CONTRASEÑA no se guarda ni se pre-rellena (nunca se persisten
  /// credenciales en claro — se eliminó el write de keySavedPassword por
  /// seguridad; aquí solo se limpia el uso residual).
  /// Sin sesión guardada el campo queda VACÍO: nada de datos de demostración.
  ///
  /// Timeout de 3s: secure_storage puede colgarse en Android sin screen lock.
  Future<void> _loadSavedCredentials() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final savedCedula = await storage
          .read(key: AppConfig.keySavedCedula)
          .timeout(const Duration(seconds: 3));

      if (!mounted) return;
      if (savedCedula != null && savedCedula.isNotEmpty) {
        _cedulaController.text = savedCedula;
      }
      setState(() {});
    } catch (_) {
      // Secure storage unreachable → proceed without prefilled cedula.
    }
  }

/// Background session restore — si hay una sesión válida en storage,
  /// el router redirige automáticamente a home (evita mostrar login).
  ///
  /// El splash screen YA NO llama a restore() porque secure_storage puede
  /// bloquearse y congelar el arranque. En lugar de eso, hacemos la
  /// restauración aquí, con la UI del login ya visible.
  void _tryRestoreSession() {
    // Lanza restore en background. Si ya hay sesión, el router listener
    // navega a home. Si falla/tardea, la pantalla de login sigue visible.
    Future.microtask(() => ref
        .read(sessionControllerProvider.notifier)
        .restore()
        .catchError((_) {}));
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _passwordController.dispose();
    _focusNodeCedula.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    // Navegación reactiva ante cambios en el ViewModel
    ref.listen(loginViewModelProvider, (_, next) {
      if (next is LoginSuccess) {
        _completeLogin(next);
      }
      if (next is LoginError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(next.message)),
                ],
              ),
              backgroundColor: AppColors.systemRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        ref.read(loginViewModelProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.cGradientBackground,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                32 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Header Logo & Marca SmartAttendance QR ────────────────
                    Column(
                      children: [
                        // Contenedor Icono QR
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_scanner,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                            .animate()
                            .scale(duration: 500.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 16),

                        // Título de la app
                        Text(
                          'SmartAttendance QR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.cTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 4),

                        // Subtítulo descriptivo
                        Text(
                          'Control inteligente de asistencia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.cTextSecondary,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Tarjeta Formulario Principal ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: context.cSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.cBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.05),
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
                            // Encabezado de sección
                            Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: context.cTextPrimary,
                                letterSpacing: -0.3,
                              ),
                            ).animate().fadeIn(delay: 350.ms),

                            const SizedBox(height: 24),

                            // ── Campo: Cédula ─────────────────────────────────
                            Text(
                              'Cédula de Identidad',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.cTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isFocusedCedula
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextFormField(
                                controller: _cedulaController,
                                focusNode: _focusNodeCedula,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.cTextPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ej: 1007331963',
                                  hintStyle: TextStyle(
                                    color: context.cGray2,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: context.cGray,
                                  ),
                                  suffixIcon: _cedulaController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.close,
                                              size: 18, color: context.cGray),
                                          onPressed: () {
                                            _cedulaController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: context.cBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: context.cBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: context.cBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) =>
                                    InputValidators.validateCedula(v),
                                onFieldSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_focusNodePassword),
                              ),
                            ).animate().fadeIn(delay: 400.ms),

                            const SizedBox(height: 20),

                            // ── Campo: Contraseña (real — verificada server-side) ──
                            Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.cTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isFocusedPassword
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                focusNode: _focusNodePassword,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.cTextPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tu contraseña',
                                  helperText:
                                      'Si tu cuenta fue creada por un administrador y aún no tiene contraseña, deja este campo vacío.',
                                  helperMaxLines: 2,
                                  helperStyle: TextStyle(
                                      fontSize: 11, color: context.cGray),
                                  hintStyle: TextStyle(
                                    color: context.cGray2,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                    color: context.cGray,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 20,
                                      color: context.cGray,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: context.cBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: context.cBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: context.cBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ).animate().fadeIn(delay: 450.ms),

                            const SizedBox(height: 16),

                            // ── Opciones: Recuperar contraseña & Recordar ──────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      context.go(AppRoutes.forgotPassword),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberSession,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        onChanged: (v) {
                                          setState(() {
                                            _rememberSession = v ?? true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _rememberSession = !_rememberSession;
                                        });
                                      },
                                      child: Text(
                                        'Recordar sesión',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: context.cTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ).animate().fadeIn(delay: 500.ms),

                            const SizedBox(height: 24),

                            // ── Botón Principal de Iniciar sesión ───────────────
                            PrimaryButton(
                              label: 'Iniciar sesión',
                              expanded: true,
                              isLoading: loginState is LoginLoading,
                              onPressed: _submit,
                            )
                                .animate()
                                .fadeIn(delay: 550.ms)
                                .slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 16),

                            // ── Enlace de Registro (flujo real: POST /auth/register) ──
                            Center(
                              child: TextButton(
                                onPressed: () => context.go(AppRoutes.register),
                                child: Text.rich(
                                  TextSpan(
                                    text: '¿No tienes una cuenta? ',
                                    style: TextStyle(
                                        color: context.cTextSecondary,
                                        fontSize: 13),
                                    children: const [
                                      TextSpan(
                                        text: 'Regístrate aquí',
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
                    )
                        .animate()
                        .fadeIn(delay: 350.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // ── Divider + Google Sign-In (real: id_token → POST /auth/google) ──
                    Row(
                      children: [
                        Expanded(child: Divider(color: context.cBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O continúa con',
                            style:
                                TextStyle(fontSize: 13, color: context.cGray),
                          ),
                        ),
                        Expanded(child: Divider(color: context.cBorder)),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 20),

                    AppButtons.googleAuth(
                      context: context,
                      onPressed: (loginState is LoginLoading)
                          ? null
                          : () => ref
                              .read(loginViewModelProvider.notifier)
                              .loginWithGoogle(),
                    ).animate().fadeIn(delay: 650.ms),

                    const SizedBox(height: 24),

                    // ── Footer ──────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: context.cGray),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Sesión protegida con token cifrado (JWT)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.cGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 650.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final password = _passwordController.text;
    ref.read(loginViewModelProvider.notifier).login(
          _cedulaController.text,
          password: password.isEmpty ? null : password,
        );
  }

  /// Completa el login cuando el servidor retornó éxito.
  ///
  /// FIX race condition: `authenticate()` (async) se espera ANTES de navegar.
  /// Antes, `context.go(home)` corría con la sesión aún Unauthenticated y el
  /// redirect del router rebotaba al login (la sesión nunca se marcaba como
  /// autenticada a tiempo).
  Future<void> _completeLogin(LoginSuccess next) async {
    final remember = _rememberSession;

    await ref.read(sessionControllerProvider.notifier).authenticate(
          next.user,
          remember: remember,
        );
    if (!remember) {
      // Sesión efímera: tokens SOLO en memoria (TokenStore), no en storage.
      ref
          .read(sessionControllerProvider.notifier)
          .setEphemeralTokens(accessToken: next.token);
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }
}
