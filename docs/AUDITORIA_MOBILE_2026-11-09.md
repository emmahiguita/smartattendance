# Auditoría móvil: 9 de noviembre de 2026

Instantánea anterior a las correcciones de esta jornada. Consultar el [informe posterior de seguridad y producción](AUDITORIA_SEGURIDAD_PRODUCCION_2026-11-09.md) para resultados y pendientes actualizados.

Alcance: revisión del código actual, casos existentes de Katalon, pruebas de Flutter y observación de la pantalla principal en un Android conectado. Esta revisión no certifica el funcionamiento de todas las operaciones.

## Hallazgos prioritarios

1. **Crítico: credencial compartida.** El alta local de personal sigue guardando una contraseña inicial fija en `photo_repository.dart`. La autenticación de origen ya exige coincidencia con el valor guardado y rechaza usar el documento como contraseña, pero no hay evidencia de activación individual y recuperación real para las cuentas nuevas. No se ha comprobado que el APK instalado corresponda al código corregido.
2. **Alto: Katalon puede reportar falsos éxitos.** Los casos registran `markPassed` sin verificar los resultados; los comandos ADB ignoran el código de salida. El acceso automatizado no introduce contraseña y contiene coordenadas con una coma. Las coordenadas y demoras fijas hacen la prueba frágil. Se encontraron dos casos y una suite, pero ningún informe de ejecución de los casos.
3. **Alto: el caso de supervisor no cubre el objetivo.** Solo intenta registrar dos trabajadores, no cinco, y describe formatos de 12 y 24 horas, que no equivalen a comprobar horario fijo y ventana flexible. No verifica persistencia, permisos, aislamiento ni recuperación.
4. **Alto: cambios parciales.** `worker_dialog.dart` guarda una zona y puede actualizar la zona de una cuadrilla antes de registrar el trabajador. Si el registro posterior falla, la modificación previa puede permanecer. El alta entre dos bases usa compensación tras error, pero no constituye una transacción única entre ambas.
5. **Alto: recuperación no demostrada.** Existen llamadas a endpoints remotos de recuperación, pero no se ha verificado la entrega real del código ni el restablecimiento para cuentas locales. Hay que probar ambos casos antes de desplegar una política que bloquee contraseñas anteriores.
6. **Medio: contrato de documentos contradictorio.** La ejecución completa de Flutter terminó con 147 pruebas aprobadas, una omitida y nueve fallos; estos fallos reflejan discrepancias entre las pruebas y la validación actual de longitudes y caracteres. No se deduce solo de ello cuál política corresponde al producto.
7. **Medio: horarios y apariencia parcialmente verificados.** El código contempla ventanas fijas, flexibles y sin restricción y conserva el cruce de medianoche; hay pruebas unitarias. Falta verificar asignación, persistencia y marcación reales en dispositivo. Aunque una constante define negro, en la pantalla de inicio instalada se observa un fondo azul oscuro y textos de acciones y estado truncados; la barra de navegación cubre parte del mapa. No se auditaron visualmente todas las pantallas.

## Evidencia de esta revisión

- `flutter analyze`: sin incidencias.
- `flutter test --reporter expanded`: 147 aprobadas, una omitida, nueve fallidas. Registro: `flutter_audit_recheck_20261109.log` en la raíz del proyecto.
- Android conectado: OPPO CPH2557, Android 15, app instalada `1.0.0`; la pantalla observada muestra una cuenta de administrador. La versión de paquete no identifica por sí sola el código fuente instalado.
- ARTEMIS pudo observar la pantalla, pero su tarea de exploración no generó un plan tras más de un minuto y fue detenida; no se atribuyen verificaciones adicionales a esa tarea.
- En `C:\Users\emman\Katalon Studio\Buenos dias` existen dos casos y una suite. No se ejecutaron durante esta auditoría porque su diseño actual podría realizar cambios reales sin comprobar los resultados.
- iOS no se compiló ni se probó en esta revisión.

## Secuencia recomendada

Resolver la activación individual y recuperación; hacer seguras las operaciones de alta y asignación entre bases; definir y probar el contrato de documentos; reemplazar las pruebas Katalon por verificaciones reales con esperas, selectores, cinco trabajadores y ambos tipos de horario; compilar e instalar una versión identificable y repetir la prueba integral Android. Verificar después en iOS con Xcode y dispositivo o simulador.
