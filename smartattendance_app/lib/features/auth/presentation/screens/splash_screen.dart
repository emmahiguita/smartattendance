// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/control_ai_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Splash screen: restores the session and routes accordingly.
/// SRP: only session restore + animated logo.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      // Timeout global: si restore() se cuelga por Keystore bloqueado
      // (sin screen lock en algunos Android), forzamos login tras 10s.
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 300)),
        ref.read(sessionControllerProvider.notifier).restore(),
      ]).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timeout o error en restore → ir a login directamente.
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    // Navegación explícita: cubre el caso donde restore() terminó ANTES de
    // que el listener de build() se registrara (race condition).
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider);
    if (session is SessionAuthenticated) {
      context.go(AppRoutes.home);
    } else if (session is SessionUnauthenticated) {
      context.go(AppRoutes.login);
    }
    // SessionUnknown: el listener de build() navegará cuando cambie.
  }

  @override
  Widget build(BuildContext context) {
    // Navegación reactiva al estado de sesión (evita manual redirects).
    ref.listen<SessionState>(sessionControllerProvider, (_, next) {
      if (!mounted) return;
      if (next is SessionAuthenticated) {
        context.go(AppRoutes.home);
      } else if (next is SessionUnauthenticated) {
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: context.cGradientBackground,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating CONTROL AI Logo
            const ControlAiLogo(size: 64, isHorizontal: false)
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .shimmer(
                    delay: 1000.ms,
                    duration: 1200.ms,
                    color: Colors.white.withValues(alpha: 0.5)),

            const SizedBox(height: 60),

            // Modern Loader
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.systemBlue,
                strokeWidth: 3,
                backgroundColor: AppColors.systemBlue.withValues(alpha: 0.1),
              ),
            ).animate().fadeIn(delay: 1800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
