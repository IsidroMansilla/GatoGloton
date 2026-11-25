# Contexto del proyecto

## Identidad

- Proyecto: **Gato Gloton**.
- Ruta local: `C:\Users\Isidro\Documents\GatoGloton`.
- Repositorio remoto: `https://github.com/IsidroMansilla/GatoGloton.git`.
- Motor: Godot `4.7.2.stable.mono`.
- Lenguaje: GDScript 4 tipado.
- Plataforma objetivo: Android / Google Play.
- Orientacion: portrait.
- Resolucion logica: `360x640`, stretch `canvas_items`.
- Estado: base jugable completa; pendientes balance final, guardado ampliado, logros y cosméticos.

## Entorno

- Godot: `C:\Users\Isidro\Desktop\Godot_v4.7.2-stable_mono_win64`.
- JDK 17: `C:\Program Files\Java\jdk-17`.
- Android SDK: `%LOCALAPPDATA%\Android\Sdk`.
- Android API objetivo: 36.
- `minSdk`: 24.
- Arquitectura: `arm64-v8a`.
- Export templates Mono 4.7.2 instalados.
- Android build template instalado en `android\build`.
- APK debug probado en un Redmi Note 9 Pro conectado por ADB.

## Estructura importante

```text
project.godot
export_presets.cfg
AGENTS.md
CONTEXTO.md
OBJETIVOS.md
src/autoload/               # estado, guardado, progresion, audio y anuncios
src/ads/                    # backends MockAds y AdMob/UMP
src/game/                   # Main, Maze, Player, RivalCat y menu
src/data/                   # niveles, mapas y configuracion personalizada
assets/fonts/               # Press Start 2P y tema arcade
assets/maps/                # PNG de referencia de los 30 niveles
assets/store/               # recursos de Google Play
tests/                      # runner headless de mapas y pellets
scripts/                    # build, validacion y renderizado
android/                    # plantilla de exportacion Android
```

## Funcionalidad implementada

### Bucle jugable

- Menu inicial retro con `INICIAR` y `MODO PERSONALIZADO`.
- Movimiento grid-locked por teclado, WASD y swipe.
- Mapas con paredes de bloques completos y rutas conectadas.
- Bolas de pelo, power-ups, puntuacion, vidas y respawn seguro.
- Rivales dinamicos de 1 a 4 segun el nivel.
- IA con estados `Scatter`, `Chase` y `Frightened`.
- Pausa con `CONTINUAR`, `REINICIAR` y `SALIR`.
- Game over con anuncio recompensado, reinicio y vuelta al menu.

### Progresion

- 30 niveles progresivos.
- Mapas de `13x11` a `25x21` celdas.
- Tamano de celda adaptativo para mantener la visibilidad en portrait.
- Velocidad, rivales, power-ups y agresividad de IA configurables por nivel.
- Nivel maximo guardado en `user://save.json`.

### Modo personalizado

- Seleccion limitado al nivel maximo progresivo desbloqueado.
- Configuracion de velocidad del jugador, velocidad y cantidad de rivales,
  dificultad de IA y power-ups.
- No aumenta récord, nivel maximo, logros ni desbloqueos.

### Interfaz y arte

- Fuente `PressStart2P-Regular.ttf` bajo OFL 1.1.
- Tema arcade compartido en `assets/fonts/arcade_theme.tres`.
- HUD en tabla horizontal con nivel, IA, puntos y vidas.
- Menus de pausa, game over y modo personalizado con tarjetas retro.
- Laberinto centrado horizontal y verticalmente.
- Arte vectorial original sin marcas ni recursos de terceros incompatibles.

## Pruebas

El runner `tests/test_runner.gd` valida los 30 niveles sin depender de Android ni
de la IA. Comprueba configuracion, dimensiones, conectividad, ruta de cobertura,
recogida de pellets y spawns seguros.

Resultado validado actualmente: `380 passed, 0 failed`.

Para obtener un codigo de salida fiable en PowerShell se recomienda usar
`Start-Process -Wait -PassThru`, porque el ejecutable Mono puede dejar
`$LASTEXITCODE` vacio aunque termine correctamente.

## Pendientes principales

- Balancear la progresion completa jugando niveles iniciales, intermedios y finales.
- Probar rendimiento del nivel 30 en Android.
- Ampliar `SaveManager` con estadisticas, logros y cosmeticos.
- Implementar `AchievementManager`, `UnlockManager` y personalizacion.
- Generar AAB release, completar Play Console y realizar closed testing 12/14.

## Reglas de trabajo

- Leer `AGENTS.md` antes de modificar el proyecto.
- No usar nombres, sprites, sonidos ni laberintos de Pac-Man.
- Mantener el arte original.
- Validar en Godot headless antes de instalar.
- Probar el APK en el telefono despues de cada cambio relevante.
- No hacer commit ni push automaticamente sin solicitarlo.
