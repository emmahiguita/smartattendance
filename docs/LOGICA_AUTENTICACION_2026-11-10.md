# Lógica de sesiones y recuperación

Implementada en el código el 10 de noviembre de 2026. No se desplegó el servidor ni se instaló una nueva versión móvil durante esta implementación.

## Servidor

- `auth_sessions` guarda el identificador de sesión, usuario, vencimiento, revocación y SHA-256 del token de refresco. No guarda el token en claro.
- Cada renovación genera un JWT diferente y reemplaza el resumen anterior mediante una actualización condicional. Dos renovaciones simultáneas del mismo token tienen un único ganador; la otra recibe 401.
- Los accesos nuevos incluyen `sid`. La dependencia de autenticación comprueba que esa sesión siga vigente y no revocada.
- `password_challenges` sustituye el diccionario de memoria: guarda generación, HMAC del código, vencimiento y contador de intentos. Los códigos vencen a los diez minutos y se bloquean tras cinco errores.
- El código correcto se consume una sola vez. Su consumo, la nueva contraseña y la revocación de sesiones se confirman en la misma transacción.
- La emisión de sesiones y el cambio de contraseña utilizan el mismo bloqueo condicional por usuario y revalidan la credencial. Esto impide emitir una sesión con un hash verificado antes de un cambio de clave concurrente.
- Se conservó la entrega SMTP real. Si falla, solo se invalida la generación correspondiente; no se eliminan solicitudes posteriores. No se enviaron correos durante las pruebas.

## Aplicación móvil

- Las solicitudes concurrentes comparten una operación de renovación mediante `SingleFlight`.
- Una solicitud original solo se reintenta una vez después del refresco, evitando ciclos de 401.
- Se reconoce el prefijo real de las credenciales locales. Un rechazo HTTP no se convierte en una renovación de un token offline ni en una falsa sincronización exitosa.
- La renovación respeta las sesiones efímeras: no escribe credenciales permanentes si la sesión no estaba recordada.
- El cliente HTTP temporal de renovación se cierra al terminar. Los logs no incluyen los cuerpos con credenciales.

## Pruebas

SQLite real, sesiones independientes y un caso con dos hilos comprueban rotación única, rechazo de reutilización, revocación tras cambiar la clave, persistencia de códigos, límite de intentos, expiración y conservación de usuarios al crear las tablas nuevas. Una prueba reprodujo la carrera de emisión tras cambiar la contraseña y pasó después de corregirla.

En Flutter se prueba la renovación compartida, la liberación tras error y la distinción entre tokens locales y del servidor. La batería completa se registra en `qa_auth_logic_flutter.log`; el servidor en `qa_auth_logic_tests.log`; el análisis en `qa_auth_logic_analyze.log`.

Las pruebas Python utilizan una clave de firma efímera en el proceso de pruebas, sin utilizar ni modificar el secreto real del archivo `.env`.

## Aplicación y compatibilidad

1. Las tablas se registran en `app.models` y se crean por el mecanismo existente de inicio `create_all_tables`. La incorporación es aditiva; no elimina cuentas. Antes de desplegar, revisar y aplicar el esquema una sola vez, con respaldo, antes de iniciar varios procesos.
2. Los tokens de refresco anteriores, sin `sid` persistente, requieren iniciar sesión de nuevo. Los JWT de acceso anteriores mantienen su vencimiento original; esta implementación no promete revocarlos retroactivamente. Si se necesita esa revocación, debe planificarse una transición explícita de las sesiones existentes.
3. La coordinación entre procesos presupone la misma base de datos y el mismo secreto de servidor. Se verificó SQLite; falta ejecutar las pruebas con el motor de base de datos de producción.
4. Falta comprobar el envío y recepción de un correo real autorizado y el recorrido completo de la app contra el servidor desplegado. El limitador HTTP global sigue en memoria; no se presenta como distribuido.

Este bloque de lógica está implementado y probado localmente. No certifica la preparación integral de la aplicación para producción.
