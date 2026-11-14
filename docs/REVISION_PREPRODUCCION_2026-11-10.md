# Revisión de preparación para producción — 10 de noviembre de 2026

## Dictamen

**No aprobado para producción.** Hay correcciones verificadas en el código local, pero quedan fallos y verificaciones de despliegue pendientes. Las pruebas aprobadas no acreditan ausencia total de errores ni que el teléfono o el servidor público ejecuten esta revisión.

Esta revisión sustituye el estado de los informes anteriores. En particular, los códigos de recuperación ya se guardan en base de datos y la rotación de refrescos ya tiene estado persistente; no deben seguir figurando como implementaciones exclusivamente en memoria. El limitador general de solicitudes sí permanece en memoria.

## Errores encontrados y corregidos en esta revisión

| Prioridad | Problema confirmado | Corrección y evidencia |
|---|---|---|
| Crítica si se utilizó en un despliegue | `fly.Dockerfile` proporcionaba una clave JWT pública como valor predeterminado. | Eliminado ese valor. `Settings` exige al menos 32 caracteres útiles y rechaza los valores públicos conocidos, incluso rodeados de espacios. Pruebas de regresión en `test_production_settings.py`; el caso con espacios falló antes de corregirlo. No se ha rotado ninguna clave desplegada. |
| Alta | El contexto de Docker no excluía archivos privados, bases locales ni fotos; `COPY . .` podía incorporarlos. | Nuevo `.dockerignore` en el backend. Se excluyen los nombres y extensiones de credenciales conocidos, entornos locales, bases, logs y las dos rutas de fotografías. No se construyó ni inspeccionó una imagen resultante. |
| Alta | «No recordar sesión» no se respetaba al reiniciar: un perfil guardado sin token se restauraba como autenticado. | `session_controller.dart:67` exige una credencial persistida no vacía. Dos casos fallaban antes; pasan los tres casos, incluida conservación de la sesión local recordada. Pruebas unitarias con el adaptador de pruebas oficial de SecureStorage; no prueban Keystore/Keychain. |
| Alta | Subir una fotografía devolvía 200, pero descargar su URL devolvía 404: escritura en `backend/app/static/fotos` y lectura en `backend/static/fotos`. | Nueva ruta compartida en `app/core/file_storage.py`, usada por subida y servidor estático. Prueba con SQLite temporal, fichero PNG real y API ASGI: subida 200, descarga 200 y mismos bytes. El recorrido falló con 404 antes del cambio. |
| Alta | Las fotos de Fly se escribían fuera del volumen persistente. | `STATIC_DIRECTORY` configurable; `fly.toml` apunta a `/data/static`, dentro del volumen configurado. Esto corrige la configuración del repositorio para Fly; todavía no se verificó persistencia en un despliegue real ni se configuró un disco en Render. |
| Alta | Faltaba declarar `email-validator`, necesario para los esquemas `EmailStr`. Un entorno previamente instalado podía ocultar el problema. | Añadido `email-validator==2.3.0`; aparece entre los 57 paquetes de la resolución de instalación. La resolución no equivale a instalar y arrancar una imagen limpia. |
| Media | `.env.example` contenía `GOOGLE_SHEET_NAME`, ausente de `Settings`; copiarlo podía impedir el arranque por configuración desconocida. Sheets, además, leía `os.environ` aunque Pydantic cargara el `.env`. | Campo añadido y consumo desde `settings.GOOGLE_SHEET_NAME`. Prueba con archivo de configuración temporal. |
| Media | Las pruebas necesitaban una clave real para importar configuración antes de sustituirla. | `tests/conftest.py` establece una clave efímera antes de importar `settings`. Comprobado en otro proceso, desde directorio temporal y sin `.env` ni `SECRET_KEY` heredada. |

No se modificaron datos de usuarios existentes, no se borraron duplicados y no se desplegó ni instaló esta revisión. La prueba de fotografías eliminó exclusivamente su propio archivo de prueba.

## Pendientes ordenados por impacto

### P1: Resolver antes de aprobar un despliegue

1. **Servidor predeterminado sin salud verificada.** `environment_config.dart:119` utiliza `https://smartattendance-api.onrender.com/api/v1`. La consulta de solo lectura a `/health` del 10 de noviembre a las 17:42:53 UTC devolvió **404**. Confirmar URL del servicio y comprobar salud, autenticación y operaciones contra el despliegue correcto. Un intento anterior agotó el tiempo de espera; no se atribuye la causa sin acceso al servicio. Evidencia: `qa/readiness_remote_health.json`.
2. **Renovación concurrente con cierre de sesión.** `token_refresh.dart:36` comprueba el token antes de esperar escrituras en almacenamiento (:38–41), pero después vuelve a poblar memoria (:43–45). `SessionController.clear():134` puede ejecutarse durante esa espera. Hallazgo por orden asíncrono, confirmado en revisión independiente; **no reproducido con un intercalado determinista**. Requiere coordinación de operaciones y una regresión que fuerce ese intercalado, incluida la llegada de una nueva sesión.
3. **Fallback local tras rechazo remoto.** `auth_repository_impl.dart:59–61` intenta iniciar sesión local ante cualquier error remoto, incluidos rechazos de credenciales; además aplica un tiempo de espera de solo dos segundos (:57). Definir y verificar cómo una baja o cambio de contraseña del servidor invalida credenciales locales. No basta con llamar «offline» a una autenticación rechazada en línea.
4. **Cerrar sesión también en el servidor.** El cierre actual limpia el dispositivo; no existe una operación de cierre que revoque la sesión remota correspondiente. Un token copiado puede continuar siendo válido hasta caducar o ser revocado por otra vía. Los JWT antiguos sin `sid` siguen aceptándose hasta su expiración por compatibilidad (`session_service.py:59`), incluso después de cambios que revocan sesiones con estado.
5. **Migrar fotos conservando información.** Inventariar `backend/app/static/fotos`, `backend/static/fotos` y el almacenamiento del servidor, cruzar `foto_url`, copiar al destino persistente y verificar cantidad y hashes. Mantener copia anterior. El código nuevo no traslada archivos existentes; no se ejecutó ninguna migración ni eliminación automática.
6. **Secretos e identidad reales.** Si algún servidor usó la antigua clave pública, configurar una nueva clave privada y sustituir las sesiones anteriores. Probar recuperación SMTP y establecimiento de contraseña con una cuenta QA autorizada. No se enviaron correos en esta auditoría. Google sigue necesitando vinculación duradera por `sub`, migración y prueba real de OAuth.
7. **Recorrido administrativo completo en versión identificable.** Compilar e instalar esta revisión y comprobar administrador → supervisor → cinco trabajadores, sitio de trabajo, permisos propios/ajenos, duplicados, edición, horario fijo y ventana flexible en Colombia, cambios de fecha y trabajo nocturno. Las pruebas sobre repositorios temporales y la inspección anterior de cinco trabajadores existentes no sustituyen este recorrido de creación.

### P2: Infraestructura y distribución sin verificar

- `rate_limit.py:9` conserva contadores por proceso y no elimina claves inactivas del diccionario. No coordina varios procesos ni resiste reinicios; verificar también cómo el proxy identifica clientes. Los desafíos de recuperación sí tienen persistencia e intentos limitados en base de datos.
- Roles no homologados: `deps.py:20` permite administración remota a `admin`/`administrador`; el clasificador móvil admite también `Administrador General`, `super_admin`, `gerente` y `rrhh`. Definir roles canónicos y migrar sin conceder privilegios nuevos automáticamente.
- `render.yaml` no declara disco para fotos. El ajuste de Fly no modifica Render. Elegir un almacenamiento persistente y verificar conservación tras reiniciar y redesplegar.
- `fly.toml` y `render.yaml` mantienen CORS `*`; concretar orígenes si se publica un cliente web. Las fotos bajo `/static` se sirven sin autenticación: revisar si esa política pública corresponde a los datos que se almacenan.
- Construir la imagen Python 3.12/Linux e instalar dependencias desde cero, fijar versiones transitivas y probar PostgreSQL si será la base de producción. Docker no está disponible en este equipo; las pruebas del servidor corrieron con Python 3.14 en Windows.
- Verificar copias y restauración de bases y fotografías, migraciones, concurrencia, carga, alertas y recuperación ante fallos. No se ejecutaron pruebas de carga ni restauraciones de producción.
- Android: firma de distribución, artefacto de esta revisión y pruebas de permisos/GPS/cámara, fondos y legibilidad en todas las pantallas. El APK 1.0.2 instalado anteriormente no contiene estas correcciones nuevas.
- iOS: compilación y pruebas en Mac/Xcode, firma, permisos y OAuth reales. No se ejecutaron en esta revisión.
- Katalon: el intento anterior de ejecución por consola fue rechazado por falta de licencia válida de Runtime Engine. No se declara una suite Katalon aprobada ni se ha eludido esa restricción.

## Resultados verificables actuales

| Comprobación | Resultado | Evidencia |
|---|---|---|
| `flutter analyze --no-pub` | Sin incidencias | `qa_readiness_analyze.log` |
| `flutter test --no-pub --reporter expanded` | **173 aprobadas, 1 omitida** | `qa_readiness_flutter.log` |
| `python -m pytest -q` | **58 aprobadas**, 1 advertencia de compatibilidad de Starlette/TestClient | `qa_readiness_backend.log` |
| Restauración de sesión, antes/después | 2 fallos antes; 3 aprobadas después | `qa_session_restore_red.log`, `qa_session_restore_green.log` |
| Fotografías, antes/después | Subida aceptada y lectura 404 antes; recorrido aprobado en batería final | `qa_profile_photo_red.log`, `test_profile_photo_roundtrip.py` |
| Rechazo de secretos con espacios | 2 fallos antes; aprobadas en batería final | `qa_settings_red.log`, `test_production_settings.py` |
| Dependencias declaradas | 220 versiones consultadas en OSV, sin avisos en ese alcance | `qa_readiness_dependencies.log`, `qa/dependency_audit.json` |
| Resolución de instalación | 57 paquetes; incluye `email-validator` | `qa_clean_install_fixed.json`, `qa_clean_install_fixed.log` |
| Sintaxis Python y formato de cambios | `compileall` y `git diff --check`, salida 0 | Ejecución local de esta revisión |
| Revisión independiente | 8 pruebas de configuración/fotos y 3 de sesión aprobadas; confirmó pendientes de migración y concurrencia | Revisor separado, sin modificar archivos ni usar teléfono |

La prueba Flutter omitida requiere backend y datos preparados (`RUN_LIVE_TESTS=true`); **no cuenta como aprobada**. OSV solo cubre el alcance consultado: no certifica todas las dependencias transitivas ni Gradle/CocoaPods. La prueba ASGI de fotos inyecta identidad para aislar almacenamiento y no certifica autenticación. Las pruebas de sesión usan el adaptador de almacenamiento de pruebas; queda la verificación en dispositivo.

## Archivos de implementación modificados en esta revisión

- Backend: `fly.Dockerfile`, nuevo `.dockerignore`, `requirements.txt`, `app/core/config.py`, `app/services/sheets_service.py`, `tests/conftest.py`, nuevos `tests/test_production_settings.py` y `tests/test_profile_photo_roundtrip.py`.
- Fotografías: nuevo `app/core/file_storage.py`, `app/api/v1/endpoints/users.py`, `main.py`, `fly.toml` y `.env.example`.
- Móvil: `lib/core/auth/session_controller.dart`, nuevo `test/unit/auth/session_restore_test.dart` y corrección de un comentario de disponibilidad en `lib/core/config/environment_config.dart`.
- Informe e índice de documentación. Los demás cambios previos del repositorio se conservaron.

## Criterio de aprobación

Aprobar únicamente cuando los P1 estén cerrados con evidencia, el almacenamiento y la recuperación estén verificados en el entorno elegido, y las versiones firmadas de Android/iOS superen el recorrido administrativo real. Registrar versión de código, artefactos, entorno y resultados. Mantener explícitos los P2 aceptados y sus responsables; ningún porcentaje de pruebas sustituye estos criterios.
