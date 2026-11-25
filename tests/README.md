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

`save_test_runner.gd` valida la persistencia de `SaveManager`:

- Archivo ausente, corrupto y de version futura.
- Migraciones v1, v2 y save sin version hasta v3.
- Round trip de record, estadisticas, logros, desbloqueos, cosmeticos y config personalizada.
- Saneado de tipos invalidos y escritura fallida.
- Aislamiento de las partidas personalizadas respecto a estadisticas y progreso.

Resultado de referencia actual: `97 passed, 0 failed`.

`progression_test_runner.gd` valida logros y desbloqueos:

- Integridad y cobertura del catalogo de logros.
- Calculo de progreso por estadistica y record.
- Integridad del catalogo de cosmeticos y sus paletas.
- Reglas de desbloqueo por nivel, partidas, logros y niveles completados.
- API publica de `AchievementManager` y `UnlockManager`.

Resultado de referencia actual: `45 passed, 0 failed`.

En PowerShell, usa `Start-Process` para obtener correctamente el codigo de salida con el ejecutable de Godot instalado en este proyecto. El runner de guardado necesita `--quit-after` para cerrar el proceso de forma fiable tras escribir en disco:

```powershell
$godot = "C:\ruta\Godot_v4.7.2-stable_mono_win64.exe"
$scripts = @(
    "res://tests/test_runner.gd",
    "res://tests/save_test_runner.gd",
    "res://tests/progression_test_runner.gd"
)
foreach ($script in $scripts) {
    $process = Start-Process -FilePath $godot -ArgumentList @(
        "--headless", "--quit-after", "30", "--path", ".", "--script", $script
    ) -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) { throw "Tests fallidos: $script" }
}
```
