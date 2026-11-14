package com.smartattendance.testing

import com.kms.katalon.core.annotation.Keyword
import com.kms.katalon.core.configuration.RunConfiguration
import com.kms.katalon.core.util.KeywordUtil
import com.google.gson.JsonParser
import java.util.concurrent.TimeUnit

// Keywords propias: comandos estructurados, evidencia por caso y fallos explícitos.
// Requiere una instalación/licencia válida para ejecutarse desde Katalon.
class AndroidAutomation {
    @Keyword
    static void detectarAndroid() { ejecutar('preflight') }

    @Keyword
    static void comprobarPantalla() { ejecutar('smoke') }

    @Keyword
    static void probarAdministrador() { ejecutar('admin') }

    @Keyword
    static void probarSupervisor() { ejecutar('supervisor') }

    @Keyword
    static void probarEdicion() { ejecutar('edit') }

    @Keyword
    static void ejecutar(String stage) {
        if (!(stage in ['preflight','smoke','admin','supervisor','edit'])) {
            KeywordUtil.markFailedAndStop('Etapa desconocida')
        }
        Properties settings = new Properties()
        File config = new File(RunConfiguration.getProjectDir(), 'automation.properties')
        if (config.isFile()) config.withInputStream { settings.load(it) }
        String root = System.getenv('SA_PROJECT_ROOT') ?: settings.getProperty('projectRoot')
        if (!root) KeywordUtil.markFailedAndStop('Falta la ruta projectRoot en automation.properties')
        String python = System.getenv('SA_PYTHON') ?: settings.getProperty('python', 'python')
        File runner = new File(root, 'qa/mobile/run.py')
        if (!runner.isFile()) KeywordUtil.markFailedAndStop('No se encontró el motor de pruebas')
        if (stage == 'admin' && (!System.getenv('SA_ADMIN_DOCUMENT') || !System.getenv('SA_ADMIN_PASSWORD'))) {
            KeywordUtil.markFailedAndStop('Configura las credenciales localmente antes de ejecutar altas')
        }
        String local = System.getenv('LOCALAPPDATA') ?: System.getProperty('user.home')
        File evidence = new File(local, 'SmartAttendanceQA/katalon_'+UUID.randomUUID())
        if (!evidence.mkdirs()) KeywordUtil.markFailedAndStop('No se pudo crear la carpeta de evidencias')
        File log = new File(evidence, 'execution.log')
        ProcessBuilder builder = new ProcessBuilder(python, '-X', 'utf8',
            runner.absolutePath, '--stage', stage).directory(new File(root))
            .redirectErrorStream(true).redirectOutput(log)
        builder.environment().put('SA_REPORT_DIR', evidence.absolutePath)
        Process process = builder.start()
        if (!process.waitFor(20, TimeUnit.MINUTES)) {
            process.destroyForcibly()
            KeywordUtil.markFailedAndStop('Tiempo agotado; evidencia: '+evidence)
        }
        KeywordUtil.logInfo('Evidencia de '+stage+': '+evidence)
        // No se imprimen cuerpos de peticiones, contraseñas ni tokens.
        if (process.exitValue() != 0) {
            KeywordUtil.markFailedAndStop('Falló '+stage+'; revisa execution.log en la evidencia')
        }
        List<File> reports = []
        evidence.eachFileRecurse { file ->
            if (file.isFile() && file.name.startsWith('result') && file.name.endsWith('.json')) reports.add(file)
        }
        if (reports.size() != 1) KeywordUtil.markFailedAndStop('No existe un informe único verificable')
        boolean passed = false
        reports.first().withReader('UTF-8') { reader ->
            def result = JsonParser.parseReader(reader).getAsJsonObject()
            passed = result.has('passed') && result.get('passed').isJsonPrimitive() &&
                result.get('passed').getAsJsonPrimitive().isBoolean() && result.get('passed').getAsBoolean()
        }
        if (!passed) KeywordUtil.markFailedAndStop('El informe no acredita una prueba aprobada')
        KeywordUtil.markPassed('Aprobado con evidencia: '+stage)
    }
}
