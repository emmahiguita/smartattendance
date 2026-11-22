// ============================================================================
// ARCHIVO: main.dart
// QUÉ HACE: Punto de entrada multiplataforma (Android, iOS, Windows, macOS,
//           Linux) de BuenTiempo con inicialización de SQLite FFI en escritorio
//           y configuración de orientaciones y tema adaptativo.
// CÓMO FUNCIONA:
// 1. En escritorio (`Windows`, `Linux`, `macOS`) inicializa `sqfliteFfiInit()`
//    y asigna `databaseFactory = databaseFactoryFfi` para que SQLite funcione
//    nativamente igual que en Android e iOS.
// 2. En móvil (`Android`, `iOS`) habilita rotación adaptativa y barra de estado.
// POR QUÉ: Garantiza ejecución multiplataforma 100% real (< 115 líneas).
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/employee_avatar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización SQLite FFI para ejecución nativa en Windows, macOS y Linux
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (_) {}
  }

  await initializeDateFormatting('es', null);
  await EmployeeAvatarService.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(
    const ProviderScope(child: SmartAttendanceApp()),
  );
}

class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    _applySystemOverlay(context, themeMode);

    return MaterialApp.router(
      title: 'BuenTiempo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
      statusBarIconBrightness:
          effectiveDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: effectiveDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          effectiveDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness:
          effectiveDark ? Brightness.light : Brightness.dark,
    ));
  }
}
