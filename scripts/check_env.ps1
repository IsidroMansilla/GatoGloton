[CmdletBinding()]
param(
    [string]$GodotExe = "godot"
)

$ErrorActionPreference = "Continue"
Write-Host "== Gato Gloton / comprobacion de entorno =="

$godot = Get-Command $GodotExe -ErrorAction SilentlyContinue
if ($godot) {
    Write-Host "Godot: $($godot.Source)"
    & $GodotExe --version
}
else {
    Write-Warning "Godot no encontrado. Instala Godot 4.7.2-stable y pasa -GodotExe con la ruta completa."
}

$java = Get-Command java -ErrorAction SilentlyContinue
if ($java) {
    Write-Host "Java: $($java.Source)"
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $javaVersion = (& java -version 2>&1) | Out-String
    $ErrorActionPreference = $previousEap
    Write-Host ($javaVersion.Trim())
    Write-Warning "Godot/AGP 8.x recomienda JDK 17. Si ves JDK 11, instala JDK 17."
}
else {
    Write-Warning "Java no encontrado. Instala JDK 17."
}

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Warning "keytool no encontrado (viene con el JDK)."
}

$sdk = $env:ANDROID_HOME
if (-not $sdk) {
    $sdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}

if (Test-Path -LiteralPath $sdk) {
    Write-Host "Android SDK: $sdk"
    $required = @(
        "platform-tools\adb.exe",
        "platforms\android-36",
        "build-tools",
        "cmdline-tools"
    )
    foreach ($item in $required) {
        $candidate = Join-Path $sdk $item
        if (Test-Path -LiteralPath $candidate) {
            Write-Host "  OK    $item"
        }
        else {
            Write-Warning "  FALTA $item"
        }
    }
}
else {
    Write-Warning "Android SDK no encontrado en $sdk."
}

Write-Host ""
Write-Host "Siguiente paso: instalar export templates y ejecutar scripts\build_debug.ps1."
