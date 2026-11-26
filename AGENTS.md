# AGENTS.md — Gato Gloton

Guia operativa del proyecto para agentes de IA (opencode) y para cualquier persona que toque el repo. Leer antes de editar.

## 1. Resumen

Arcade de laberinto 2D para Android, en estilo Pac-Man pero con IP propia: un gato come bolas de pelo y escapa de perros rivales. Monetizacion con AdMob (rewarded + interstitial). Publicacion en Google Play con cuenta personal.

- Motor: **Godot 4.7.x** (renderer Mobile), **GDScript 4 tipado**.
- Plataforma objetivo: Android (Play Store), `minSdk 24`, `targetSdk 36`, `arm64-v8a`.
- Vista: **portrait**, viewport base 360x640, `stretch=canvas_items`, `aspect=keep`.
- Arte: vector plano original. Sin assets ni marcas de terceros.
- Estado actual: base jugable completa, 30 niveles progresivos, modo personalizado, modo infierno, game over con rewarded, logros, desbloqueos, personalizacion visual y de audio, UI retro y pruebas headless.

## 2. Comandos

Godot no esta necesariamente en `PATH`. Los scripts aceptan `-GodotExe`.

```powershell
# Importar recursos / validar que el proyecto parsea
godot --headless --path . --import

# Ejecutar las pruebas headless de los 30 mapas (PowerShell)
$process = Start-Process -FilePath "C:\ruta\Godot_v4.7.2-stable_mono_win64.exe" -ArgumentList @("--headless", "--path", ".", "--script", "res://tests/test_runner.gd") -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) { throw "Tests fallidos" }

# APK de debug -> build\gato_gloton.apk
powershell -File scripts\build_debug.ps1 -GodotExe "C:\ruta\Godot_v4.7.2-stable_win64.exe"

# Instalar el APK en un Android conectado y autorizado
powershell -File scripts\install_debug.ps1

# AAB de release -> build\gato_gloton.aab (requiere keystore por variables de entorno)
powershell -File scripts\build_release.ps1 -GodotExe "C:\ruta\Godot.exe"

# Crear keystore de upload (una vez; guardar fuera del repo)
powershell -File scripts\create_keystore.ps1
```

Variables de release (Godot las lee directamente):

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`

## 3. Estructura

```
project.godot
export_presets.cfg          # presets "Android" (APK) y "Google Play" (AAB)
src/autoload/               # singletons: GameState, SaveManager, ProgressionManager, AchievementManager, UnlockManager, AudioManager, AdsManager, DevUnlock
src/ads/                    # AdsBackend, MockAds, AdMobBackend
src/game/                   # escenas y scripts de juego (main, maze, player, rival_dog, pantallas, hell_select_screen)
src/data/                   # niveles, mapas, logros, cosmeticos, reglas de infierno y modo personalizado
assets/                     # sprites, audio, fuentes, mapas, icono y recursos de tienda
tests/                      # runner headless y pruebas de cobertura de mapas
scripts/                    # build, validacion y renderizado
.github/workflows/          # CI Android
```

## 4. Convenciones de codigo

- GDScript 4 **tipado** (`var x: int`, `func f(a: int) -> void`). Prohibida API de Godot 3 (`yield`, `instance()`, `KinematicBody2D`, `TileMap` clasico).
- Indentacion con **tabs** (estandar Godot).
- `class_name` solo en scripts reutilizables; **no** en autoloads.
- Nombres: `snake_case` para variables/funciones, `PascalCase` para clases y nodos.
- Senales en pasado (`score_changed`), conectadas en `_ready` o en el editor.
- No usar `move_and_slide` para el jugador ni rivales: el movimiento es **grid-locked manual** entre tiles.
- Datos de balance en `.tres`, no hardcodeados en scripts.
- RNG inyectable con seed para tests deterministas.
- Cambios pequenos y revisables. Compilar/importar despues de cada tarea.

## 5. Arquitectura

- **Autoloads**
  - `GameState`: score, vidas, nivel, modo personalizado y senales de cambio.
  - `SaveManager`: JSON versionado v3 en `user://save.json`, record, nivel maximo, estadisticas, logros/desbloqueos/cosmeticos, ultima config personalizada y records de tiempo del modo infierno.
  - `ProgressionManager`: catalogo y avance de los 30 niveles progresivos.
  - `AchievementManager`: catalogo, progreso y notificaciones de los 17 logros.
  - `UnlockManager`: reglas, seleccion y paletas de los cosmeticos desbloqueables.
  - `AudioManager`: volumen/mute, reproduccion de SFX y musica.
  - `AdsManager`: fachada sobre `AdsBackend`; elige `MockAds` en desktop/editor y `AdMobBackend` en Android.
  - `DevUnlock`: en ejecuciones de escritorio debug (no headless ni Android) desbloquea automaticamente todos los logros, cosmeticos, el nivel 30 y el modo infierno para pruebas integrales.
- **Juego**
  - `Main`: state machine `Menu -> Playing -> Paused -> GameOver -> LevelClear`, con flujos separados para progresion, modo personalizado y modo infierno.
  - `Maze`: mapas generados en celdas completas, pellets, conectividad, respawn seguro y tema infernal con paredes de fuego.
  - `Player`, `RivalDog`: movimiento grid-locked y estados de IA; en infierno los rivales se dibujan como demonios rojos.
  - **Modo infierno**: desbloqueado al ganar una partida normal, selector libre de 30 niveles, una vida, sin pellets, cronometro y oleadas progresivas de demonios.
  - `HUD`: tabla retro con nivel, IA, puntos y vidas.
- **IA de rivales**: estados `Scatter/Chase/Frightened`, velocidad y agresividad configurables, sin A*.

## 6. Reglas de anuncios

- `MockAds` en editor/desktop; nunca cargar el SDK real fuera de Android.
- En Android, **UMP/consentimiento antes de cargar** cualquier anuncio.
- La inicializacion de `MobileAds` v5 es **asincrona**: no cargar ads hasta el callback.
- IDs de prueba en debug. Nunca hacer clic en anuncios propios.
- Rewarded: "continuar" una vez por partida. Interstitial: al completar cada nivel progresivo (salvo el nivel 30) y al morir en modo infierno, mostrando despues el menu o los resultados; si no esta listo, se omite. Banner solo en menu.
- Plugin previsto: `poingstudios/godot-admob-plugin` v5.x (Godot >= 4.5).

## 7. Android y Google Play

- AAB obligatorio. Firma con **upload key** + **Play App Signing**.
- `targetSdk 36` (obligatorio para apps nuevas desde 31-ago-2026). Revisar cada ano.
- `arm64-v8a` obligatorio; no anadir ABIs sin motivo.
- Cuenta **personal** creada despues del 13-nov-2023: cerrar test con **12 testers opt-in continuos 14 dias** antes de pedir produccion. Los testers internos no cuentan.
- Formularios obligatorios: IARC, Data safety, declaracion de ads, publico objetivo, politica de privacidad.
- No commitear keystore ni contrasenas. `export_presets.cfg` se commitea **sin** credenciales.

## 8. Legal / IP

- Las mecanicas no tienen copyright, pero **no** copiar nombre, laberinto exacto, sprites, sonidos ni trade dress de Pac-Man.
- No usar "Pac-Man"/"Pacman" en titulo, descripcion, keywords ni capturas.
- Verificar el nombre comercial antes de publicar.
- Arte de terceros: solo licencias que permitan uso comercial (p. ej. CC0). Guardar atribuciones si aplica.

## 9. Milestones

- M0: repo, project.godot, autoloads, ads mock, export presets, scripts, CI, APK debug.
- M0-M5: base jugable, menu, HUD, rivales, power mode, pausa y game over.
- M6: 30 niveles escalables, mapas generados, modo personalizado y UI retro.
- M7: balance completo y rendimiento Android.
- M8: logros, desbloqueos, cosmeticos y guardado ampliado.
- M9: AAB release, ficha y formularios.
- M10-M12: closed testing 12/14, produccion y metricas.

## 10. Definicion de "hecho"

- `godot --headless --path . --import` termina sin errores.
- La app arranca en desktop y en un Android real sin crashes.
- `tests/test_runner.gd`, `tests/save_test_runner.gd` y `tests/progression_test_runner.gd` en verde: validan los 30 mapas, la cobertura de pellets, el guardado, las migraciones, los logros, los desbloqueos, el contraste, el audio y las reglas del modo infierno.
- Sin secretos ni arte con licencia incompatible en el diff.
- Diff pequeno, con mensaje de commit claro.

## 11. Estado del entorno

- Godot instalado: `C:\Users\Isidro\Desktop\Godot_v4.7.2-stable_mono_win64`.
- JDK 17 instalado: `C:\Program Files\Java\jdk-17`.
- Android SDK disponible con `platforms;android-36`, `build-tools` y `platform-tools`.
- Export templates Mono 4.7.2 instalados en `%APPDATA%\Godot\export_templates\4.7.2.stable.mono`.
- Android build template instalado en `android\build`.
- Git remoto: `https://github.com/IsidroMansilla/GatoGloton.git`.
- El primer APK de debug ya se genero en `build\gato_gloton.apk`.
- `cmdline-tools` falta para usar `sdkmanager` y el workflow CI; no bloquea instalar el APK local.
- El APK debug se ha instalado y probado en un Redmi Note 9 Pro conectado por ADB.
- La fuente de interfaz es `assets/fonts/PressStart2P-Regular.ttf` bajo OFL 1.1.
