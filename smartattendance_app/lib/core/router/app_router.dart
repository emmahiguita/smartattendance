import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/session_controller.dart';
import '../../features/attendance/presentation/screens/confirmation_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/photo_attendance/presentation/local_attendance_home.dart';
import '../../features/photo_attendance/presentation/local_start_screen.dart';
import '../../features/photo_attendance/presentation/photo_history_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Nombres de rutas corporativas oficiales de Serviciudad E.S.P.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const qrScan = '/qr-scan';
  static const facialRecognition = '/facial-recognition';
  static const confirmation = '/confirmation';
  static const history = '/history';
  static const profileEdit = '/profile-edit';
  static const settings = '/settings';
  static const employeeToday = '/employee-today';
  static const messages = '/messages';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
      initialLocation: AppRoutes.splash,
      redirect: (context, state) {
        final session = ref.read(sessionControllerProvider);
        final path = state.matchedLocation;
        if (session is SessionUnknown || path == AppRoutes.splash) return null;
        const public = {
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.forgotPassword
        };
        if (session is SessionUnauthenticated && !public.contains(path)) {
          return AppRoutes.login;
        }
        return null;
      },
      routes: [
        GoRoute(
            path: AppRoutes.splash,
            builder: (_, __) => const LocalStartScreen()),
        GoRoute(
            path: AppRoutes.login,
            builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: AppRoutes.register,
            builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: AppRoutes.forgotPassword,
            builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen()),
        GoRoute(
            path: AppRoutes.confirmation,
            builder: (_, state) => ConfirmationScreen(
                tipo: state.uri.queryParameters['tipo'] ?? 'entrada',
                fechaRegistro: state.uri.queryParameters['fecha'],
                horaRegistro: state.uri.queryParameters['hora'])),
        GoRoute(
            path: AppRoutes.history,
            builder: (_, __) => const PhotoHistoryScreen()),
        GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen()),
        GoRoute(
            path: AppRoutes.profileEdit,
            builder: (_, __) => const EditProfileScreen()),
        for (final path in [
          AppRoutes.facialRecognition,
          AppRoutes.employeeToday,
          AppRoutes.qrScan
        ])
          GoRoute(
              path: path,
              builder: (_, state) => LocalAttendanceHome(
                  initialType: state.uri.queryParameters['tipo'])),
      ],
      errorBuilder: (_, __) => const Scaffold(
          body: Center(child: Text('Pantalla no encontrada.'))));

  ref.listen<SessionState>(sessionControllerProvider, (_, next) {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (next is SessionUnauthenticated) router.go(AppRoutes.login);
    if (next is SessionAuthenticated &&
        [AppRoutes.login, AppRoutes.splash].contains(path)) {
      router.go(AppRoutes.home);
    }
  });
  ref.onDispose(router.dispose);
  return router;
});
