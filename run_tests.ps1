# run_tests.ps1
# ===================================================================
# Automated Test Suite Runner — SmartAttendance App
# ===================================================================
# Ejecuta todas las pruebas (backend + Flutter unit/widget/integration)
# y genera un reporte consolidado.
#
# Uso:
#   .\run_tests.ps1                    # Todas las pruebas
#   .\run_tests.ps1 -FlutterOnly       # Solo Flutter (unit + widget)
#   .\run_tests.ps1 -BackendOnly       # Solo backend
#   .\run_tests.ps1 -Integration       # Solo integration (requiere backend corriendo)
#   .\run_tests.ps1 -SkipBackend       # Flutter + integration, sin ejecutar backend
#
# Salida: test_results.json y test_results.txt en el directorio actual.
# Exit code: 0 = todo OK, 1 = fallos encontrados.
# ===================================================================
param(
    [switch]$FlutterOnly,
    [switch]$BackendOnly,
    [switch]$Integration,
    [switch]$SkipBackend,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$projectRoot = $PSScriptRoot
$flutterApp = Join-Path $projectRoot 'smartattendance_app'
$backendDir = Join-Path $projectRoot 'smartattendance_backend'
$resultsFile = Join-Path $projectRoot 'test_results.json'
$resultsText = Join-Path $projectRoot 'test_results.txt'

# -- Colores --------------------------------------------------------
function Write-Status {
    param([string]$Text, [string]$Color = 'White')
    Write-Host $Text -ForegroundColor $Color
}

function Write-Pass { Write-Status "  PASS  $args" 'Green' }
function Write-Fail { Write-Status "  FAIL  $args" 'Red' }
function Write-Warn { Write-Status "  WARN  $args" 'Yellow' }
function Write-Step { Write-Status "`n==== $args ====" 'Cyan' }

# -- Resultados ------------------------------------------------------
$script:results = @{
    total_tests  = 0
    passed       = 0
    failed       = 0
    backend      = @{ status = 'skipped'; tests = 0; passed = 0; failed = 0 }
    flutter_unit = @{ status = 'skipped'; tests = 0; passed = 0; failed = 0 }
    flutter_widget = @{ status = 'skipped'; tests = 0; passed = 0; failed = 0 }
    flutter_integration = @{ status = 'skipped'; tests = 0; passed = 0; failed = 0 }
}

function Save-Results {
    $json = $script:results | ConvertTo-Json -Depth 3
    Set-Content -LiteralPath $resultsFile -Value $json -Encoding UTF8
    Set-Content -LiteralPath $resultsText -Value "SmartAttendance Test Results — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$('-' * 60)`n$($script:results | ConvertTo-Json -Depth 3)" -Encoding UTF8

    Write-Step "RESUMEN FINAL"
    Write-Status "Total:   $($script:results.total_tests)" 'White'
    Write-Status "Pasados: $($script:results.passed)" 'Green'
    Write-Status "Fallidos: $($script:results.failed)" $(if ($script:results.failed -gt 0) { 'Red' } else { 'Green' })
    Write-Status "`nReporte guardado en: $resultsFile`nReporte texto: $resultsText" 'Gray'

    if ($script:results.failed -gt 0) { exit 1 } else { exit 0 }
}

# -- Verificación de prerequisitos -----------------------------------
function Test-Prerequisites {
    Write-Step "VERIFICANDO PREREQUISITOS"
    $ok = $true

    # Flutter
    try {
        $flutter = Get-Command flutter -ErrorAction Stop
        $ver = & flutter --version 2>&1 | Select-Object -First 1
        Write-Pass "Flutter: $ver"
    } catch {
        Write-Fail "Flutter no encontrado. Instálalo: https://flutter.dev"
        $ok = $false
    }

    # Python
    try {
        $py = Get-Command python -ErrorAction Stop
        $ver = & python --version 2>&1
        Write-Pass "Python: $ver"
    } catch {
        Write-Fail "Python no encontrado."
        $ok = $false
    }

    # pip
    try {
        $pip = Get-Command pip -ErrorAction Stop
        Write-Pass "pip disponible"
    } catch {
        Write-Fail "pip no encontrado."
        $ok = $false
    }

    if (-not $ok) {
        Write-Status "`nPrerequisitos incumplidos. Corrige antes de ejecutar." 'Red'
        exit 1
    }
}

# -- Backend Tests ---------------------------------------------------
function Invoke-BackendTests {
    Write-Step "BACKEND TESTS (FastAPI)"
    try {
        Push-Location -LiteralPath $backendDir

        # Instalar dependencias si el venv no existe
        if (-not (Test-Path -LiteralPath 'venv\Scripts\python.exe')) {
            Write-Warn "Virtualenv no encontrado. Creando..."
            python -m venv venv
            & .\venv\Scripts\python.exe -m pip install -r requirements.txt --quiet
        }

        # Ejecutar pytest
        $output = & .\venv\Scripts\python.exe -m pytest tests/ -v --tb=short 2>&1
        $exitCode = $LASTEXITCODE

        Pop-Location

        # Parsear resultados
        $passedMatch = [regex]::Match($output -join "`n", '(\d+) passed')
        $failedMatch = [regex]::Match($output -join "`n", '(\d+) failed')
        $passed = if ($passedMatch.Success) { [int]$passedMatch.Groups[1].Value } else { 0 }
        $failed = if ($failedMatch.Success) { [int]$failedMatch.Groups[1].Value } else { 0 }

        $script:results.backend = @{
            status = if ($failed -eq 0 -and $exitCode -eq 0) { 'passed' } else { 'failed' }
            tests  = $passed + $failed
            passed = $passed
            failed = $failed
            exit_code = $exitCode
        }

        $script:results.total_tests += ($passed + $failed)
        $script:results.passed += $passed
        $script:results.failed += $failed

        if ($VerboseOutput -or $failed -gt 0) {
            Write-Status ($output -join "`n") 'Gray'
        }

        if ($failed -eq 0) {
            Write-Pass "Backend: $passed tests pasados, 0 fallidos"
        } else {
            Write-Fail "Backend: $passed pasados, $failed fallidos"
        }
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        Write-Fail "Error ejecutando backend tests: $_"
        $script:results.backend.status = 'error'
    }
}

# -- Flutter Unit Tests ----------------------------------------------
function Invoke-FlutterUnitTests {
    Write-Step "FLUTTER UNIT TESTS"
    try {
        Push-Location -LiteralPath $flutterApp

        $output = & flutter test test/unit/ test/app_smoke_test.dart --reporter expanded 2>&1
        $exitCode = $LASTEXITCODE

        Pop-Location

        $passedMatch = [regex]::Matches(($output -join "`n"), '\+(\d+)(?::|\s*All)')
        $failedMatch = [regex]::Matches(($output -join "`n"), '\-(\d+)(?::|\s*Some)')
        $totalMatch  = [regex]::Match(($output -join "`n"), '(\d+) tests passed')

        # Extraer del formato de salida de Flutter
        $allMatches = [regex]::Matches(($output -join "`n"), 'All tests passed!')
        if ($allMatches.Count -gt 0 -or ($exitCode -eq 0 -and ($output -join "`n") -notmatch 'Some tests failed')) {
            $testCount = [regex]::Match(($output -join "`n"), '\+(\d+)')
            $passed = if ($testCount.Success) { [int]$testCount.Groups[1].Value } else { 0 }
            $failed = 0
        } else {
            $plusCount = [regex]::Matches(($output -join "`n"), 'All tests passed!').Count
            $plusMatches = [regex]::Matches(($output -join "`n"), '\+(\d+) ~')
            if ($plusMatches.Count -gt 0) {
                $passed = [int]$plusMatches[-1].Groups[1].Value
            } else {
                $passed = 0
            }
            $minusMatches = [regex]::Match(($output -join "`n"), '(\d+) failed')
            $failed = if ($minusMatches.Success) { [int]$minusMatches.Groups[1].Value } else { 0 }
        }

        $script:results.flutter_unit = @{
            status = if ($failed -eq 0) { 'passed' } else { 'failed' }
            tests  = $passed + $failed
            passed = $passed
            failed = $failed
            exit_code = $exitCode
        }

        $script:results.total_tests += ($passed + $failed)
        $script:results.passed += $passed
        $script:results.failed += $failed

        if ($VerboseOutput -or $failed -gt 0) {
            Write-Status ($output -join "`n") 'Gray'
        }

        if ($failed -eq 0) {
            Write-Pass "Flutter unit: $passed tests pasados, 0 fallidos"
        } else {
            Write-Fail "Flutter unit: $passed pasados, $failed fallidos"
        }
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        Write-Fail "Error ejecutando Flutter unit tests: $_"
        $script:results.flutter_unit.status = 'error'
    }
}

# -- Flutter Widget Tests --------------------------------------------
function Invoke-FlutterWidgetTests {
    Write-Step "FLUTTER WIDGET TESTS"
    try {
        Push-Location -LiteralPath $flutterApp

        $output = & flutter test test/widget/ test/widget_test.dart --reporter expanded 2>&1
        $exitCode = $LASTEXITCODE

        Pop-Location

        if ($exitCode -eq 0 -and ($output -join "`n") -notmatch 'Some tests failed') {
            $plusMatch = [regex]::Match(($output -join "`n"), '\+(\d+) ~')
            $passed = if ($plusMatch.Success) { [int]$plusMatch.Groups[1].Value } else { 0 }
            $failed = 0
        } else {
            $passed = 0
            $failedMatch = [regex]::Match(($output -join "`n"), '(\d+) failed')
            $failed = if ($failedMatch.Success) { [int]$failedMatch.Groups[1].Value } else { 1 }
        }

        $script:results.flutter_widget = @{
            status = if ($failed -eq 0) { 'passed' } else { 'failed' }
            tests  = $passed + $failed
            passed = $passed
            failed = $failed
            exit_code = $exitCode
        }

        $script:results.total_tests += ($passed + $failed)
        $script:results.passed += $passed
        $script:results.failed += $failed

        if ($VerboseOutput -or $failed -gt 0) {
            Write-Status ($output -join "`n") 'Gray'
        }

        if ($failed -eq 0) {
            Write-Pass "Flutter widget: $passed tests pasados, 0 fallidos"
        } else {
            Write-Fail "Flutter widget: $passed pasados, $failed fallidos"
        }
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        Write-Fail "Error ejecutando Flutter widget tests: $_"
        $script:results.flutter_widget.status = 'error'
    }
}

# -- Flutter Integration Tests ---------------------------------------
function Invoke-FlutterIntegrationTests {
    Write-Step "FLUTTER INTEGRATION TESTS"
    try {
        Push-Location -LiteralPath $flutterApp

        # Integration tests requieren un device/emulador. Verificar.
        $devices = & flutter devices --machine 2>&1 | ConvertFrom-Json
        $deviceIds = $devices | Where-Object { $_.emulator -or $_.platform -match 'android|ios|windows' } | ForEach-Object { $_.id }

        if (-not $deviceIds) {
            Write-Warn "No se encontraron devices/emuladores. Saltando integration tests."
            Write-Warn "  Para correrlos: inicia un emulador o conecta un dispositivo."
            $script:results.flutter_integration.status = 'skipped_no_device'
            Pop-Location
            return
        }

        # Usar el primer device disponible
        $deviceId = ($deviceIds | Select-Object -First 1).Trim()
        Write-Status "  Device: $deviceId"

        # Integration test de flujo real (requiere backend corriendo en 0.0.0.0:8000)
        $output = & flutter test integration_test/flujo_real_test.dart -d $deviceId 2>&1
        $exitCode = $LASTEXITCODE

        Pop-Location

        if ($exitCode -eq 0) {
            $passed = 1
            $failed = 0
        } else {
            $passed = 0
            $failed = 1
        }

        $script:results.flutter_integration = @{
            status = if ($failed -eq 0) { 'passed' } else { 'failed' }
            tests  = 1
            passed = $passed
            failed = $failed
            exit_code = $exitCode
            device  = $deviceId
        }

        $script:results.total_tests += 1
        $script:results.passed += $passed
        $script:results.failed += $failed

        if ($VerboseOutput -or $failed -gt 0) {
            $tail = ($output -join "`n")[-30..-1] -join "`n"
            Write-Status $tail 'Gray'
        }

        if ($failed -eq 0) {
            Write-Pass "Flutter integration: 1 test pasado"
        } else {
            Write-Fail "Flutter integration: 1 test fallido (revisa que el backend esté en http://localhost:8000)"
        }
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        Write-Fail "Error ejecutando integration tests: $_"
        $script:results.flutter_integration.status = 'error'
    }
}

# -- Main ------------------------------------------------------------
Write-Status "`n==========================================================" 'Cyan'
Write-Status "  SmartAttendance — Suite de Pruebas Automatizada" 'Cyan'
Write-Status "  Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 'Cyan'
Write-Status "==========================================================`n" 'Cyan'

Test-Prerequisites

if ($FlutterOnly) {
    Invoke-FlutterUnitTests
    Invoke-FlutterWidgetTests
} elseif ($BackendOnly) {
    Invoke-BackendTests
} elseif ($Integration) {
    Invoke-FlutterIntegrationTests
} elseif ($SkipBackend) {
    Invoke-FlutterUnitTests
    Invoke-FlutterWidgetTests
    Invoke-FlutterIntegrationTests
} else {
    # Default: all
    Invoke-BackendTests
    Invoke-FlutterUnitTests
    Invoke-FlutterWidgetTests
    Invoke-FlutterIntegrationTests
}

Save-Results
