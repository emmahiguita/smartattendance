// lib/core/router/app_router.dart
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/attendance/presentation/screens/admin_dashboard_screen.dart';
import '../../features/attendance/presentation/screens/employee_today_screen.dart';
import '../../features/attendance/presentation/screens/confirmation_screen.dart';
import '../../features/qr/presentation/screens/qr_scanner_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/messaging/presentation/messages_screen.dart';
import '../auth/session_controller.dart';
import '../utils/roles.dart';

/// Named route paths â€” single source of truth.
/// OCP: add new routes here without touching other files.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String qrScan = '/qr-scan';
  static const String confirmation = '/confirmation';
  static const String history = '/history';
  static const String profileEdit = '/profile-edit';
  static const String settings = '/settings';
  static const String employeeToday = '/employee-today';
  static const String messages = '/messages';
}

/// Roles que obtienen el dashboard admin â€” espejo del check server-side
/// (`ADMIN_ROLES` en el backend). Check de cliente = UX solamente.
bool _isAdminRole(String? cargo) => AppRoles.isAdminRole(cargo);

CustomTransitionPage _premiumPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}

/// GoRouter provider â€” DIP applied: screens depend on this provider, not on GoRouter directly.
///
/// Seguridad: las decisiones de ruta leen el estado de sesión (C3). El
/// servidor impone los mismos roles en cada endpoint â€” este redirect es UX,
/// no la frontera de seguridad.
///
/// IMPORTANTE: el router NO se reconstruye al cambiar la sesión (usar
/// `ref.read` en lugar de `ref.watch`): reconstruirlo reinicia la pila de
/// navegación (splash â†’ home) y pierde el contexto tras editar perfil, etc.
/// La navegación reactiva la hace `ref.listen` con el MISMO router.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      // Splash owns the restore flow â€” do not redirect while it runs.
      if (location == AppRoutes.splash) return null;

      // While restoring, stay put (SessionUnknown).
      if (session is SessionUnknown) return null;

      // Rutas públicas accesibles sin sesión (login, registro, recuperación).
      const publicRoutes = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };

      if (session is SessionUnauthenticated) {
        return publicRoutes.contains(location) ? null : AppRoutes.login;
      }

      // Authenticated: never show public auth screens.
      if (publicRoutes.contains(location)) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _premiumPage(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _premiumPage(const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _premiumPage(const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _premiumPage(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final user = session is SessionAuthenticated ? session.user : null;
          final isAdmin = _isAdminRole(user?.cargo);

          return LayoutBuilder(
            builder: (context, constraints) {
              // Admin dashboard is reserved for admins â€” employees on wide
              // screens keep the employee home screen (C3).
              if (constraints.maxWidth > 800 && isAdmin) {
                return const AdminDashboardScreen();
              }
              return const HomeScreen();
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.qrScan,
        pageBuilder: (context, state) => _premiumPage(const QRScannerScreen()),
      ),
      GoRoute(
        path: AppRoutes.confirmation,
        pageBuilder: (context, state) {
          final params = state.uri.queryParameters;
          return _premiumPage(
            ConfirmationScreen(
              tipo: params['tipo'] ?? 'entrada',
              fechaRegistro: params['fecha'],
              horaRegistro: params['hora'],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        pageBuilder: (context, state) => _premiumPage(const HistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        pageBuilder: (context, state) =>
            _premiumPage(const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _premiumPage(const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.employeeToday,
        pageBuilder: (context, state) =>
            _premiumPage(const EmployeeTodayScreen()),
      ),
      GoRoute(
        path: AppRoutes.messages,
        pageBuilder: (context, state) => _premiumPage(const MessagesScreen()),
      ),
    ],
  );

  // Navegación reactiva a la sesión, sin reconstruir el router:
  //  - logout  â†’ login (desde cualquier pantalla)
  //  - login   â†’ home (desde login/splash)
  //  - editar perfil â†’ NADA (la pila actual se preserva)
  ref.listen<SessionState>(sessionControllerProvider, (_, next) {
    if (next is SessionUnknown) return;
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (next is SessionUnauthenticated) {
      if (currentPath != AppRoutes.login) router.go(AppRoutes.login);
    } else if (next is SessionAuthenticated) {
      if (currentPath == AppRoutes.login || currentPath == AppRoutes.splash) {
        router.go(AppRoutes.home);
      }
    }
  });

  return router;
});
