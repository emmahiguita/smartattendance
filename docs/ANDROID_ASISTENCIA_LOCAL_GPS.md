# Asistencia Android: foto y ubicación local

## Flujo activo

Inicio → Registrar asistencia → seleccionar trabajador → tomar foto → elegir
entrada, inicio de almuerzo, regreso o salida → Guardar asistencia.

Al guardar, `PhotoRepository` solicita una posición a `AttendanceLocationSource`.
`DeviceAttendanceLocation` conecta ese contrato con `LocationService`, que usa
el proveedor nativo a través de Geolocator. No usa posiciones predeterminadas.
La solicitud ocurre en primer plano y no inicia rastreo permanente.

La captura exige ubicación habilitada, permiso, coordenadas válidas, lectura de
menos de dos minutos, precisión estimada de hasta 100 m y ausencia de la bandera
`isMocked` de Android. Esta bandera no garantiza detectar toda suplantación.
Si falta señal o permiso, se conserva la foto temporal y se puede reintentar;
no se anuncia que la asistencia se guardó correctamente.

## Datos guardados

La base privada `local_photo_attendance.db`, versión 3, conserva trabajador,
documento, cargo, tipo, hora de guardado, foto, latitud, longitud, precisión
estimada y hora de la lectura de ubicación. La migración agrega columnas sin
borrar marcas anteriores. Esas marcas muestran «Sin GPS guardado»; no se les
asigna retrospectivamente la posición actual.

El historial agrupa por trabajador y día y muestra cada etapa con sus fotos,
horas y posición. PDF, XLSX y CSV conservan los datos geográficos por etapa.
XLSX y PDF incluyen fotos; CSV contiene sus nombres, no imágenes incrustadas.

## Límites explícitos

- La fotografía es evidencia visual. No hay reconocimiento de identidad ni
  prueba de vida biométrica; una captura estática no demuestra presencia viva.
- El visor existente es Flutter Map con OpenStreetMap. No se migró la app a
  Kotlin, Compose o MapLibre ni se agregaron PostGIS o WebSocket.
- Obtener GPS y guardar datos no requieren internet. La cartografía no está
  descargada para uso offline; las teselas disponibles dependen de la red/caché.
- No hay validación de geocercas autorizadas en el flujo local. El círculo del
  mapa es una indicación visual, no una zona asignada ni una autorización.
- El GPS corresponde al dispositivo del supervisor o encargado que toma la foto.
- Cambios revisados estáticamente. No se ejecutaron pruebas automatizadas ni
  interacciones automáticas en el teléfono para esta integración.
