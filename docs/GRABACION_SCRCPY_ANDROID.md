# Grabación con contraseñas enmascaradas

Verificado el 9 de noviembre de 2026 en OPPO CPH2557, Android 15, scrcpy 4.1.

El bloqueo provenía de la ventana de sistema `OplusSecurityInputMethod`, marcada como segura. La ventana de BuenTiempo no tenía `FLAG_SECURE`; no fue necesario cambiar la aplicación ni mostrar la contraseña.

Con autorización del usuario se desactivó **Ajustes → Sistema y actualización → Teclado y método de entrada → Teclado seguro para contraseñas**. Es un ajuste del teléfono que afecta a todas sus aplicaciones y se puede volver a activar desde la misma ruta.

Se grabó un campo de contraseña con texto de prueba enmascarado. La grabación contiene la pantalla normal con puntos, sin pantalla negra. El texto de prueba se eliminó y el formulario se cerró sin guardar.

- Video: `qa/artifacts/password_capture.mp4`.
- Fotograma comprobado: `qa/artifacts/password_capture_frame.png`.

Android también puede proteger otras ventanas sensibles; este resultado verifica el caso concreto del teclado de OPPO y no promete capturar cualquier pantalla protegida del sistema.
