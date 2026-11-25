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
- Estado: base jugable completa, guardado ampliado, logros y personalización; pendientes balance final, arte alternativo y publicación.

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
src/autoload/               # estado, guardado, progresion, logros, desbloqueos, audio y anuncios
src/ads/                    # backends MockAds y AdMob/UMP
src/game/                   # Main, Maze, Player, RivalCat, pantallas y menu
src/data/                   # niveles, mapas, logros, cosmeticos y config personalizada
assets/fonts/               # Press Start 2P y tema arcade
assets/maps/                # PNG de referencia de los 30 niveles
assets/store/               # recursos de Google Play
tests/                      # runners headless de mapas, guardado y progresion
scripts/                    # build, validacion y renderizado
android/                    # plantilla de exportacion Android
```

## Funcionalidad implementada

### Bucle jugable

- Menu inicial retro con `INICIAR`, `MODO PERSONALIZADO`, `LOGROS` y `PERSONALIZAR`.
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

### Guardado y estadisticas

- Esquema versionado v3 compatible con saves v1, v2 y sin version.
- Conserva record y nivel maximo.
- Guarda partidas iniciadas, terminadas por game over y ganadas, niveles
  completados, niveles sin dano, pellets, power-ups, rivales comidos y vidas perdidas.
- Prepara persistencia de logros, desbloqueos y cosmeticos seleccionados.
- Guarda la ultima configuracion del modo personalizado y la reutiliza al abrirlo.
- Las partidas personalizadas no alteran estadisticas, records, logros ni desbloqueos.
- Save ausente, corrupto o de version futura se maneja sin romper el arranque.

### Logros y desbloqueos

- Catalogo de 17 logros basado en niveles, partidas, puntuacion, pellets,
  power-ups, rivales y niveles completados sin dano.
- Catalogo de 9 cosmeticos en tres categorias: gato, rivales y mapa.
- Los cosmeticos aplican paletas propias al jugador, a los rivales y al laberinto.
- Evaluacion de logros y desbloqueos solo durante partidas progresivas.
- Notificacion retro de desbloqueo durante la partida.
- Pantalla de logros con progreso por objetivo y pantalla de personalizacion
  con estado bloqueado, disponible o equipado.
- La seleccion de cosmeticos se guarda en `user://save.json`.

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

El runner `tests/save_test_runner.gd` valida guardado, migraciones v1/v2, archivo
ausente, corrupto, version futura, tipos invalidos, escritura fallida y el
aislamiento de las partidas personalizadas.

El runner `tests/progression_test_runner.gd` valida los catalogos de logros y
cosmeticos, el calculo de progreso y las reglas de desbloqueo.

Resultado validado actualmente: `380 passed, 0 failed` en mapas, `97 passed, 0 failed`
en guardado y `45 passed, 0 failed` en progresion.

Para obtener un codigo de salida fiable en PowerShell se recomienda usar
`Start-Process -Wait -PassThru`, porque el ejecutable Mono puede dejar
`$LASTEXITCODE` vacio aunque termine correctamente.

## Pendientes principales

- Balancear la progresion completa jugando niveles iniciales, intermedios y finales.
- Probar rendimiento del nivel 30 en Android.
- Ampliar estilos alternativos de arte y audio (Fase 9).
- Generar AAB release, completar Play Console y realizar closed testing 12/14.

## Reglas de trabajo

- Leer `AGENTS.md` antes de modificar el proyecto.
- No usar nombres, sprites, sonidos ni laberintos de Pac-Man.
- Mantener el arte original.
- Validar en Godot headless antes de instalar.
- Probar el APK en el telefono despues de cada cambio relevante.
- No hacer commit ni push automaticamente sin solicitarlo.
