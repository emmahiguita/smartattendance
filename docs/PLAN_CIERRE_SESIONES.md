# Plan de corrección de sesiones

1. Reproducir el rechazo remoto con HTTP local y credenciales válidas en SQLite temporal. Comprobar que el acceso sin conexión conserve su funcionamiento.
2. Pausar una escritura de renovación en la prueba, cerrar sesión y reanudarla. Serializar cambios de credenciales y descartar respuestas de una sesión que ya terminó.
3. Probar revocación en la API con SQLite: el cierre debe invalidar acceso y refresco de esa sesión y conservar otras sesiones del usuario.
4. Ejecutar las suites, revisar de forma independiente y documentar límites de despliegue, dispositivo y revocación sin conexión.
