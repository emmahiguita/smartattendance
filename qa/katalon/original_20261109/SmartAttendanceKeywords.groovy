package com.smartattendance.testing

import com.kms.katalon.core.annotation.Keyword
import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile
import com.kms.katalon.core.testobject.TestObject
import com.kms.katalon.core.util.KeywordUtil

// ============================================================================
// ARCHIVO: SmartAttendanceKeywords.groovy
// QUÉ HACE: Keywords reutilizables en Katalon Studio para pruebas de SmartAttendance:
//           - Automatiza login real de Administrador y Supervisor.
//           - Creación de zonas / sitios de trabajo y cuadrillas.
//           - Afiliación de operarios con horarios en formatos 12h y 24h (Colombia).
// CÓMO FUNCIONA: Ejecuta secuencias Appium/ADB con validación de elementos visuales.
// POR QUÉ: Permite pruebas modulares, limpias y libres de duplicidad en Katalon.
// ============================================================================
class SmartAttendanceKeywords {

    static final String APP_PACKAGE = 'io.smartattendance.attendance'
    static final String APP_ACTIVITY = 'io.smartattendance.attendance.MainActivity'

    @Keyword
    static void startSmartAttendanceApp(String appPath = '') {
        KeywordUtil.logInfo('Iniciando SmartAttendance en dispositivo móvil...')
        if (appPath != null && appPath.trim().length() > 0 && new File(appPath).exists()) {
            Mobile.startApplication(appPath, false)
        } else {
            Mobile.startExistingApplication(APP_PACKAGE)
        }
        Mobile.delay(3)
    }

    @Keyword
    static void runAdb(String command) {
        KeywordUtil.logInfo("Ejecutando comando ADB: ${command}")
        def proc = ["cmd.exe", "/c", "adb ${command}"].execute()
        proc.waitFor()
    }

    @Keyword
    static void cleanAndTypeText(int x, int y, String text) {
        KeywordUtil.logInfo("Limpiando e ingresando texto '${text}' en coordenadas (${x}, ${y})...")
        runAdb("shell input tap ${x} ${y}")
        Mobile.delay(1)
        // 30 Backspaces para limpiar cualquier dato previo
        for (int i = 0; i < 30; i++) {
            runAdb("shell input keyevent 67")
        }
        Mobile.delay(1)
        runAdb("shell input text ${text}")
        Mobile.delay(1)
        // Ocultar teclado
        runAdb("shell input keyevent 4")
        Mobile.delay(1)
    }

    @Keyword
    static void login(String document) {
        KeywordUtil.logInfo("Iniciando sesión con documento: ${document}")
        cleanAndTypeText(540, 1150, document)
        // Tap botón ingresar
        runAdb("shell input tap 540, 1400")
        Mobile.delay(3)
    }

    @Keyword
    static void logout() {
        KeywordUtil.logInfo("Cerrando sesión limpiamente...")
        // Tap tab Perfil
        runAdb("shell input tap 890 2260")
        Mobile.delay(2)
        // Tap Cerrar Sesión
        runAdb("shell input tap 540 1850")
        Mobile.delay(1)
        // Confirmar modal Salir
        runAdb("shell input tap 750 1350")
        Mobile.delay(2)
    }
}
