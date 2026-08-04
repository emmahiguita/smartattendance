// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // ProviderScope: DIP root — all providers resolved here.
    const ProviderScope(child: SmartAttendanceApp()),
  );
}

/// Application root widget.
/// SRP: only sets up MaterialApp and routing.
class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    // Barra de estado acorde al tema activo (antes era forzada a iconos
    // oscuros siempre → invisibles en dark mode).
    _applySystemOverlay(context, themeMode);

    return MaterialApp.router(
      title: 'CONTROL AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Preferencia del usuario (Configuración)
      // Español: textos nativos de Material (calendario, diálogos, etc.)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      locale: const Locale('es'),
      routerConfig: router,
    );
  }

  /// Ajusta el contraste de la barra de estado al brillo efectivo.
  /// Se re-ejecuta en cada build (el themeMode se observa arriba).
  void _applySystemOverlay(BuildContext context, ThemeMode themeMode) {
    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final effectiveDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => systemDark,
    };

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Fondo oscuro → iconos claros; fondo claro → iconos oscuros.
      statusBarIconBrightness:
          effectiveDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: effectiveDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          effectiveDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness:
          effectiveDark ? Brightness.light : Brightness.dark,
    ));
  }
}
