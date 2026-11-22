[CmdletBinding()]
param(
    [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) "upload.keystore"),
    [string]$Alias = "upload",
    [string]$DistinguishedName = "CN=Gato Gloton, OU=Games, O=Isidro, C=ES"
)

$ErrorActionPreference = "Stop"

if (Test-Path -LiteralPath $Path) {
    throw "Ya existe un keystore en $Path. No lo sobrescribas: guardalo y reutilizalo."
}

$secure = Read-Host -Prompt "Contrasena del keystore (solo letras y numeros)" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

try {
    & keytool -genkeypair -v `
        -keystore $Path `
        -alias $Alias `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -storepass $plain `
        -keypass $plain `
        -dname $DistinguishedName
    if ($LASTEXITCODE -ne 0) {
        throw "keytool fallo (exit $LASTEXITCODE)."
    }

    Write-Host ""
    Write-Host "Keystore: $Path"
    Write-Host "Alias:    $Alias"
    Write-Host "Guarda el archivo y la contrasena FUERA del repo. No los subas a git."
    Write-Host "Configura las variables GODOT_ANDROID_KEYSTORE_RELEASE_* para build_release.ps1."
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    $plain = $null
}
