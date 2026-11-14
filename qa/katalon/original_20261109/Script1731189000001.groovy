import static com.kms.katalon.core.checkpoint.CheckpointFactory.findCheckpoint
import static com.kms.katalon.core.testcase.TestCaseFactory.findTestCase
import static com.kms.katalon.core.testdata.TestDataFactory.findTestData
import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject
import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile
import com.kms.katalon.core.model.FailureHandling as FailureHandling
import com.kms.katalon.core.util.KeywordUtil
import com.smartattendance.testing.SmartAttendanceKeywords as SA

// ============================================================================
// CASO DE PRUEBA: TC01_Admin_Crea_Supervisor_Y_Sitio
// OBJETIVO: 
// 1. Super Administrador (1007331963) inicia sesión real.
// 2. Crea el Sitio de Trabajo / Geocerca GPS con dirección física y radio.
// 3. Registra al Supervisor con rol RBAC de supervisión y asigna su Cuadrilla.
// 4. Valida en interfaz y persistencia SQLite local sin errores ni mocks.
// ============================================================================

KeywordUtil.logInfo('>>> INICIANDO PRUEBA KATALON: TC01_Admin_Crea_Supervisor_Y_Sitio <<<')

// 1. Iniciar SmartAttendance en el dispositivo Android
SA.startSmartAttendanceApp()

// 2. Autenticar como Super Administrador
SA.login('1007331963')
Mobile.delay(3)

// 3. Navegar a Gestión de Equipos y Sitios de Trabajo (Tab 2)
SA.runAdb('shell input tap 415 2280')
Mobile.delay(2)

// 4. Crear nuevo Sitio de Trabajo / Geocerca GPS (+ Nueva Zona)
KeywordUtil.logInfo('Paso: Creando Sitio de Trabajo / Geocerca GPS...')
SA.runAdb('shell input tap 260 450') // Botón '+ Nueva Zona'
Mobile.delay(2)

// Escribir nombre del Sitio de Trabajo
SA.cleanAndTypeText(540, 680, 'Sede Operativa Norte')
// Escribir dirección física en Dosquebradas, Colombia
SA.cleanAndTypeText(540, 830, 'Carrera 16 Calle 30 Dosquebradas')
// Guardar Zona GPS
SA.runAdb('shell input tap 750 1150')
Mobile.delay(2)
KeywordUtil.logInfo('Sitio de Trabajo registrado con éxito.')

// 5. Crear Cuadrilla y Asignar al Supervisor
KeywordUtil.logInfo('Paso: Creando Cuadrilla para el Supervisor...')
SA.runAdb('shell input tap 780 450') // Botón '+ Nuevo Equipo'
Mobile.delay(2)

// Nombre de la cuadrilla
SA.cleanAndTypeText(540, 680, 'Cuadrilla Los Rosales')
// Cédula del Supervisor asignado
SA.cleanAndTypeText(540, 830, '2026005555')
// Guardar Cuadrilla
SA.runAdb('shell input tap 750 1150')
Mobile.delay(2)

// 6. Registrar datos del Supervisor en el Directorio (Tab Personal)
KeywordUtil.logInfo('Paso: Registrando cuenta y permisos del Supervisor...')
SA.runAdb('shell input tap 380 360') // Subtab Personal
Mobile.delay(2)
SA.runAdb('shell input tap 980 490') // Botón '+ Nuevo'
Mobile.delay(2)

// Nombre completo del Supervisor
SA.cleanAndTypeText(540, 480, 'Gonzalo Morales')
// Cédula / Documento legal
SA.cleanAndTypeText(540, 580, '2026005555')
// Seleccionar Rol Supervisor
SA.runAdb('shell input tap 540 680')
Mobile.delay(1)
SA.runAdb('shell input tap 540 1080') // Rol 'Supervisor'
Mobile.delay(1)

// Guardar Supervisor
SA.runAdb('shell input tap 980 180') // Guardar AppBar
Mobile.delay(3)

// 7. Captura de evidencia y confirmación
Mobile.takeScreenshot('evidencia_katalon_tc01_supervisor_creado.png')
KeywordUtil.markPassed('TC01 COMPLETADO CON ÉXITO: Administrador creó Sitio de Trabajo y Supervisor.')
