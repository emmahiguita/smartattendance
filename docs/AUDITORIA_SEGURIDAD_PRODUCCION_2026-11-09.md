# Auditoría de seguridad y preparación para producción

Fecha: 9 de noviembre de 2026, Colombia. Alcance: código Flutter/Android/iOS y servidor Python, configuración, dependencias declaradas, controles de acceso y pruebas locales. No hubo despliegue del servidor ni envío de correos.

## Dictamen

**Pendiente de aprobación para producción.** Las correcciones se han verificado mediante análisis y pruebas automatizadas. La prueba integral del teléfono no está aprobada: el usuario confirmó que otra prueba estaba usando el mismo dispositivo y se detuvo nuestra interacción. iOS, entrega real de correo, sincronización con el servidor desplegado y firma de distribución siguen sin verificar.

## Problemas reproducidos y corregidos

| Prioridad | Problema | Corrección y evidencia |
|---|---|---|
| Crítica | El registro público del servidor aceptaba un cargo administrativo | Se rechazan roles distintos del de empleado en el registro público; los mandos se asignan por la ruta administrativa. `test_auth_boundaries.py` reprodujo el fallo antes de corregirlo. |
| Crítica | Una cuenta del servidor sin contraseña recibía tokens al presentar su documento | Se exige una contraseña establecida y válida. La misma prueba reprodujo el acceso anterior y ahora lo rechaza. |
| Crítica | La migración local aceptaba contraseñas comunes para cuentas cuya credencial era la cédula | Se eliminó la excepción. `legacy_login_boundary_test.dart` falló antes del cambio y pasó después; también comprueba que un intento fallido no altera la cuenta. |
| Alta | Altas locales con contraseña compartida y posibles cambios parciales de trabajador/sitio/equipo | Contraseñas individuales PBKDF2 con sal, confirmación en formulario y operación transaccional entre las bases locales. Pruebas de SQLite verifican cinco trabajadores, autenticación, permisos y reversión de duplicados. |
| Alta | Falta de recuperación local comprobable | Acción «Establecer contraseña» con confirmación, validación y autorización en el almacén; el administrador actúa sobre las cuentas autorizadas y el supervisor sobre sus operarios. Hay prueba real de persistencia y rechazo de equipo ajeno. |
| Alta | Tokens firmados sin expiración aceptados por el servidor | La verificación exige `exp` y `sub`. Se comprueban vencimiento, firma y separación entre acceso y refresco. |
| Alta | Dependencias declaradas con avisos de OSV | Se sustituyó python-jose por PyJWT 2.15.1 y se actualizaron python-multipart, pytest y pytest-asyncio. La segunda consulta de 219 versiones exactas no devolvió avisos en ese alcance. |
| Media | HTTP sin cifrar habilitado en todas las compilaciones Android | Se deshabilita en el manifiesto principal y se permite explícitamente en debug. |
| Media | Los registros HTTP podían incluir contraseñas, datos personales o tokens | Se retiraron los cuerpos de solicitudes/respuestas del registro y se limita el detalle del error de API a su tipo. |
| Media | La carga de fotos leía el archivo entero antes de aplicar el límite | Se limita la lectura a 2 MiB más un byte. Una prueba con un archivo temporal real reprodujo y comprobó el límite de lectura. |
| Media | Horarios, GPS y horas trabajadas podían mostrar valores de respaldo o extras no observadas | Se retiraron los valores ficticios; las tolerancias conservan el cruce de medianoche y las horas efectivas dependen de los registros. |

## Verificación y artefactos

- Flutter: 166 pruebas aprobadas y una omitida; resultado completo en `qa_flutter_final_tests.log`; análisis sin incidencias en `qa_flutter_analyze.log`.
- Servidor: 35 pruebas aprobadas, dos advertencias de compatibilidad/deprecación del entorno de pruebas. Registro: `qa_backend_tests.log`. El entorno aislado de auditoría usa los paquetes de seguridad actualizados y bibliotecas base del equipo; no constituye una instalación limpia completa de producción.
- Dependencias: `qa/dependency_audit.json` y ejecutor `qa/audit_dependencies.py`. Cubre requisitos Python con versión exacta y paquetes alojados de `pubspec.lock`; no cubre rangos Python sin fijar, dependencias nativas Gradle/CocoaPods ni historial completo de vulnerabilidades.
- Secretos: no se encontraron coincidencias de los patrones revisados de claves privadas/API en `lib`, `app` y `.github`, ni archivos de credenciales coincidentes entre los archivos versionados. El `.env` del servidor está ignorado; se verificó la presencia de configuración y longitud de la clave sin imprimir valores. No equivale a auditar todo el historial Git o servicios externos.
- Android 1.0.1 / código 20261109 se compiló e instaló conservando los datos. Esta instalación precede a la última corrección de migración local y **no representa el código final de seguridad**.
- El APK final 1.0.2 / código 20261110 se compiló después de corregir la migración y se instaló conservando los datos; registro `qa_android_final_build.log`. La copia verificable se conserva como `qa/artifacts/BuenTiempo-1.0.2-debug.apk`.
- Posteriormente el usuario liberó el teléfono. Se comprobaron los cinco registros ya existentes de la ejecución QA: ambas bases, equipo común, permisos operativos, ventanas fijas/flexibles, sitio persistido y sesión tras reinicio. Registro `qa_device_verification.log`. Esto no equivale a repetir todas las acciones de creación desde cero.
- Se resolvió y grabó el caso de pantalla negra al enfocar una contraseña: el teclado seguro de OPPO bloqueaba la captura. Se desactivó ese ajuste con autorización expresa, conservando el enmascaramiento; detalle y evidencia en `GRABACION_SCRCPY_ANDROID.md`.
- Katalon: sus dos casos utilizan el motor `qa/mobile`, con esperas y verificaciones de interfaz y SQLite. Los originales se conservaron fuera de los casos activos. La ejecución integral no está aprobada; los intentos fallidos no se presentan como éxitos.

## Riesgos y comprobaciones pendientes

1. Ejecutar el flujo exclusivo del teléfono: administrador autenticado, supervisor nuevo, cinco trabajadores, sitio GPS, horarios fijo/flexible, duplicados, aislamiento, edición y persistencia. Coordinar el dispositivo con la otra prueba antes de instalar o controlar la app.
2. Completar la revisión visual de todas las pantallas del APK final y su accesibilidad; el rediseño usa secciones abiertas, texto neutro y divisores.
3. Configurar la firma Android de distribución: `android/key.properties` no estaba presente. La compilación instalada es de depuración. Compilar y probar iOS con Mac, Xcode, firma y configuración OAuth reales.
4. Probar autenticación y sincronización contra el servidor desplegado. Las bases locales y el servidor no se vuelven una única base por pasar las pruebas locales.
5. Verificar entrega de recuperación por correo con una cuenta QA autorizada. Los códigos y el limitador del servidor están en memoria del proceso: requieren una solución compartida/persistente para despliegues con varios trabajadores o reinicios.
6. Revisar revocación de tokens de refresco y la política de fallback local cuando el servidor rechaza una cuenta. El soporte offline no demuestra revocación central inmediata.
7. Verificar los límites de carga en el proxy de despliegue, además del límite de lectura corregido en la aplicación.
8. Crear una instalación reproducible de todas las dependencias del servidor, con versión de Python y dependencias transitivas fijadas. El entorno virtual antiguo del repositorio apunta a un Python que ya no está instalado en el equipo.

## Referencias

Material 3: [divisores](https://m3.material.io/components/divider/overview). Avisos consultados en OSV: [python-jose](https://osv.dev/vulnerability/GHSA-3qf3-8w2g-rqmx), [python-multipart](https://osv.dev/vulnerability/GHSA-v9pg-7xvm-68hf), [pytest](https://osv.dev/vulnerability/GHSA-6w46-j5rx-g56g). La ausencia de avisos en una consulta no certifica que no existan vulnerabilidades.
