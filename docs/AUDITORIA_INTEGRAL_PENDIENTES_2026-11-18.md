# 🔍 Informe Exhaustivo de Auditoría y Diagnóstico de Pendientes
**Proyecto:** SmartAttendance (Flutter Multiplataforma + FastAPI Cloud Backend)  
**Fecha de Auditoría:** 18 de Noviembre de 2026  
**Auditor:** Agente Senior de Calidad y Arquitectura de Software  

---

## 📊 1. Resumen Ejecutivo del Estado del Sistema

| Dimensión | Estado | Observación |
| :--- | :---: | :--- |
| **Análisis Estático Flutter (`flutter analyze`)** | **100% LIMPIO** | 0 errores, 0 advertencias, 0 lints en los 325 archivos de `lib/`. |
| **Pruebas de Integración y Seguridad Flutter** | **100% PASS** | 15/15 suites pasando (`test/integration/`). Corregido boundary 401/403/429. |
| **Pruebas de Backend FastAPI (`pytest`)** | **100% PASS** | 59/59 tests aprobados en `smartattendance_backend`. |
| **Hardware Real (OPPO A79 5G - `VGL7MVFMDYQG8T55`)** | **CONECTADO & VERIFICADO** | Login offline < 100ms, online con fallback < 3.2s. |
| **Regla de Modularización (< 200 / 280 líneas)** | **ATENCIÓN REQUERIDA** | 14 archivos superan las 280 líneas; 39 archivos entre 201 y 280 líneas. |
| **Sincronización Cloud vs Local SQLite** | **PARCIAL** | Asistencia básica sincroniza; fotos biométricas y cuadrillas son 100% locales. |

---

## 🛠️ 2. Correcciones de Seguridad Aplicadas en Esta Sesión

1. **Corrección de Límite de Autenticación (`AuthRepositoryImpl`):**
   * *Problema Detectado:* Se había colocado la validación SQLite antes de la llamada remota incondicionalmente, lo que provocaba que si el servidor remoto denegaba explícitamente el acceso con `HTTP 401`, `403` o `429`, la app aceptara una contraseña local desactualizada.
   * *Solución Aplicada:* Se restauró el flujo estricto: cuando está online (`isOffline == false`), la app consulta el backend con timeout de 3 segundos. Si el backend rechaza con 401/403/429, se propaga `AppException`. Solo ante **fallos reales de transporte** (timeout, 502/503/504, 404, caída de conexión) o en modo offline explícito se procede con la autenticación local en SQLite.
2. **Detección de Sesión Real en Sincronizador (`OfflineSyncController`):**
   * *Problema Detectado:* `_hasRealSession()` solo evaluaba `token != 'local-offline-token'`, enviando accidentalmente tokens locales generados (`local_jwt_...`) a los endpoints del servidor remoto, lo que causaba rechazos con 401.
   * *Solución Aplicada:* Se integró `TokenStore.isLocalToken(token)` para blindar la cola de sincronización contra expulsiones involuntarias de sesión.

---

## 📋 3. ¿Qué Falta? — Diagnóstico Detallado de Pendientes

### 🔴 Prioridad Alta (Arquitectura y Reglas del Proyecto)

1. **Refactorización de Archivos que Superan 280 Líneas (Incumplimiento de `AGENTS.md`):**
   * `lib/core/localstore/local_database_service.dart` (**582 líneas**): Debe desacoplarse en DAOs especializados (`UserDao`, `AttendanceDao`, `ConfigDao`).
   * `lib/features/attendance/data/repositories/attendance_repository_impl.dart` (**478 líneas**): Debe extraerse la lógica de cálculo de horas y mapeos a helpers dedicados.
   * `lib/core/design_system/employee_credential_card.dart` (**417 líneas**): Dividir en carátula frontal, reverso QR y widget de chip holográfico.
   * `lib/features/attendance/presentation/screens/employee_today_screen.dart` (**407 líneas**): Separar la cabecera métrica y el timeline de marcas en widgets independientes.
   * `lib/features/attendance/presentation/screens/admin_dashboard_screen.dart` (**379 líneas**): Desacoplar secciones de filtros y métricas.
   * `lib/features/attendance/data/consolidated_attendance_repository.dart` (**366 líneas**): Extraer queries agregadas a un reader SQLite.
   * `lib/features/attendance/presentation/widgets/premium_attendance_table.dart` (**331 líneas**): Extraer filas y celdas interactivas.
   * `lib/features/attendance/presentation/consolidated/controllers/consolidated_attendance_controller.dart` (**323 líneas**): Dividir en controlador de filtros y controlador de paginación.
   * `lib/shared/widgets/premium_animations.dart` (**319 líneas**): Separar por familias de animación.
   * `lib/features/photo_attendance/presentation/worker_assignment_dialog.dart` (**300 líneas**): Modularizar campos de asignación.
   * `lib/features/auth/presentation/screens/forgot_password_screen.dart` (**283 líneas**).
   * `lib/core/design_system/status_states_view.dart` (**281 líneas**).
   * `lib/features/attendance/presentation/widgets/premium_area_sections.dart` (**281 líneas**).
   * `lib/features/users/presentation/widgets/register_user_dialog.dart` (**281 líneas**).

2. **Estandarización de Comentarios Pedagógicos:**
   * Agregar en los archivos históricos identificados (`messaging_repository.dart`, `excel_exporter.dart`, `app_buttons.dart`, etc.) el bloque mandatorio:
     ```dart
     // ============================================================================
     // ARCHIVO: [nombre_archivo.dart]
     // QUÉ HACE: ...
     // CÓMO FUNCIONA: ...
     // POR QUÉ: ...
     // ============================================================================
     ```

---

### 🟡 Prioridad Media (Sincronización y Backend Cloud)

3. **Sincronización de Marcaciones Fotográficas (`photo_marks`) al Backend:**
   * Actualmente, la marcación fotográfica con 4 estados guarda la foto y coordenadas en SQLite local y genera reportes Excel/PDF en el teléfono.
   * *Falta:* Implementar un endpoint multipart/form-data en FastAPI (`POST /api/v1/attendance/photo-mark`) y un worker de sincronización en Flutter que suba la imagen comprimida (JPEG 85%) y el registro a Cloud Storage / S3 / Base de datos para que los supervisores la vean en el panel web.

4. **Sincronización Cloud de Cuadrillas y Geocercas (`crews`, `work_zones`):**
   * Las cuadrillas, puestos y zonas creadas en el diálogo de administración viven únicamente en el SQLite del dispositivo del creador.
   * *Falta:* Endpoints en FastAPI (`/api/v1/crews`, `/api/v1/zones`) y sync bidireccional para que cuando un Administrador cree una cuadrilla o geocerca desde cualquier teléfono o portal web, se replique automáticamente en los dispositivos de los supervisores asignados.

5. **Notificaciones Push en Tiempo Real (FCM / APNs):**
   * La app maneja mensajes internos (`messages_screen.dart`), pero no cuenta con un servicio push en background (Firebase Cloud Messaging).
   * *Falta:* Configurar `firebase_messaging` para despertar al dispositivo cuando un supervisor asigne un turno urgente o se genere una alerta de salida de geocerca.

6. **Consolidación del Servicio de Telemetría GPS (Traccar):**
   * El cliente de telemetría envía tramas OsmAnd a una URL configurable de Traccar.
   * *Falta:* Validar si el backend de FastAPI alojará un microservicio receptor GPS propio o si se mantendrá el servidor Traccar externo con credenciales de producción documentadas.

---

### 🟢 Prioridad Baja (Preparación para Publicación en Tiendas)

7. **Configuración de Firma de Producción Android (`Release Key`):**
   * El archivo `android/key.properties.example` está presente.
   * *Falta:* Generar el keystore de producción oficial (`upload-keystore.jks`) y configurar las variables secretas en CI/CD para generar el Android App Bundle (`.aab`) firmado para Google Play Store.

8. **Certificados de Distribución iOS (Apple Developer Program):**
   * El workflow de GitHub Actions (`build_ios.yml`) está preparado.
   * *Falta:* Proveer los secretos de repositorio: `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `MOBILEPROVISION_BASE64` para despliegues a TestFlight.
