# Pruebas Android automáticas

## Keywords disponibles

La biblioteca `com.smartattendance.testing.AndroidAutomation` ofrece `detectarAndroid()`, `comprobarPantalla()`, `probarAdministrador()`, `probarSupervisor()` y `probarEdicion()`. Los casos instalados llaman los métodos correspondientes. `ejecutar(etapa)` conserva la API genérica para reutilización.

Cada keyword crea una carpeta de evidencia exclusiva y comprueba dos condiciones: proceso terminado correctamente e informe JSON con `passed` booleano verdadero. Los cuerpos y credenciales no se imprimen en el log de Katalon. Los GUID de casos y suites son estables al reinstalar. El motor bloquea una segunda ejecución propia sobre el mismo Android hasta que termine la primera; otras herramientas, como ARTEMIS, deben coordinarse por separado.

El código Groovy se compiló contra las bibliotecas de Katalon 11.7 instaladas. Esto valida compilación, no reemplaza la ejecución licenciada de Katalon Runtime Engine.

1. Conecta el Android desbloqueado por USB y acepta la depuración.
2. Abre **Probar Android.cmd** desde la raíz del proyecto. Detecta el dispositivo autorizado, comprueba la instalación y ejecuta navegación sin crear datos.
3. Para usar Katalon Studio abre `Buenos dias.prj` y ejecuta **Test Suites/TS_Android_Automatico**. Los casos nuevos están en **Test Cases/Android Automatico**.

La suite **TS_Android_Administrativo** crea registros persistentes de prueba: equipo, supervisor y cinco trabajadores. Necesita `SA_ADMIN_DOCUMENT` y `SA_ADMIN_PASSWORD` configurados localmente; no se incluyen contraseñas predeterminadas. No elimina registros existentes. Requiere disponer del teléfono en exclusiva durante la ejecución.

## Ejecución por consola

Desde PowerShell en la raíz del proyecto:

```powershell
./qa/katalon/Iniciar-Pruebas-Android.ps1 -Modo Smoke
./qa/katalon/Iniciar-Pruebas-Android.ps1 -Modo Katalon
./qa/katalon/Iniciar-Pruebas-Android.ps1 -Modo Administrativo
```

Katalon por consola requiere una licencia activa de Runtime Engine. El instalador no compra licencias ni almacena claves de activación. El modo Smoke ejecuta el mismo motor de navegación directamente y comunica su resultado como motor directo, sin atribuirlo a Katalon.

Si hay varios teléfonos no se elige uno al azar: configura `SA_DEVICE_SERIAL`. Las rutas ADB se detectan desde PATH o Android SDK; `SA_ADB_PATH` permite seleccionar una instalación específica. La configuración de rutas de Katalon queda en `automation.properties`, sin credenciales.

## Evidencias y alcance

El diagnóstico y la navegación escriben `result.json`, `junit.xml` y capturas en `%LOCALAPPDATA%/SmartAttendanceQA/automation_*`. Cada fallo devuelve un código distinto de cero. La falta de un dispositivo o una app instalada no se reporta como éxito.

ARTEMIS se usa para diagnosticar y explorar la interfaz; ADB y UIAutomator2 ejecutan las interacciones con selectores y esperas. No se ejecutan simultáneamente sobre el mismo teléfono. El motor administrativo existente conserva sus verificaciones de SQLite y sus propios informes; su aprobación requiere ejecutar todos sus pasos.

En la verificación del 10 de noviembre se comprobó detección automática de un OPPO CPH2557. El intento Katalon 11.7 por consola devolvió código 2 por falta de licencia Runtime Engine; no se declara una suite Katalon aprobada sin ejecución.
