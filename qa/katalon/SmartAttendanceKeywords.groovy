package com.smartattendance.testing

import com.kms.katalon.core.annotation.Keyword
import com.kms.katalon.core.util.KeywordUtil
import java.util.concurrent.TimeUnit

// QUÉ HACE: Ejecuta el mismo motor real que se verifica en el teléfono.
// CÓMO: UIAutomator usa etiquetas y esperas; SQLite se consulta solo en lectura.
// POR QUÉ: Katalon falla ante errores y nunca declara éxitos sin aserciones.
class SmartAttendanceKeywords {
    @Keyword
    static void runStage(String stage) {
        if (!(stage in ['admin', 'supervisor'])) {
            KeywordUtil.markFailedAndStop('Etapa desconocida')
        }
        String root = System.getenv('SA_PROJECT_ROOT') ?:
            'C:/Users/emman/Desktop/Proyectos/PROYECTO QR'
        File runner = new File(root, 'qa/mobile/run.py')
        if (!runner.isFile()) {
            KeywordUtil.markFailedAndStop('Configura SA_PROJECT_ROOT con la carpeta del proyecto')
        }
        String python = System.getenv('SA_PYTHON') ?: 'python'
        File log = File.createTempFile('attendance-qa-', '.log')
        def process = new ProcessBuilder(python, '-X', 'utf8',
            runner.absolutePath, '--stage', stage).directory(new File(root))
            .redirectErrorStream(true).redirectOutput(log).start()
        if (!process.waitFor(20, TimeUnit.MINUTES)) {
            process.destroyForcibly()
            KeywordUtil.markFailedAndStop('La prueba excedió 20 minutos; log: ' + log)
        }
        KeywordUtil.logInfo(log.getText('UTF-8'))
        if (process.exitValue() != 0) {
            KeywordUtil.markFailedAndStop('Falló la verificación real de ' + stage)
        }
        KeywordUtil.markPassed('Verificación real aprobada: ' + stage)
    }
}
