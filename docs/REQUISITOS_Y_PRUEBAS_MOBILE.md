# Requisitos y pruebas de SmartAttendance

Estado de revisión: 9 de noviembre de 2026. Este documento describe requisitos y evidencias observadas; no certifica cumplimiento ni reemplaza la validación laboral o jurídica colombiana.

La revisión posterior de seguridad y sus correcciones están en [Auditoría de preparación para producción](AUDITORIA_SEGURIDAD_PRODUCCION_2026-11-09.md). El apartado «Estado y límites conocidos» de este documento conserva la instantánea inicial de la sesión; prevalece el informe posterior cuando difieran.

## Flujo objetivo

1. Una cuenta administrativa autenticada crea el supervisor y le asigna un equipo.
2. El supervisor activa su cuenta con credenciales propias y accede a su equipo.
3. El supervisor registra colaboradores y asigna su sitio de trabajo y horario autorizado.
4. El trabajador marca asistencia, sujeto a permisos, ubicación y configuración del horario.
5. El administrador consulta y exporta los registros, con trazabilidad y sin sobrescribir datos existentes.

## Requisitos funcionales

| ID | Requisito | Criterio de aceptación |
|---|---|---|
| RF-01 | Autenticación y activación | El usuario registrado inicia con credenciales propias; una cuenta sin credencial no accede. La recuperación exige identidad y entrega real del código. |
| RF-02 | Supervisores y equipos | Solo un administrador autorizado crea mandos y asigna cada supervisor a su equipo. |
| RF-03 | Personal | El supervisor registra cinco colaboradores diferentes dentro de su equipo; se rechaza una cédula duplicada y la creación de mandos. |
| RF-04 | Sitio | La ubicación y el radio se guardan explícitamente y se muestran al asignado; no se inventan coordenadas. |
| RF-05 | Horario fijo | La asignación conserva jornada y ventana fija; la marcación fuera de la ventana configurada se rechaza. |
| RF-06 | Ventana flexible | La asignación conserva los límites flexibles elegidos; sin límite configurado no se muestra una restricción ficticia. |
| RF-07 | Persistencia | Equipo, personas, sitio y horarios permanecen tras navegar y reabrir la app; una falla no deja cuentas incompletas. |
| RF-08 | Aislamiento | El supervisor no puede consultar ni modificar personal de otro equipo. |

## Requisitos no funcionales

| ID | Requisito | Verificación |
|---|---|---|
| RNF-01 | Seguridad | Autenticación real, permisos comprobados en el servidor y en cada operación local; sin privilegios por identificación fija. |
| RNF-02 | Privacidad | No registrar contraseñas ni datos personales en trazas; usar datos QA autorizados. |
| RNF-03 | Disponibilidad | Mostrar claramente errores de red y estado offline; no presentar una operación pendiente como sincronizada. |
| RNF-04 | Interfaz | Fondo negro en modo oscuro, texto contrastado, iconos neutros y legibles; sin recortes en vertical ni horizontal. |
| RNF-05 | Plataforma | Compilar y probar Android e iOS; iOS requiere Mac, Xcode y firma configurada. |
| RNF-06 | Fechas y reglas | Usar hora de Colombia y validar casos nocturnos y medianoche; reglas legales de jornada y recargos deben aprobarse con normativa vigente y asesoría laboral. |

## Estado y límites conocidos

- En el Android conectado se accedió a la pantalla de administrador con una credencial presente en un guion anterior. Se observó el formulario de registro y su opción «Supervisor»; no se ha creado ni autenticado un supervisor nuevo en esta revisión.
- La versión instalada debe considerarse vulnerable: el código anterior de autenticación aceptaba cualquier contraseña para algunas credenciales guardadas. Se corrigió en el código fuente y se verificó con pruebas, pero aún no se ha instalado la corrección. El alta local asigna una contraseña predeterminada compartida; falta un mecanismo seguro y comprobado de activación y recuperación antes de desplegar.
- El registro local y la cuenta remota son rutas distintas. No se ha demostrado activación del supervisor ni consistencia atómica entre bases.
- El formulario de personal puede modificar la zona de una cuadrilla existente antes de completar el alta. Debe evitarse usarlo con datos reales hasta verificar y corregir esa secuencia.
- Una plantilla puede establecer ventana de marcación, pero el formulario de personal también construye otra desde tolerancias; hay que validar que ambos recorridos conserven la intención seleccionada. En el código se corrigió el cálculo de tolerancia al cruzar medianoche y se conservaron los límites nocturnos de la plantilla; está cubierto por pruebas de unidad y pendiente de prueba en dispositivo.
- La vista de inicio mostraba un horario inventado si faltaba asignación; el código actual muestra «Sin horario asignado». La corrección está cubierta por prueba de widget, pendiente de instalar y verificar en dispositivo.
- La presentación de una ventana sin límites se corrigió para mostrar «Sin restricción horaria»; las pruebas de unidad cubren los límites fijos y el cruce de medianoche.
- Los informes históricos de `docs/` son instantáneas con afirmaciones que pueden estar desactualizadas; contrastar su fecha y evidencia antes de usarlos como estado actual.
- Tras corregir el fallo de credenciales, la batería completa de Flutter registró 144 pruebas aprobadas, una omitida y nueve fallos relacionados con expectativas de validación de documento. La política actual permite letras y longitudes distintas de las pruebas históricas; debe revisarse el contrato antes de modificarlo.

## Ejecución prevista en Katalon

Usar un entorno de prueba y cuentas autorizadas, un dispositivo desbloqueado y sin cerrar la sesión administrativa hasta verificar la recuperación. Mantener registros QA identificables; no modificar ni borrar datos ajenos. Cada caso debe comprobar cambios persistidos, acceso denegado a otro equipo y errores de red, y conservar capturas. Las credenciales se proporcionan de forma segura fuera del código y del informe.

Los casos de creación y acceso solo pueden declararse aprobados después de ejecutarlos realmente en el dispositivo. Katalon puede esperar elementos y localizarlos de forma dinámica; las coordenadas son un último recurso limitado al dispositivo verificado. Véanse las referencias oficiales de [espera de elementos](https://docs.katalon.com/katalon-studio/keywords/keyword-description-in-katalon-studio/mobile-keywords/mobile-wait-for-element-present) y [localización de elementos](https://docs.katalon.com/katalon-studio/keywords/keyword-description-in-katalon-studio/mobile-keywords/mobile-find-elements).
