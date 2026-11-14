# Continuación de preproducción: autenticación y cierre de sesión

**Cambios verificados localmente. Aprobación de producción pendiente.** Esta revisión continúa los puntos de sesión de [la auditoría de preproducción](REVISION_PREPRODUCCION_2026-11-10.md).

| Hallazgo de la auditoría | Cambio aplicado | Evidencia |
|---|---|---|
| Renovar durante el cierre podía recuperar credenciales borradas. | Las escrituras y borrados comparten una cola. Cerrar invalida inmediatamente la generación de sesión. Una renovación antigua no instala sus resultados y una petición antigua no cierra una sesión distinta. | `test/integration/auth_session_boundaries_test.dart` detiene la escritura, cierra y reanuda; verifica memoria y almacenamiento. Fallaba antes del cambio. |
| El rechazo HTTP podía dar paso a SQLite. | Se respeta cualquier respuesta HTTP del login; solo se usa respaldo automático ante errores de transporte sin respuesta. El acceso directo local exige que el sistema confirme desconexión. Eliminado el límite artificial de dos segundos para la respuesta de login. | Casos HTTP 401, 403 y 429 sobre un servicio local y una cuenta en SQLite temporal. Los tres fallaban antes. El acceso offline explícito sigue pasando. |
| Cerrar en el teléfono no revocaba en el servidor. | `POST /api/v1/auth/logout` revoca el identificador de sesión firmado en el refresco. Acepta el refresco firmado anterior de esa misma sesión si rotó mientras se salía. El cliente borra localmente y solicita la revocación al emisor, con aviso si no confirma. | `test_logout.py`: antes 404; ahora comprueba cierre idempotente, rechazo de accesos/refresco de la sesión cerrada y conservación de otra sesión del mismo usuario. |
| Un cambio de servidor podía reutilizar credenciales anteriores. | Se guarda el servidor emisor con la sesión. Se comprueba el destino al enviar tokens y no se siguen redirecciones autenticadas. La revocación usa la dirección emisora capturada. La configuración de producción exige HTTPS. | Regresión que verifica que la renovación no llega a otro servidor; revisión independiente del flujo de peticiones y cierre. |
| Un error temporal podía borrar la sesión. | Se distingue rechazo de credencial (400/401/403) de indisponibilidad. Un error de borrado en el interceptor tampoco deja sin resolver la petición. | Caso HTTP 503 conserva el par en memoria; revisión de código. |

Los ensayos Flutter usan HTTP local y SQLite temporal. El adaptador de pruebas de SecureStorage permite forzar el orden de escrituras; no es una prueba de Keystore/Keychain. La API usa SQLite temporal y las rutas reales mediante el cliente ASGI. No se enviaron correos, no se cambió la configuración de producción y no se eliminaron cuentas ni registros.

## Resultados

- Flutter: **179 aprobadas y 1 omitida**; la omitida necesita servidor y datos preparados. `qa_sessions_flutter.log`.
- Servidor: **59 aprobadas**, una advertencia de Starlette. `qa_sessions_backend.log`.
- Análisis Flutter: sin incidencias. `qa_sessions_analyze.log`.
- Revisión independiente: 6 pruebas focalizadas de rotación y revocación; los cuatro hallazgos de esa revisión se corrigieron y volvieron a revisarse.
- Consulta pública de `/health`: agotó el tiempo de espera en esta revisión; la consulta de la auditoría anterior devolvió 404. `qa/session_remote_health.json`. Ninguno verifica un servidor listo.

## Android instalado y comprobado

- Compilación debug aprobada: **1.0.3**, código **20261112**. APK: `qa/artifacts/BuenTiempo-1.0.3-debug.apk`. SHA-256: `bac270155bbc8ade84a46408165e1e49e5d12fd93c358258307cba2c6b1a3f35`.
- Instalado mediante actualización (`adb install -r`) en OPPO CPH2557, Android 15. No se desinstaló la app ni se ejecutó borrado de datos. Evidencias: `qa_sessions_android_build.log`, `qa_sessions_android_install.log`.
- Prueba básica real aprobada: arranque con sesión existente, Inicio → Perfil → Inicio. Resultado y JUnit en `qa/artifacts/session_smoke/automation_1794359745682896300/`. Se revisó la captura final: pantalla normal, fondo negro, texto legible y divisores.
- Inventario de lectura: **27 trabajadores y 29 cuentas**; cero documentos duplicados normalizados en cada tabla y cero trabajadores sin cuenta. Esto no revisa duplicados por nombres, equipos, nómina ni todos los datos de negocio. `qa/session_device_data_inventory.json`.
- Los **cinco registros QA esperados del estado de una ejecución antigua no aparecen en estas bases actuales**. La comprobación de esos registros no aprobó. No se atribuye la causa sin una instantánea anterior comparable; no se recrearon ni borraron registros para cambiar ese resultado.
- La prueba básica no incluye un inicio de sesión nuevo, creación del supervisor/cinco trabajadores, recuperación ni cierre remoto contra producción. Katalon Runtime Engine no se ejecutó en esta continuación; se utilizó ADB/UIAutomator para la comprobación básica.

## Compatibilidad y condiciones pendientes

- Las sesiones remotas guardadas por versiones anteriores que no tienen servidor emisor requieren iniciar sesión nuevamente. Las sesiones locales recordadas conservan su formato y no necesitan un servidor.
- El cierre remoto solo se acredita cuando el servidor confirma la solicitud. Sin conexión, se cierra en el teléfono y no se asegura revocación remota. Los JWT anteriores sin identificador de sesión no adquieren revocación retroactiva.
- Sigue pendiente desplegar la ruta nueva, confirmar la URL de producción, validar recuperación y entrega de correo, y resolver la política de expiración y bajas en dispositivos deliberadamente desconectados.
- Sigue pendiente migrar las fotografías anteriores al almacenamiento persistente, ejecutar pruebas firmadas iOS/Android y completar el recorrido real administrador → supervisor → cinco trabajadores, sitio y horarios. Las pruebas locales no acreditan el recorrido en el dispositivo.

## Comprobación adicional del historial remoto

Se consultó GitHub en modo de lectura, sin publicar commits ni disparar despliegues:

- El último despliegue registrado para la API (`7369915376`, 27 de octubre) figura **failure** y apunta a `https://smartattendance-api-fnvo.onrender.com`, distinta de la URL predeterminada compilada. La consulta de salud a esa dirección también agotó el tiempo de espera. No se cambió la app a una dirección cuya salud no se pudo confirmar. Evidencias: `qa/github_latest_api_deployment.json` y `qa/github_deployment_health.json`.
- La ejecución histórica de iOS `40614307970` fue exitosa sobre `e5969a0d71e5bab91db7ad43162af8606bd09cb2`, pero su comando fue `flutter build ios --release --no-codesign`. Acredita una compilación antigua sin firma, no esta revisión, una instalación en iPhone ni preparación para App Store. Evidencia: `qa/github_last_ios_build.json`.
