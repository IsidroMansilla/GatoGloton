# Contexto del proyecto

## Identidad

- Proyecto: **Gato Gloton**.
- Ruta local: `C:\Users\Isidro\Documents\GatoGloton`.
- Repositorio remoto: `https://github.com/IsidroMansilla/GatoGloton.git`.
- Motor: Godot `4.7.2.stable.mono`.
- Lenguaje: GDScript 4 tipado.
- Desarrollo asistido principalmente con opencode.
- Plataforma objetivo: Android / Google Play.
- Orientacion: portrait.
- Resolucion logica: `360x640`, stretch `canvas_items`.

## Entorno configurado

- Godot: `C:\Users\Isidro\Desktop\Godot_v4.7.2-stable_mono_win64`.
- JDK 17: `C:\Program Files\Java\jdk-17`.
- Android SDK: `%LOCALAPPDATA%\Android\Sdk`.
- Android API objetivo: 36.
- `minSdk`: 24.
- Arquitectura: `arm64-v8a`.
- Export templates Mono 4.7.2 instalados.
- Android build template instalado en `android\build`.
- Cuenta/telefono Android conectados mediante ADB para pruebas.

## Estructura importante

```text
project.godot
export_presets.cfg
AGENTS.md
CONTEXTO.md
OBJETIVOS.md
src/autoload/
src/ads/
src/game/main.gd
src/game/main.tscn
src/game/maze.gd
src/game/player.gd
scripts/
assets/
tests/unit/
android/
```

## Funcionalidad implementada

### Scaffold M0

- Proyecto Godot funcional.
- Autoloads:
  - `GameState` para score, vidas y nivel.
  - `SaveManager` para high score en `user://save.json`.
  - `AudioManager` para mute y audio futuro.
  - `AdsManager` con `MockAds` en desktop y `AdMobBackend` pendiente.
- Export presets para APK Android y AAB Google Play.
- Scripts de entorno, build, keystore e instalacion del APK.
- Icono SVG original.
- Workflow CI Android inicial.

### M1

- Laberinto propio de 21x19 casillas.
- Paredes azules y bolas de pelo visuales.
- Movimiento grid-locked manual.
- Bloqueo contra paredes.
- Wrap horizontal en los extremos del laberinto.
- Buffer de direccion de 150 ms.
- Controles de teclado: flechas y WASD.
- Controles tactiles: swipe.
- Gato vectorial dibujado desde GDScript.
- APK debug probado en un telefono Android real.

## Decisiones y problemas resueltos

- Se eligio Godot + GDScript porque los archivos `.gd`, `.tscn` y `.tres` son faciles de generar y revisar con IA.
- El editor Mono funciona, pero el cierre headless del export puede quedarse abierto despues de generar el APK. La exportacion se controla detectando que el APK este completo.
- `adb devices` necesita un telefono autorizado con Depuracion USB.
- El fondo era un `ColorRect` dentro de un `CanvasLayer` y tapaba visualmente el laberinto. Se oculta al entrar al gameplay.
- El redibujado del laberinto se fuerza al mostrarlo con `queue_redraw()`.
- La aplicacion actualmente entra directamente al laberinto para poder validar M1 sin bloquearse en el menu.

## Estado actual de ejecucion

- Al abrir la app aparece directamente el laberinto.
- El jugador puede moverse deslizando el dedo.
- El menu de inicio esta temporalmente desactivado.
- El siguiente objetivo es restaurar el menu y hacer que el boton `INICIAR` lleve al laberinto.

## Reglas de trabajo

- Leer `AGENTS.md` antes de modificar el proyecto.
- No usar nombres, sprites, sonidos ni laberintos de Pac-Man.
- Mantener el arte original.
- Validar en Godot headless antes de instalar.
- Probar el APK en el telefono despues de cada cambio relevante.
- No hacer commit ni push automaticamente sin solicitarlo.
