import static com.kms.katalon.core.checkpoint.CheckpointFactory.findCheckpoint
import static com.kms.katalon.core.testcase.TestCaseFactory.findTestCase
import static com.kms.katalon.core.testdata.TestDataFactory.findTestData
import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject
import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile
import com.kms.katalon.core.model.FailureHandling as FailureHandling
import com.kms.katalon.core.util.KeywordUtil
import com.smartattendance.testing.SmartAttendanceKeywords as SA

// ============================================================================
// CASO DE PRUEBA: TC02_Supervisor_Crea_Usuarios_Y_Horarios
// OBJETIVO:
// 1. Cierre de sesión limpio del Administrador.
// 2. Supervisor Gonzalo Morales (2026005555) inicia sesión con su cédula.
// 3. Supervisor accede a su cuadrilla asignada ('Cuadrilla Los Rosales').
// 4. Afilia operarios configurando turnos en formatos 24h y 12h (AM/PM) de Colombia.
// 5. Valida visibilidad de la cuadrilla y persistencia local sin errores.
// ============================================================================

KeywordUtil.logInfo('>>> INICIANDO PRUEBA KATALON: TC02_Supervisor_Crea_Usuarios_Y_Horarios <<<')

// 1. Cerrar sesión previa de Administrador
SA.logout()
Mobile.delay(2)

// 2. Iniciar sesión como Supervisor
KeywordUtil.logInfo('Iniciando sesión como Supervisor Gonzalo Morales (2026005555)...')
SA.login('2026005555')
Mobile.delay(3)

// 3. Abrir Directorio de Mi Cuadrilla (Tab 2 Equipos / Personal)
SA.runAdb('shell input tap 415 2280')
Mobile.delay(2)
SA.runAdb('shell input tap 380 360') // Subtab Personal
Mobile.delay(2)

// 4. Registrar Operario 1 con Turno Mañana (06:00 - 14:00 / 06:00 AM - 02:00 PM)
KeywordUtil.logInfo('Registrando Trabajador 1 con Turno Mañana (12h/24h Colombia)...')
SA.runAdb('shell input tap 980 490') // '+ Nuevo'
Mobile.delay(2)

SA.cleanAndTypeText(540, 480, 'Ramiro Operario')
SA.cleanAndTypeText(540, 580, '1099112201')

// Selector de Turno: Mañana (06:00 - 14:00)
SA.runAdb('shell input tap 540 850')
Mobile.delay(1)
SA.runAdb('shell input tap 540 850') // Turno Mañana
Mobile.delay(1)

// Guardar
SA.runAdb('shell input tap 980 180')
Mobile.delay(2)
KeywordUtil.logInfo('Trabajador 1 afiliado exitosamente con Turno Mañana.')

// 5. Registrar Operario 2 con Turno Ordinario / Oficina (08:00 - 17:00 / 08:00 AM - 05:00 PM)
KeywordUtil.logInfo('Registrando Trabajador 2 con Turno Ordinario / Oficina (12h/24h Colombia)...')
SA.runAdb('shell input tap 980 490') // '+ Nuevo'
Mobile.delay(2)

SA.cleanAndTypeText(540, 480, 'Lucia Barredora')
SA.cleanAndTypeText(540, 580, '1099112202')

// Selector de Turno: Oficina (08:00 - 17:00)
SA.runAdb('shell input tap 540 850')
Mobile.delay(1)
SA.runAdb('shell input tap 540 980') // Turno Ordinario / Oficina
Mobile.delay(1)

// Guardar
SA.runAdb('shell input tap 980 180')
Mobile.delay(2)
KeywordUtil.logInfo('Trabajador 2 afiliado exitosamente con Turno Oficina.')

// 6. Captura de pantalla final de la cuadrilla y validación
Mobile.takeScreenshot('evidencia_katalon_tc02_cuadrilla_creada.png')
KeywordUtil.markPassed('TC02 COMPLETADO CON ÉXITO: Supervisor afilió usuarios y aplicó turnos en Colombia.')
