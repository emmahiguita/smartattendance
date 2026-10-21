import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/session_controller.dart';
import '../../features/attendance/presentation/screens/confirmation_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/photo_attendance/presentation/local_settings_screen.dart';
import '../../features/photo_attendance/presentation/local_attendance_home.dart';
import '../../features/photo_attendance/presentation/local_operator_screen.dart';
import '../../features/photo_attendance/presentation/local_start_screen.dart';
import '../../features/photo_attendance/presentation/photo_history_screen.dart';

/// Nombres de rutas conservados para no romper enlaces de componentes previos.
/// El flujo activo es local: no abre APIs ni afirma autenticación biométrica.
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

/// Conserva el mismo Home visual en teléfonos y horizontal. No cambia a un
/// dashboard remoto solo por superar cierto ancho de pantalla.
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
            builder: (_, __) => const LocalOperatorScreen()),
        GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
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
            builder: (_, __) => const LocalSettingsScreen()),
        GoRoute(
            path: AppRoutes.profileEdit,
            builder: (_, __) => const LocalOperatorScreen()),
        // Las rutas antiguas conducen a seleccionar trabajador, nunca al simulador.
        for (final path in [
          AppRoutes.facialRecognition,
          AppRoutes.employeeToday,
          AppRoutes.qrScan
        ])
          GoRoute(
              path: path,
              builder: (_, state) => LocalAttendanceHome(
                  initialType: state.uri.queryParameters['tipo'])),
        for (final path in [AppRoutes.register, AppRoutes.forgotPassword])
          GoRoute(path: path, builder: (_, __) => const LocalOperatorScreen()),
      ],
      errorBuilder: (_, __) => const Scaffold(
          body:
              Center(child: Text('Pantalla no disponible en el modo local.'))));

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
