[CmdletBinding()]
param(
    [string]$GodotExe = "godot"
)

$ErrorActionPreference = "Stop"
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

    Write-Host "Exportando APK de debug..."
    & $GodotExe --headless --path . --export-debug "Android" (Join-Path $buildDir "gato_gloton.apk")
    if ($LASTEXITCODE -ne 0) {
        throw "La exportacion fallo (exit $LASTEXITCODE)."
    }

    Write-Host "OK: $(Join-Path $buildDir 'gato_gloton.apk')"
}
finally {
    Pop-Location
}
