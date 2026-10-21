// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/control_ai_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Splash screen: animated logo + fixed delay, then login.
///
/// NO dependency on secure_storage or session restore. Those operations
/// can hang on Android devices without screen lock (Keystore blocked).
/// Session restore happens lazily when the login screen is visible.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Show splash for ~3s, then go to login. No async I/O — guaranteed fast.
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: context.cGradientBackground,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ControlAiLogo(size: 64, isHorizontal: false)
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .shimmer(
                    delay: 1000.ms,
                    duration: 1200.ms,
                    color: Colors.white.withValues(alpha: 0.5)),

            const SizedBox(height: 60),

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
