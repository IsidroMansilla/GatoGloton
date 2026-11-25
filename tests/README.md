# Pruebas headless

`test_runner.gd` valida los 30 niveles sin depender de controles, Android ni de la IA de los rivales.

Comprueba:

- Configuracion y limites de cada nivel.
- Crecimiento de dimensiones.
- Conectividad del mapa.
- Ruta valida de cobertura desde el spawn del jugador.
- Recogida de todos los pellets.
- Spawns seguros para la cantidad de rivales del nivel.

Resultado de referencia actual: `380 passed, 0 failed`.

Estas pruebas validan la completabilidad estructural de los mapas sin rivales;
el balance de la IA se valida aparte en Android real.

En PowerShell, usa `Start-Process` para obtener correctamente el codigo de salida con el ejecutable de Godot instalado en este proyecto:

```powershell
$godot = "C:\ruta\Godot_v4.7.2-stable_mono_win64.exe"
$process = Start-Process -FilePath $godot -ArgumentList @(
    "--headless", "--path", ".", "--script", "res://tests/test_runner.gd"
) -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) { throw "Tests fallidos" }
```
