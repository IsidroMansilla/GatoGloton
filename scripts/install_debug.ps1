[CmdletBinding()]
param(
    [string]$ApkPath = ""
)

$ErrorActionPreference = "Stop"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $ApkPath = Join-Path $projectRoot "build\gato_gloton.apk"
}

if (-not (Test-Path -LiteralPath $adb)) {
    throw "adb no encontrado en $adb"
}
if (-not (Test-Path -LiteralPath $ApkPath)) {
    throw "APK no encontrado: $ApkPath. Ejecuta primero build_debug.ps1."
}

$deviceLines = @(& $adb devices | Where-Object { $_ -match "^\S+\s+device$" })
if ($deviceLines.Count -eq 0) {
    throw "No hay ningun dispositivo Android autorizado. Activa Depuracion USB, conecta el movil y acepta la huella RSA."
}

& $adb install -r $ApkPath
if ($LASTEXITCODE -ne 0) {
    throw "adb install fallo (exit $LASTEXITCODE)."
}

Write-Host "APK instalado correctamente: $ApkPath"
