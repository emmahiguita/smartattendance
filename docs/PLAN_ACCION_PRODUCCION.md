# PLAN DE ACCIÓN DETALLADO - 3 Semanas a Producción

## Semana 1: Remediación Crítica

### Día 1: Configuración y Variables de Entorno

**Tareas:**
1. Crear `lib/core/config/environment_config.dart` (Copiar de SOLUCIONES_IMPLEMENTABLES.md)
2. Actualizar `lib/core/config/app_config.dart`:
   ```dart
   // Cambiar de:
   static const String baseUrl = 'http://192.168.0.9:8000/api/v1';
   
   // A:
   static String get baseUrl => EnvironmentConfig.baseUrl;
   ```
3. Actualizar `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "io.smartattendance.attendance"
   ```
4. Crear `pubspec_dev.yaml` para variables de desarrollo

**Checklist:**
- [ ] environment_config.dart creado
- [ ] app_config.dart actualizado
- [ ] gradle.kts actualizado
- [ ] Variables de entorno documentadas
- [ ] Tests locales exitosos

**Tiempo:** 4 horas

---

### Día 2: Error Handling Global

**Tareas:**
1. Crear `lib/core/exceptions/app_exception.dart`
2. Crear `lib/core/exceptions/error_handler.dart`
3. Integrar en `lib/core/network/dio_provider.dart`
4. Actualizar todos los ViewModels para usar `ErrorHandler`

**Cambios en login_viewmodel.dart:**
```dart
// Antes
} catch (e) {
  state = LoginError(e.toString().replaceFirst('Exception: ', ''));
}

// Después
} catch (e) {
  final appError = ErrorHandler.handle(e);
  state = LoginError(appError.message);
}
```

**Checklist:**
- [ ] AppException implementado
- [ ] ErrorHandler implementado
- [ ] DioProvider actualizado
- [ ] LoginViewModel actualizado
- [ ] AttendanceRepository actualizado
- [ ] HistoryViewModel actualizado

**Tiempo:** 6 horas

---

### Día 3: Validadores y Logging

**Tareas:**
1. Crear `lib/core/validators/validators.dart`
2. Crear `lib/core/logging/app_logger.dart`
3. Integrar logger en todos los repositorios
4. Crear validadores específicos de dominio

**Actualizar login_screen.dart:**
```dart
validator: (v) => Validators.validateCedula(v),
```

**Actualizar auth_remote_datasource.dart:**
```dart
Future<(String token, UserModel user)> loginByCedula(String cedula) async {
  AppLogger.logApiCall('POST', '/auth/login', data: {'cedula': cedula});
  try {
    final response = await _dio.post(/* ... */);
    AppLogger.logApiResponse(response.statusCode ?? 200, response.data);
    // ...
  } catch (e) {
    AppLogger.error('Login failed', error: e);
    rethrow;
  }
}
```

**Checklist:**
- [ ] Validadores creados
- [ ] Logger integrado
- [ ] RemoteDataSources loguean
- [ ] Repositories loguean
- [ ] Tests de validadores pasan

**Tiempo:** 5 horas

---

### Día 4: Seguridad de Autenticación

**Tareas:**
1. Implementar Refresh Token Flow (requiere cambios en Backend)
2. Crear `lib/core/network/secure_dio_provider.dart`
3. Reemplazar dioProvider actual
4. Implementar Token Rotation
5. Crear SessionManager

**Nuevo auth_interceptor.dart:**
```dart
// Implementar refresh token en lugar de logout simple
if (error.response?.statusCode == 401) {
  try {
    final newToken = await _refreshToken();
    await storage.write(key: 'access_token', value: newToken);
    // Reintentar request
    return handler.resolve(await _retry(error.requestOptions));
  } catch (e) {
    await storage.delete(key: 'access_token');
    // Navegar a login
  }
}
```

**Checklist:**
- [ ] secure_dio_provider.dart creado
- [ ] SecureStorage usado correctamente
- [ ] Token no se crea multiple veces
- [ ] Refresh token flow funciona
- [ ] Logout completo limpia todo

**Tiempo:** 6 horas

---

### Día 5: Rate Limiting y Tests

**Tareas:**
1. Crear `lib/core/network/rate_limiter.dart`
2. Integrar RateLimiter en DioProvider
3. Crear tests básicos para Auth module
4. Setup de testing infrastructure

**Integración en dio_provider.dart:**
```dart
final rateLimiter = RateLimiter(maxRequests: 100);

dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final key = '${options.method}:${options.path}';
      if (!rateLimiter.isAllowed(key)) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Rate limit exceeded',
            type: DioExceptionType.unknown,
          ),
        );
      }
      return handler.next(options);
    },
  ),
);
```

**Crear tests:**
- `test/unit/auth/login_usecase_test.dart`
- `test/unit/validators/validators_test.dart`
- `test/unit/exceptions/error_handler_test.dart`

**Checklist:**
- [ ] RateLimiter implementado
- [ ] Tests unitarios creados
- [ ] LoginUseCase tested
- [ ] Validators tested
- [ ] Coverage > 60%

**Tiempo:** 6 horas

---

### Resumen Semana 1
- **Horas:** ~27
- **Deliverables:** 5 archivos nuevos + 10 archivos modificados
- **Riesgo:** Bajo (cambios pueden ser reversibles)

---

## Semana 2: Escalabilidad y UX

### Día 6: Dark Mode + Tema Enterprise

**Tareas:**
1. Crear `lib/core/theme/enterprise_colors.dart` (Nueva paleta)
2. Crear `lib/core/theme/enterprise_typography.dart`
3. Refactorizar `app_colors.dart` (deprecated)
4. Actualizar `app_theme.dart` con modo oscuro

**Nuevo app_theme.dart:**
```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EnterpriseColors.accentBlue,
      brightness: Brightness.light,
    ),
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EnterpriseColors.accentBlue,
      brightness: Brightness.dark,
    ),
  );
}

// En main.dart
MaterialApp.router(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)
```

**Checklist:**
- [ ] EnterpriseColors creado
- [ ] EnterpriseTypography creado
- [ ] Dark mode funciona
- [ ] Light mode fallback funciona
- [ ] Colores consistentes en toda la app

**Tiempo:** 8 horas

---

### Día 7: Componentes Reutilizables

**Tareas:**
1. Refactorizar AppBar a widget en `shared/widgets/enterprise_appbar.dart`
2. Crear sistema de botones unificado en `enterprise_button.dart`
3. Crear componentes de error en `enterprise_error_widget.dart`
4. Crear componentes de loading en `enterprise_loader.dart`

**Nuevo structure:**
```
lib/shared/widgets/
├── common/
│   ├── enterprise_appbar.dart
│   ├── enterprise_scaffold.dart
│   └── enterprise_surface.dart
├── buttons/
│   ├── enterprise_button.dart
│   ├── enterprise_icon_button.dart
│   └── button_variants.dart
├── dialogs/
│   ├── enterprise_error_dialog.dart
│   └── enterprise_confirmation_dialog.dart
└── loaders/
    ├── enterprise_loader.dart
    └── skeleton_loader.dart
```

**Checklist:**
- [ ] AppBar refactorizado
- [ ] Button system creado
- [ ] Error widgets creados
- [ ] Loaders creados
- [ ] Todos los screens reutilizan componentes

**Tiempo:** 7 horas

---

### Día 8: Caché Local con Hive

**Tareas:**
1. Agregar dependencia: `hive: ^2.2.0`
2. Crear `lib/core/localstore/hive_provider.dart`
3. Crear adapters para AttendanceEntity
4. Implementar caché en AttendanceRepository

**Instalación:**
```bash
flutter pub add hive hive_flutter
flutter pub add -d hive_generator build_runner
```

**Implementación:**
```dart
// lib/core/localstore/hive_provider.dart
final hiveProvider = FutureProvider<HiveInterface>((ref) async {
  await Hive.initFlutter();
  
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AttendanceEntityAdapter());
  }
  
  await Hive.openBox<AttendanceEntity>('attendances');
  return Hive;
});

// Actualizar AttendanceRepositoryImpl
@override
Future<List<AttendanceEntity>> getByUser(int userId) async {
  try {
    // Remote first
    final box = await Hive.openBox<AttendanceEntity>('attendances');
    final remote = await _dio.get('/attendance/user/$userId');
    final entities = (remote.data as List)
        .map((e) => AttendanceModel.fromJson(e).toEntity())
        .toList();
    
    // Save to cache
    box.put('user_$userId', entities);
    return entities;
  } catch (e) {
    // Fallback to cache
    final box = await Hive.openBox<AttendanceEntity>('attendances');
    final cached = box.get('user_$userId') as List<AttendanceEntity>?;
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
}
```

**Checklist:**
- [ ] Hive instalado
- [ ] HiveProvider creado
- [ ] Adapters registrados
- [ ] AttendanceRepository cachea
- [ ] HistoryViewModel usa caché
- [ ] Offline mode funciona

**Tiempo:** 7 horas

---

### Día 9: AdminDashboardViewModel Refactoring

**Tareas:**
1. Refactorizar AdminDashboardViewModel para usar inyección
2. Crear AttendanceRepository injection
3. Mover lógica de dashboard a domain layer
4. Crear tests para AdminDashboardViewModel

**Nuevo patrón:**
```dart
// Antes: ❌
class AdminDashboardViewModel extends StateNotifier {
  final Dio _dio = Dio(); // ❌ MALO
  
  AdminDashboardViewModel() : super(AdminDashboardState()) {
    fetchAttendances();
  }
}

// Después: ✅
class AdminDashboardViewModel extends StateNotifier {
  final AttendanceRepository _repository;
  
  AdminDashboardViewModel(this._repository) : super(AdminDashboardState()) {
    _loadData();
  }
  
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final attendances = await _repository.getAll();
      state = state.copyWith(
        isLoading: false,
        attendances: attendances,
      );
    } catch (e) {
      final error = ErrorHandler.handle(e);
      state = state.copyWith(
        isLoading: false,
        error: error.message,
      );
    }
  }
}

// Provider
final adminDashboardProvider = 
  StateNotifierProvider<AdminDashboardViewModel, AdminDashboardState>((ref) {
    final repository = ref.watch(_attendanceRepositoryProvider);
    return AdminDashboardViewModel(repository);
  });
```

**Checklist:**
- [ ] Repository inyectado correctamente
- [ ] Usa ErrorHandler
- [ ] Usa logging
- [ ] Tests incluidos
- [ ] Funcionalidad preservada

**Tiempo:** 5 horas

---

### Día 10: Offline Support Completo

**Tareas:**
1. Crear ConnectivityService en `lib/core/network/connectivity_service.dart`
2. Implementar queue de requests offline
3. Sincronización automática cuando hay conexión
4. UI indicators para offline mode

**Implementación:**
```dart
// lib/core/network/offline_queue.dart
class OfflineQueueItem {
  final String method;
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  OfflineQueueItem({
    required this.method,
    required this.endpoint,
    required this.data,
  }) : timestamp = DateTime.now();
}

class OfflineQueue {
  final Queue<OfflineQueueItem> _queue = Queue();
  
  void enqueue(OfflineQueueItem item) => _queue.add(item);
  OfflineQueueItem? dequeue() => _queue.isNotEmpty ? _queue.removeFirst() : null;
  bool get isEmpty => _queue.isEmpty;
  int get length => _queue.length;
}

// Uso en dio_provider.dart
dio.interceptors.add(
  InterceptorsWrapper(
    onError: (error, handler) async {
      if (error.type == DioExceptionType.connectionError) {
        final queueItem = OfflineQueueItem(
          method: error.requestOptions.method,
          endpoint: error.requestOptions.path,
          data: error.requestOptions.data as Map<String, dynamic>,
        );
        offlineQueue.enqueue(queueItem);
        // Notificar al usuario
      }
      return handler.next(error);
    },
  ),
);
```

**Checklist:**
- [ ] ConnectivityService creado
- [ ] OfflineQueue implementada
- [ ] Requests se encolan offline
- [ ] Sincronización automática funciona
- [ ] UI indica status offline

**Tiempo:** 7 horas

---

### Resumen Semana 2
- **Horas:** ~41
- **Deliverables:** Tema completo + Componentes + Caché + Offline
- **Riesgo:** Medio (Refactorización extensa)

---

## Semana 3: Testing y Finalización

### Día 11: Cobertura de Tests

**Tareas:**
1. Agregar `coverage` package
2. Escribir tests para todas las capas de Auth
3. Escribir tests de validadores
4. Escribir tests de repositories
5. Target: 80%+ coverage

**Estructura de tests:**
```
test/
├── unit/
│   ├── auth/
│   │   ├── login_usecase_test.dart
│   │   ├── auth_repository_impl_test.dart
│   │   └── auth_remote_datasource_test.dart
│   ├── attendance/
│   │   ├── attendance_repository_impl_test.dart
│   │   └── attendance_model_test.dart
│   ├── validators/
│   │   └── validators_test.dart
│   └── exceptions/
│       └── error_handler_test.dart
├── widget/
│   ├── login_screen_test.dart
│   ├── home_screen_test.dart
│   └── confirmation_screen_test.dart
└── integration/
    └── auth_flow_test.dart
```

**Target:** 
- Auth module: 95%
- Validators: 100%
- Repositories: 90%
- Screens: 60%
- Overall: 80%

**Checklist:**
- [ ] Unit tests escritos (todos)
- [ ] Widget tests creados
- [ ] Integration tests básicos
- [ ] Coverage > 80%
- [ ] CI/CD pipeline configurado

**Tiempo:** 12 horas

---

### Día 12: Documentación y Deployment

**Tareas:**
1. Escribir README.md completo
2. Crear ARCHITECTURE.md
3. Crear DEPLOYMENT.md
4. Documentar API endpoints
5. Setup de CI/CD con GitHub Actions

**Ejemplo README.md:**
```markdown
# SmartAttendance

Sistema de control de asistencia empresarial con Flutter.

## Requisitos

- Flutter 3.4+
- Dart 3.0+
- Android SDK 30+
- iOS 11.0+

## Setup

1. Clone: `git clone ...`
2. Dependencias: `flutter pub get`
3. Configurar env: `cp .env.example .env`
4. Run: `flutter run -d 1` (ajustar para dev)

## Arquitectura

- Clean Architecture: Domain → Data → Presentation
- State Management: Riverpod
- Routing: GoRouter
- Storage: FlutterSecureStorage + Hive

## Testing

```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

## Deployment

Ver DEPLOYMENT.md

## Contributors

- [Tu nombre]
```

**Checklist:**
- [ ] README completo
- [ ] ARCHITECTURE.md creado
- [ ] DEPLOYMENT.md creado
- [ ] API documentation
- [ ] GitHub Actions workflow

**Tiempo:** 6 horas

---

### Día 13: Build y Release

**Tareas:**
1. Configurar signing para release
2. Crear flavor para prod vs staging
3. Build APK y AAB
4. Preparar para Play Store
5. Load testing básico

**Configuración de flavors:**
```bash
# main_dev.dart
void main() {
  runApp(
    const ProviderScope(
      child: SmartAttendanceApp(
        environment: Environment.development,
      ),
    ),
  );
}

# main_prod.dart
void main() {
  runApp(
    const ProviderScope(
      child: SmartAttendanceApp(
        environment: Environment.production,
      ),
    ),
  );
}

# Build
flutter build apk --flavor production --release
```

**Play Store preparation:**
- [ ] Icon creado (512x512)
- [ ] Screenshots preparadas
- [ ] Description en español
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Testing en device real

**Checklist:**
- [ ] Release signed correctly
- [ ] Version bumped
- [ ] All tests passing
- [ ] Load testing done
- [ ] Ready for Play Store

**Tiempo:** 5 horas

---

### Día 14: Optimización Final

**Tareas:**
1. Performance profiling
2. Size optimization
3. Security final checks
4. Battery drain analysis
5. Final QA

**Performance targets:**
- Cold start: < 2s ✅
- Hot reload: < 500ms ✅
- Login: < 1.5s ✅
- Memory: < 150MB ✅
- APK size: < 50MB ✅

**Security checklist:**
- [ ] No hardcoded secrets
- [ ] HTTPS only in prod
- [ ] Obfuscation enabled
- [ ] ProGuard rules configured
- [ ] Dependencies updated
- [ ] No deprecated APIs used

**Checklist:**
- [ ] Performance metrics OK
- [ ] Memory leak tested
- [ ] Battery drain acceptable
- [ ] All security checks passed
- [ ] Ready for production

**Tiempo:** 8 horas

---

### Resumen Semana 3
- **Horas:** ~31
- **Deliverables:** Tests completos + Docs + Release
- **Riesgo:** Bajo (Finalización)

---

## Resumen Total

| Fase | Horas | Hitas |
|------|-------|-------|
| **Semana 1: Crítico** | 27 | Config + Error + Security |
| **Semana 2: Escalabilidad** | 41 | Theme + Components + Offline |
| **Semana 3: Production** | 31 | Tests + Docs + Release |
| **TOTAL** | **99** | **~3 semanas** |

---

## Estimación de Recursos

### Equipo Mínimo
- 1 Senior Flutter Developer (Lead)
- 1 Mid Flutter Developer
- 1 Backend Developer (ajustes)

### Equipo Recomendado
- 1 Senior Flutter Developer (Lead + Architecture)
- 1 Senior Backend Developer (API + Auth)
- 1 Mid Flutter Developer (UI + Features)
- 1 QA Engineer (Testing)

### Timeline con Equipo Mínimo
- **Semana 1:** 27 hrs → 3 días (9 hrs/day)
- **Semana 2:** 41 hrs → 5 días (8.2 hrs/day)
- **Semana 3:** 31 hrs → 4 días (7.75 hrs/day)
- **Total:** 12 días de trabajo

### Timeline con Equipo Recomendado
- **Semana 1:** 27 hrs → 2 días (parallelizable)
- **Semana 2:** 41 hrs → 2.5 días (en paralelo)
- **Semana 3:** 31 hrs → 2 días (testing en paralelo)
- **Total:** ~7 días calendario

---

## Métricas de Éxito

**Antes de Producción:**

| Métrica | Target | Actual |
|---------|--------|--------|
| Code Coverage | 80% | - |
| Test Pass Rate | 100% | - |
| Security Score | A+ | - |
| Performance Score | 90+ | - |
| Accessibility Score | 85+ | - |
| Bundle Size | < 50MB | - |
| Cold Start | < 2s | - |
| Login Time | < 1.5s | - |

---

## Riesgos y Mitigación

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|--------|-----------|
| Backend no soporta refresh tokens | Media | Alto | Coordinación con backend |
| Performance issues en dispositivos viejos | Media | Medio | Load testing temprano |
| Dependencias conflictivas | Baja | Alto | Esto versioning |
| Cambios scope a mitad | Media | Alto | Scope lock en Semana 1 |

---

## Próximos Pasos

1. ✅ Leer AUDITORIA_PROFESIONAL.md completo
2. ✅ Revisar SOLUCIONES_IMPLEMENTABLES.md
3. ⏭️ **Crear rama "refactor/production"**
4. ⏭️ **Comenzar Día 1 tareas**
5. ⏭️ **Daily standup con equipo**
6. ⏭️ **Comunicar cambios a stakeholders**

---

**Documento de Plan de Acción**  
Versión: 1.0  
Última actualización: Junio 2026  
Confidencialidad: CONFIDENCIAL

