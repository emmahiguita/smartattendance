param([ValidateSet('Smoke','Katalon','Administrativo')][string]$Modo='Smoke')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$python=(Get-Command python -ErrorAction Stop).Source
Set-Location -LiteralPath $projectRoot
& $python -X utf8 qa/mobile/run.py --stage preflight
if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
if($Modo -eq 'Smoke'){
    & $python -X utf8 qa/mobile/run.py --stage smoke
    exit $LASTEXITCODE
}
& $python -X utf8 qa/katalon/install_project.py
if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
$packages=Join-Path $env:USERPROFILE '.katalon\packages'
$runtime=Get-ChildItem -LiteralPath $packages -Directory |
    Where-Object {Test-Path -LiteralPath (Join-Path $_.FullName 'katalonc.exe')} |
    Sort-Object Name -Descending | Select-Object -First 1
if(-not $runtime){throw 'No se encontró Katalon Studio/Runtime Engine instalado.'}
$qaProject=if($env:SA_KATALON_PROJECT){$env:SA_KATALON_PROJECT}else{Join-Path $env:USERPROFILE 'Katalon Studio\Buenos dias'}
$projectFile=Get-ChildItem -LiteralPath $qaProject -Filter '*.prj' | Select-Object -First 1
$suite=if($Modo -eq 'Administrativo'){'TS_Android_Administrativo'}else{'TS_Android_Automatico'}
if($Modo -eq 'Administrativo' -and (-not $env:SA_ADMIN_DOCUMENT -or -not $env:SA_ADMIN_PASSWORD)){
    throw 'Configura SA_ADMIN_DOCUMENT y SA_ADMIN_PASSWORD localmente, sin guardarlas en los scripts.'
}
& (Join-Path $runtime.FullName 'katalonc.exe') -noSplash -runMode=console `
    "-projectPath=$($projectFile.FullName)" -retry=0 "-testSuitePath=Test Suites/$suite" `
    -executionProfile=default -browserType=Android
$result=$LASTEXITCODE
if($result -eq 2){Write-Host 'Katalon requiere activación de Runtime Engine. El motor directo se ejecuta con -Modo Smoke.'}
exit $result
