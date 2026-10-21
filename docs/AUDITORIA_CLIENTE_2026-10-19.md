# Auditoría de cumplimiento — asistencia móvil

Fecha: 19 de octubre de 2026. Alcance: código local actual de Flutter y FastAPI, incluidos cambios sin confirmar y módulo facial nuevo; configuración, contratos API, persistencia y una observación del Android conectado. No se modificó implementación ni diseño. Este archivo es el entregable de auditoría.

## Dictamen

**NO APTA todavía para entregar como sistema de asistencia facial con prueba de vida y geocercas.** Existe una base de asistencia, autenticación, mapas, historial y exportaciones, pero los controles centrales del cliente no están implementados. La pantalla facial simula progreso y éxito. Tampoco hay proyecto iOS en esta copia.

La evaluación usa la especificación escrita entregada en el chat. No se recibió aquí el audio original ni se verificó la guía eTime; no se atribuyen requisitos adicionales a esos materiales. No se asigna un porcentaje ficticio de cumplimiento.

## Matriz contra los requisitos

| Requisito | Estado | Evidencia / consecuencia |
|---|---|---|
| Android | Parcial | Proyecto Android y aplicación observada en OPPO CPH2557, Android 15. No equivale a certificar todos los flujos ni una versión release. |
| iPhone | No implementado en esta copia | No existe `smartattendance_app/ios`; faltan configuración nativa, permisos, firma y prueba en iPhone. Flutter por sí solo no acredita entrega iOS. |
| Identificación facial | No cumple | No hay enrolamiento ni comparación de identidad en el flujo facial. |
| Prueba de vida | No cumple | Dos esperas temporizadas sustituyen el análisis; no se procesa video ni se exige resultado del servidor. |
| Entrada y salida | Parcial | Se guardan marcas; el ciclo automático incluye almuerzo obligatorio y no representa directamente entrada/salida de cualquier jornada. |
| Supervisor registra a su equipo | No cumple | La pantalla facial toma al usuario de sesión; el servidor reasigna a sí mismo cualquier marca de un no administrador. |
| Conductor registra acompañantes | No cumple | No hay permiso ni relación conductor/acompañantes. |
| Cuadrillas de tamaño variable | No cumple | `modalidad=cuadrilla_movil` es un texto; no hay entidad de cuadrilla con miembros y responsable. |
| Asignación de horarios | No cumple | Se usa un límite global de puntualidad; no hay asignaciones de turnos a empleados. |
| Horas trabajadas | Parcial | Cálculo por pares de horas del mismo día; falla para medianoche y varias jornadas. |
| Extras diurnas/nocturnas/festivas/dominicales | No cumple | Hay etiquetas de entrada/salida extra y sumas, sin clasificación por calendario y franjas ni reglas versionadas. |
| Ubicación de marcación | Parcial | Coordenadas opcionales; se acepta posición en caché sin controlar antigüedad o precisión. |
| Bloqueo fuera de geocerca | No cumple | No hay validación geográfica en el servidor; el círculo del mapa sigue al usuario. |
| Administración de trabajadores | Parcial | Creación/listado y perfiles existentes. No cubre administración de cuadrillas, turnos y zonas por período. |
| Asignar cuadrilla a zona por fechas | No cumple | Sin relación ni API correspondiente en el código inspeccionado. |
| Consulta y exportación | Parcial | Historial, estado diario y Excel/CSV; límites silenciosos y cálculo incompleto. |
| Diseño simple y profesional | Parcial | Inicio visualmente ordenado; información extensa antes de la acción, mensajes de seguridad no sustentados y funciones fuera del alcance. |
| Logotipo de la empresa | No acreditado | Se observa escudo genérico y nombre AsistenciaPro; configuración/manifiesto usan Buentiempo. Falta validar identidad visual aprobada. |
| Piloto de 3–7 días | No acreditado | No se ejecutó ese piloto ni hay evidencia suficiente de aceptación real. |

## Hallazgos de seguridad y funcionalidad

Prioridades: P0 = bloquea el piloto con datos reales; P1 = bloquea la aceptación funcional; P2 = calidad y operación.

### A01 — P0: el registro público permite adquirir rol administrador

`app/api/v1/endpoints/auth.py`, ruta `/auth/register`, es pública. `RegisterRequest` acepta `cargo` libre y `AuthService.register` lo guarda directamente. `app/api/v1/deps.py:is_admin` considera administrador a quien tenga cargo `admin` o `administrador`.

Consecuencia derivada del código: una solicitud pública con ese cargo crea una cuenta con privilegios sobre usuarios, reportes y marcaciones ajenas. No se ejecutó el ataque contra el servidor desplegado. Debe separarse cargo laboral de permisos y excluir toda concesión de permisos del registro público. Evidencia: `schemas/user.py:RegisterRequest`, `services/auth_service.py:register`, `api/v1/deps.py:is_admin`.

### A02 — P0: verificación facial y liveness simulados

`lib/features/facial/presentation/viewmodels/facial_viewmodel.dart:70` ejecuta una espera de 1.400 ms y otra de 2.000 ms y después llama a `register`. No recibe imágenes ni resultados biométricos. La interfaz usa `MobileScanner`, un escáner de códigos, como vista de cámara; no conecta su salida a reconocimiento facial. El contrato `AttendanceCreate` no requiere sesión biométrica, comparación ni prueba de vida.

Así, avanzar al éxito no demuestra presencia de un rostro, identidad ni resistencia a fotografías/videos. El flujo tampoco bloquea el botón por el error de cámara. No se probó una presentación de foto en dispositivo: la conclusión se fundamenta en el control de flujo inspeccionado.

### A03 — P0: se puede marcar sin pasar siquiera por la pantalla facial

`dashboard_action_grid.dart` expone marcación directa GPS y QR de respaldo. `home_screen.dart:_registerAttendance` registra directamente. El servidor admite marcas ordinarias sin prueba biométrica. Son vías operativas incompatibles con el requisito explícito de reconocimiento facial en cada trabajador; ocultarlas visualmente tampoco corregiría la API.

### A04 — P0: no existe restricción efectiva por geocerca

`AttendanceService.register` verifica usuario activo, UUID y tipo, luego persiste. No comprueba zona, distancia, polígono ni vigencia. `AttendanceCreate` y `AttendanceOfflineItem` permiten coordenadas nulas y carecen de límites de latitud/longitud.

En `realtime_map_viewer.dart`, `CircleMarker(point: point, radius: 60.0)` dibuja un círculo alrededor de la posición mostrada. No representa una zona autorizada fijada por el administrador. Estar dentro de ese círculo no acredita permiso para marcar. Faltan también zonas asignadas por período.

### A05 — P0: cuentas sin contraseña admiten acceso por cédula

`AuthService.login` solo exige contraseña cuando `user.hashed_password` ya existe. El modelo contempla cuentas creadas por administración sin contraseña. Conocer la cédula de una de esas cuentas permite obtener sesión, sin activación previamente acreditada. La exposición depende de qué cuentas estén en esa condición; no se inspeccionaron datos personales de la base para cuantificarla.

### A06 — P1: el flujo facial identifica al operador, no al trabajador

El proveedor al final de `facial_viewmodel.dart` toma `session.user.id`. No recibe trabajador objetivo. En `endpoints/attendance.py`, los no administradores ven reemplazado `usuario_id` por su propia identidad, tanto online como en sincronización.

Un supervisor no puede marcar a su cuadrilla con sus permisos propios. Convertirlo en administrador daría acceso excesivo y aún no resolvería la selección facial individual. Falta almacenar por separado sujeto de la marca y operador responsable.

### A07 — P1: faltan entidades operativas

No se localizaron implementación, modelos o rutas de cuadrillas, miembros, responsables, turnos, geocercas y asignaciones temporales. `modalidad` y `estacion_asignada` son textos de perfil, no esas relaciones. Los roles del servidor solo reconocen administrador frente a los demás cargos.

### A08 — P1: segunda marcación automática significa almuerzo

`AttendanceService._decide_tipo` implementa `entrada → salida_almuerzo → regreso_almuerzo → salida`. Un trabajador que solo marca al comenzar y terminar obtiene una salida a almuerzo en su segunda marca. No existe configuración de jornada que permita aplicar la secuencia adecuada por turno. El flujo debe verificarse contra los casos reales del cliente.

### A09 — P1: el servidor acepta el tipo de marca enviado por el cliente

Aunque los comentarios dicen que decide el servidor, `tipo = data.tipo or self._decide_tipo(...)` acepta cualquier tipo permitido sin validar transición. Pueden persistirse salidas sin entrada y secuencias repetidas; una UUID nueva evita la deduplicación de transporte. No hay validación de jornada abierta ni de solapamientos. Una UUID evita reenviar la misma petición; no impide duplicados funcionales con identificadores distintos.

### A10 — P1: horas extras offline no se pueden sincronizar

`schemas/attendance.py` permite `hora_extra_entrada` y `hora_extra_salida`; `schemas/sync.py` solo admite cuatro tipos ordinarios. La app encola el mismo tipo extra al fallar la red y luego lo envía a `/attendance/sync`. La validación de ese lote lo rechaza con 422; si mezcla otras marcas, tampoco se procesan. La cola no dispone de traducción a un contrato compatible.

### A11 — P1: los registros faciales offline sin tipo quedan siempre como entrada

La tarjeta facial ordinaria navega sin `tipo`; el repositorio resuelve el fallo de red con `tipo ?? 'entrada'`. Varias marcaciones faciales offline de la jornada se almacenan como entradas. Esto difiere del comportamiento online, donde se elige secuencia. La operación sin internet sigue siendo una decisión pendiente del cliente y no debe presentarse como resuelta.

### A12 — P1: cálculo de horas insuficiente para operación real

`AttendanceExportService` agrupa por trabajador y fecha, luego convierte las marcas a `{tipo: hora}`: conserva solo una hora por tipo, perdiendo varias jornadas o intervalos extra del mismo día. `_calculate_worked_seconds` combina horas con una fecha artificial; 22:00–06:00 produce diferencia negativa y no suma tiempo. Agrupar por fecha separa además entrada y salida de turnos nocturnos.

Las horas extra se suman al total; no hay desglose diurno/nocturno/dominical/festivo ni jornada asignada para identificar exceso automáticamente. No se validó legislación ni se inventaron tarifas: antes de implementar deben confirmarse país, calendario y reglas laborales aplicables con vigencia.

### A13 — P1: ubicación obsoleta o inexistente presentada como válida

`LocationService._capture` usa primero `getLastKnownPosition`, sin validar edad, `accuracy` ni señal de ubicación simulada. El timeout retorna null; el repositorio sigue marcando sin coordenadas. El viewmodel facial captura ubicación otra vez, por lo que la mostrada puede diferir de la enviada.

Con ubicación nula, el éxito usa el texto «Coordenadas GPS confirmadas». La pantalla también afirma «Firmando con satélites GPS», aunque no hay firma criptográfica de la ubicación. La calidad y vigencia de la muestra deben formar parte del resultado verificable; ningún GPS de teléfono garantiza por sí solo ausencia de suplantación.

### A14 — P1: no existe entrega iOS verificable

Ausencia comprobada de `smartattendance_app/ios`. No se compiló ni probó en iPhone. Se necesitan proyecto nativo, permisos, integración de cámara/biometría, firma, distribución de prueba y validación en un iPhone real. El SDK biométrico elegido debe soportar ambas plataformas y su integración con Flutter debe demostrarse.

### A15 — P1: sincronización confía en fecha/hora del cliente

`AttendanceRepository.create_from_offline` persiste directamente `fecha_hora_local.date()` y `.time()` sin ventana temporal, conversión de zona ni evidencia de captura. Fechas futuras/pasadas y diferencias de zona no reciben tratamiento. Si el tipo es nulo, la decisión usa el estado de hoy, no el de la fecha histórica sincronizada. El UUID se busca globalmente sin verificar sujeto antes de devolver una marca existente; esto merece una comprobación aislada adicional de autorización.

### A16 — P2: consultas y exportaciones incompletas silenciosamente

La app solicita historiales sin recorrer páginas; el servidor devuelve 100 por usuario y 200 enriquecidos por defecto. Los resúmenes construidos con esas listas pueden omitir registros. Las exportaciones limitan a 10.000 marcas sin indicar truncamiento al usuario. Un período con más registros puede generar un reporte incompleto.

### A17 — P2: configuración de desarrollo y transporte

`EnvironmentConfig` está fijado en development: localhost por defecto, logging activo y HTTPS no exigido. La URL puede cambiarse en ajustes; por eso no se afirma que toda instalación esté conectada a localhost. Android permite HTTP mediante `usesCleartextTraffic=true`. Para el piloto hay que verificar el artefacto distribuido y su destino real, exigir transporte seguro y revisar qué datos registra el logger. No se inspeccionaron secretos ni se probaron interceptaciones.

### A18 — P2: ciclo de vida durante la secuencia facial

Las esperas y operaciones del viewmodel continúan sin cancelación explícita al abandonar una pantalla cuyo proveedor es autoDispose. Existe riesgo de marca tardía o de actualización de estado tras dispose; falta prueba en dispositivo. Además, la marca offline devuelve un modelo de éxito igual al online, y la pantalla facial no transporta un estado de «pendiente de validación» a la confirmación.

## Auditoría del diseño móvil existente

Observación directa: captura y jerarquía del inicio en Android con ARTEMIS. Se ve jerarquía visual clara, tarjetas legibles, navegación inferior y mapa. En ese primer viewport no aparece la acción de asistencia: encabezado, mapa y estado del día ocupan la altura. El código ubica las acciones después de esos elementos; obliga a desplazarse para la tarea principal. No se acreditaron tamaño de texto ampliado, lector de pantalla, contraste completo, teclado, orientación horizontal ni todos los tamaños de pantalla.

Problemas del diseño funcional:

- «Escanear Rostro con IA» y «Analizando biometría y liveness» prometen una verificación que el código no realiza.
- «GPS EN VIVO» y «GPS Activo y Calibrado» exceden la garantía disponible: la ubicación se captura al iniciar/refrescar y puede provenir de caché. No hay seguimiento continuo demostrado.
- «Punto geográfico asignado» y el círculo sugieren autorización geográfica sin zona del administrador.
- Falta contexto explícito de trabajador objetivo, operador, cuadrilla, turno y zona vigente.
- No se encontró flujo de enrolamiento biométrico ni de recuperación ante rostro no reconocido, vida fallida o mala calidad.
- QR y marcación directa contradicen el alcance. La mensajería interna existe, pero no fue pedida; no debe contarse como cumplimiento ni ampliar la cotización automáticamente.
- El escudo y nombres de producto no acreditan el logotipo empresarial aprobado.

Son observaciones y criterios de aceptación; no se rediseñaron pantallas.

## Qué datos e integración facial se necesitan

No basta con añadir una librería de cámara ni animar un óvalo. Deben existir tres capacidades distintas: capturar con calidad, verificar presencia real y comparar identidad contra un enrolamiento confiable. Para un dispositivo compartido es razonable seleccionar un trabajador de la cuadrilla y verificar 1:1; identificarlo automáticamente entre muchos rostros requiere búsqueda 1:N y controles adicionales. Esa elección debe validarse con el cliente.

Datos mínimos propuestos para cerrar la brecha, sujetos a política de tratamiento y retención:

| Área | Datos necesarios |
|---|---|
| Trabajador | Identificador estable, cédula según necesidad, nombre y estado; no exige instalar app ni crear contraseña por trabajador. |
| Operador | Cuenta de supervisor/conductor/encargado, permisos y relación vigente con trabajadores/cuadrillas. |
| Enrolamiento | Referencia biométrica o identificador del proveedor, vínculo verificado con empleado, calidad, versión, fecha y responsable. Una foto de perfil cualquiera no acredita identidad. |
| Prueba facial | Sesión efímera, desafío, vencimiento, resultado de vida y comparación, umbrales y versión del motor. Decisión contrastada en servidor y ligada al trabajador y a esa marca; impedir reutilización. |
| Marca | Trabajador y operador separados, entrada/salida, fecha/hora y zona horaria, identificador idempotente, estado confirmado/pendiente/rechazado y evidencia vinculada. |
| Ubicación | Latitud/longitud, momento de captura, precisión, señales disponibles de simulación y zona/version aplicada. |
| Organización | Cuadrilla, membresía, responsable, zona autorizada y período de vigencia. |
| Jornada | Turno asignado, descansos, cruce de medianoche, calendario y reglas para clasificar horas. |
| Trazabilidad | Motivo de rechazo/corrección, actor, fecha, referencia de evidencia y política de acceso/retención. |

No hace falta añadir fecha de nacimiento, domicilio particular, documento fotografiado o seguimiento GPS permanente salvo justificación y autorización. No se recomienda conservar videos biométricos indefinidamente.

### Tecnología a evaluar, sin instalar ni contratar

- **ML Kit Face Detection** puede ayudar a localizar rostro, ojos, orientación y expresiones. Su documentación dice expresamente que no reconoce personas. No satisface identidad ni demuestra por sí solo prueba de vida robusta. Fuente: https://developers.google.com/ml-kit/vision/face-detection
- **Amazon Rekognition Face Liveness + CompareFaces** es un candidato documentado que separa vivacidad y comparación. Liveness devuelve puntuación e imagen de referencia; hay componentes móviles nativos Android y Swift/iOS. En esta app Flutter se debe comprobar integración nativa, soporte de dispositivos, región, conectividad, costos y tratamiento de datos antes de elegirlo. No se afirma que exista un SDK Flutter oficial equivalente. Fuentes: https://docs.aws.amazon.com/rekognition/latest/dg/face-liveness.html y https://docs.aws.amazon.com/rekognition/latest/APIReference/API_CompareFaces.html
- Una alternativa local requiere modelo de identidad, motor anti-suplantación, licencias y validación independiente en ambos sistemas; no equivale a sumar parpadeo/sonrisa. La selección no puede cerrarse antes de decidir el requisito offline.

Las puntuaciones biométricas son probabilísticas. Deben medirse falsos rechazos/aceptaciones en la población y condiciones reales; no prometer identificación perfecta. Para geocercas ya existen geolocator y flutter_map: lo ausente es la configuración de zonas y la decisión de autorización en servidor. Horarios y clasificación de horas requieren reglas deterministas, no IA conversacional.

## Verificación realizada y límites

- Se indexó el repositorio sin persistir un nuevo artefacto del grafo y se inspeccionaron funciones, modelos, rutas y configuraciones actuales.
- Se observó inicio del OPPO conectado mediante jerarquía y captura de ARTEMIS. No se alteró asistencia ni se ejecutó un ataque en producción. No se acredita que el binario instalado corresponda exactamente al código local.
- ARTEMIS diagnóstico: dispositivo disponible; automatización bloqueada por ausencia de credencial multimodal. También informa puerto 8000 ocupado por otro proceso; es advertencia opcional y no se detuvo ese proceso. Para habilitar exploración se requiere agregar la credencial en `C:\Users\emman\artemis\.env` o configuración MCP y reiniciar el servidor MCP; nunca pegarla en el chat.
- `flutter analyze --no-pub` no inició por ausencia de `pwsh` en el entorno. Se ejecutó el analizador Dart directamente: **22 observaciones, 1 warning y 21 informativas; no se reportaron errores de análisis**. Warning: comparación imposible con null en `profile_repository_impl.dart:202`. Al terminar hubo error de permisos de telemetría; esto no constituye build exitoso ni prueba funcional.
- El entorno virtual Python del backend apunta a una instalación eliminada. Se encontró Python del sistema con dependencias y se intentaron las pruebas existentes usando SQLite en memoria, una clave solo de prueba y sin caché de pytest; no se usó la base operativa. La ejecución no produjo resultados y se interrumpió: no hay suite aprobada ni fallos funcionales atribuidos a esa ejecución. Una futura ejecución debe usar una base temporal aislada compatible con los distintos hilos de TestClient.
- Las pruebas existentes de asistencia limpian tablas mediante el engine configurado. No deben ejecutarse directamente sobre una base con datos reales.
- No se escribieron tests móviles sin exploración previa, ni se ejecutó piloto de 3–7 días, build iOS o ensayo antifraude.

## Criterios para aceptar un piloto futuro

1. Cerrar registro público con escalada administrativa y acceso a cuentas sin activación segura.
2. Demostrar en Android e iPhone que ausencia de rostro, persona distinta, foto, video y vida fallida no generan marca; validar resultado en servidor sin rutas alternativas de bypass.
3. Enrolar un trabajador con identidad comprobada y verificarlo individualmente desde el teléfono del operador.
4. Registrar entrada y salida de cuadrillas de 4, 5 y más integrantes mediante supervisor y conductor, sin darles administración global y sin cuenta móvil por trabajador.
5. Rechazar marcas fuera de zona, sin ubicación válida o fuera de vigencia; probar bordes, precisión y cambios de asignación.
6. Asignar turnos y contrastar el cálculo con resultados esperados de jornada normal, varios intervalos, medianoche, extras y calendario aplicable.
7. Decidir funcionamiento offline y aprobación de extras; si se admite offline, distinguir captura pendiente de aceptación final y probar sincronización/idempotencia.
8. Entregar binarios de prueba identificables, identidad visual aprobada, servicio accesible y evidencia del piloto de 3–7 días.

Hasta cumplir esos puntos, la aplicación debe describirse como base parcial de asistencia y demostración de interfaz facial, no como reconocimiento facial empresarial listo para uso real.
