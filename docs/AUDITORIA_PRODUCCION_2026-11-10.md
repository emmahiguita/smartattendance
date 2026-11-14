# Auditoría actualizada de producción — 10 de noviembre de 2026

## Resultado

**No aprobado todavía para producción.** Se revisaron el repositorio local, autenticación móvil y del servidor, permisos, configuración, dependencias declaradas y patrones de secretos. Se corrigieron dos problemas adicionales y se ejecutaron comprobaciones nuevas. No se desplegó el servidor ni se instaló un APK con las correcciones de esta revisión.

## Hallazgos corregidos

| Prioridad | Hallazgo confirmado | Cambio | Evidencia |
|---|---|---|---|
| Alta | La clasificación móvil concedía administración por contener la palabra «administrador»: incluso «No administrador» y «Administrador de redes» resultaban administrativos. | Lista explícita de roles, incluida la denominación Administrador General; autenticación local y UI usan el mismo clasificador. | `supervisor_scope_test.dart`: caso nuevo falló antes y pasó después. |
| Alta | Google Sign-In seleccionaba una cuenta local por correo sin comprobar `email_verified` ni la autoridad de Google sobre ese correo. | Política de claims posterior a la verificación criptográfica: exige sujeto, correo verificado y Gmail o dominio Workspace coincidente. Otros correos deben usar contraseña hasta contar con vinculación adicional. | Siete casos de política, incluidos correo no verificado, dominio externo, dominio discrepante y ausencia de sujeto. No es una prueba contra una cuenta Google real. |

Cambios: `lib/core/utils/roles.dart`, `lib/features/auth/data/datasources/local_auth_datasource.dart`, `app/services/auth_service.py`, nuevo `app/services/google_identity_policy.py` y pruebas correspondientes.

La política de Google se basa en la distinción entre correo verificado y correo sobre el que Google tiene autoridad, descrita en su [documentación oficial de autenticación de servidor](https://developers.google.com/identity/sign-in/web/backend-auth). La verificación de firma, audiencia y emisor continúa delegada al verificador Google existente. La vinculación permanente por `sub` sigue pendiente.

## Resultados nuevos

| Comprobación | Resultado | Evidencia local |
|---|---|---|
| Flutter, análisis estático | Sin incidencias | `qa_audit_20261110_analyze.log` |
| Flutter, batería completa | 167 aprobadas, una omitida | `qa_audit_20261110_flutter.log` |
| Servidor | 42 aprobadas; dos advertencias del entorno de pruebas | `qa_audit_20261110_backend.log` |
| Dependencias declaradas | 219 versiones consultadas en OSV; sin avisos en ese alcance | `qa_audit_20261110_dependencies.log`, `qa/dependency_audit.json` |
| Secretos, código actual | Sin coincidencias de los patrones de API/claves privadas revisados en app, servidor y workflows; sin archivos de credenciales coincidentes entre los versionados | Comprobación de rutas y patrones, sin imprimir valores |
| Historial Git | 36 revisiones comprobadas; sin coincidencias de esos patrones en las extensiones seleccionadas | `qa/audit_20261110_secret_history.json` |
| Sintaxis Python | Compilación sin errores de `smartattendance_backend/app` | `python -m compileall -q smartattendance_backend/app` |

La consulta de dependencias no cubre rangos Python sin fijar, todas las dependencias transitivas instaladas ni Gradle/CocoaPods. La búsqueda de secretos no detecta todos los formatos, contraseñas genéricas ni secretos en servicios externos. El entorno Python de auditoría comparte bibliotecas base del equipo; las pruebas no acreditan una instalación limpia completa de producción.

## Comprobaciones de regresiones anteriores

La batería incluye rechazo de cuentas sin contraseña del servidor, rechazo de roles administrativos en registro público, tokens sin expiración/firma válida, límite de lectura de fotografías y migraciones locales que intenten admitir claves comunes. También incluye altas reales sobre SQLite temporal de un supervisor y cinco trabajadores, autenticación, rechazo de duplicados y permisos sobre equipos ajenos. Estas pruebas de repositorio no sustituyen el recorrido completo de interfaz en Android o iOS.

## Bloqueos de producción pendientes

1. Ejecutar el recorrido completo en dispositivo sobre el código de esta revisión: administrador, supervisor, cinco trabajadores, sitios, horarios, errores, edición y recuperación. Katalon Runtime Engine seguía sin licencia activa en la comprobación anterior; no se declara una suite Katalon aprobada.
2. Compilar e instalar un APK identificable con esta revisión; confirmar textos, permisos del sistema y todas las pantallas. La instalación 1.0.2 anterior no contiene los cambios nuevos de clasificación de roles.
3. Preparar firma Android de distribución. No se encontró `android/key.properties`; la ausencia de ese archivo no acredita por sí sola otras formas de firma externas.
4. Compilar y probar iOS con Mac/Xcode, firma y OAuth reales.
5. Probar el servidor desplegado, sincronización y entrega de correo con una cuenta QA autorizada. No se enviaron correos ni mensajes a terceros durante esta auditoría.
6. Persistir/compartir códigos de recuperación y limitador de intentos para varios procesos; actualmente permanecen en memoria. Revisar revocación/rotación efectiva de refrescos y la política de fallback offline ante rechazo del servidor.
7. Vincular identidades Google por `sub` con migración controlada. El cambio actual reduce el riesgo del lookup por correo; no completa esa migración.
8. Fijar versión Python y dependencias transitivas en una instalación reproducible; validar también límites y configuración del proxy de producción.

La aprobación requiere cerrar estos puntos con resultados reproducibles; los resultados de pruebas no constituyen una garantía de ausencia total de fallos.
