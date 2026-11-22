[CmdletBinding()]
param(
    [string]$GodotExe = "godot",
    [string]$KeystorePath = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH,
    [string]$KeystoreUser = $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER,
    [string]$KeystorePassword = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
)

$ErrorActionPreference = "Stop"

if (-not $KeystorePath -or -not $KeystoreUser -or -not $KeystorePassword) {
    throw "Define GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER y _PASSWORD antes de exportar."
}
if (-not (Test-Path -LiteralPath $KeystorePath)) {
    throw "No existe el keystore: $KeystorePath"
}

$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $KeystorePath
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $KeystoreUser
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $KeystorePassword

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectRoot "build"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

Push-Location $projectRoot
try {
    Write-Host "Importando recursos..."
    & $GodotExe --headless --path . --import
    if ($LASTEXITCODE -ne 0) {
        throw "La importacion fallo (exit $LASTEXITCODE)."
    }

    Write-Host "Exportando AAB de release..."
    & $GodotExe --headless --path . --export-release "Google Play" (Join-Path $buildDir "gato_gloton.aab")
    if ($LASTEXITCODE -ne 0) {
        throw "La exportacion fallo (exit $LASTEXITCODE)."
    }

    Write-Host "OK: $(Join-Path $buildDir 'gato_gloton.aab')"
}
finally {
    Pop-Location
}
