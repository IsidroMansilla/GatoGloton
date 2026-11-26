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
- Estado: base jugable completa, guardado ampliado, logros, personalización visual y audio desbloqueable, modo infierno; pendientes balance final, rendimiento y publicación.

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
- En ejecuciones de escritorio debug (no headless ni Android), `DevUnlock`
  desbloquea automaticamente todos los logros, cosmeticos, el nivel 30 y el
  modo infierno para pruebas integrales.

## Estructura importante

```text
project.godot
export_presets.cfg
AGENTS.md
CONTEXTO.md
OBJETIVOS.md
src/autoload/               # estado, guardado, progresion, logros, desbloqueos, audio, anuncios y DevUnlock
src/ads/                    # backends MockAds y AdMob/UMP
src/game/                   # Main, Maze, Player, RivalDog, pantallas y menu
src/data/                   # niveles, mapas, logros, cosmeticos, reglas de infierno y config personalizada
assets/fonts/               # Press Start 2P y tema arcade
assets/maps/                # PNG de referencia de los 30 niveles
assets/store/               # recursos de Google Play
tests/                      # runners headless de mapas, guardado y progresion
scripts/                    # build, validacion y renderizado
android/                    # plantilla de exportacion Android
```

## Funcionalidad implementada

### Bucle jugable

- Menu inicial retro con `INICIAR`, `MODO PERSONALIZADO`, `LOGROS`, `PERSONALIZAR` y `MODO INFIERNO` (bloqueado hasta completar el modo normal).
- Movimiento grid-locked por teclado, WASD y swipe.
- Mapas con paredes de bloques completos y rutas conectadas.
- Bolas de pelo, power-ups, puntuacion, vidas y respawn seguro.
- Perros rivales dinamicos de 1 a 4 segun el nivel; el estilo por defecto es un doberman negro con bordes marrones.
- IA con estados `Scatter`, `Chase` y `Frightened`.
- Pausa con `CONTINUAR`, `REINICIAR` y `SALIR`.
- Game over con anuncio recompensado, reinicio y vuelta al menu.

### Progresion

- 30 niveles progresivos.
- Mapas de `13x11` a `25x21` celdas.
- Tamano de celda adaptativo para mantener la visibilidad en portrait.
- Velocidad, rivales, power-ups y agresividad de IA configurables por nivel.
- Al completar un nivel se muestra un interstitial; al cerrarlo aparece un menu
  con un unico boton `NIVEL N` para comenzar el siguiente nivel.
- Nivel maximo guardado en `user://save.json`.

### Modo Infierno

- Se desbloquea al completar los 30 niveles del modo progresion.
- Selector libre para jugar cualquiera de los 30 niveles.
- Supervivencia sin bolas de pelo ni power-ups; la partida solo termina al morir.
- Una unica vida y muerte instantanea, sin reapariciones.
- Empieza con un demonio y aparecen mas cada pocos segundos sin limite hasta que la partida termina.
- HUD con cronometro de supervivencia y numero de perseguidores.
- Al morir se muestra un interstitial y despues la pantalla de resultados.
- Resultados con tiempo total, aviso `NUEVO RECORD!`, `VOLVER A INTENTARLO` y
  `VOLVER AL MENU`.
- Records de tiempo por nivel guardados en `user://save.json`.
- Laberinto rojo con llamas y rivales convertidos en demonios rojos.
- No altera estadisticas, records, logros ni desbloqueos del modo normal.

### Guardado y estadisticas

- Esquema versionado v3 compatible con saves v1, v2 y sin version.
- Conserva record y nivel maximo.
- Guarda partidas iniciadas, terminadas por game over y ganadas, niveles
  completados, niveles sin dano, pellets, power-ups, rivales comidos y vidas perdidas.
- Prepara persistencia de logros, desbloqueos y cosmeticos seleccionados.
- Guarda la ultima configuracion del modo personalizado y la reutiliza al abrirlo.
- Guarda los mejores tiempos del modo infierno por nivel.
- Las partidas personalizadas y las de infierno no alteran estadisticas, records,
  logros ni desbloqueos del modo normal.
- Save ausente, corrupto o de version futura se maneja sin romper el arranque.

### Logros y desbloqueos

- Catalogo de 17 logros basado en niveles, partidas, puntuacion, pellets,
  power-ups, rivales y niveles completados sin dano.
- Catalogo de 21 cosmeticos en siete categorias: gato, rivales, mapa, bolas,
  efectos, sonido y musica.
- Los cosmeticos aplican paletas al jugador, rivales, laberinto, bolas y
  power-ups, y anaden aros o particulas de recogida.
- Estilos de sonido sintetizados (`classic`, `chip`, `deep`) y dos pistas de
  musica generadas y reproducidas en bucle.
- Contraste validado por pruebas para todas las paletas sobre cada suelo.
- Evaluacion de logros y desbloqueos solo durante partidas progresivas.
- Notificacion retro de desbloqueo durante la partida.
- Pantalla de logros con progreso por objetivo y pantalla de personalizacion
  con estado bloqueado, disponible o equipado.
- La seleccion de cosmeticos se guarda en `user://save.json`.

### Modo personalizado

- Seleccion limitado al nivel maximo progresivo desbloqueado.
- Configuracion de velocidad del jugador, velocidad y cantidad de rivales,
  dificultad de IA y power-ups.
- No aumenta rÃ©cord, nivel maximo, logros ni desbloqueos.

### Interfaz y arte

- Fuente `PressStart2P-Regular.ttf` bajo OFL 1.1.
- Tema arcade compartido en `assets/fonts/arcade_theme.tres`.
- HUD en tabla horizontal con nivel, IA, puntos y vidas; en infierno muestra
  cronometro y numero de demonios.
- Menus de pausa, game over, modo personalizado, logros, personalizacion e
  infierno con tarjetas retro.
- Laberinto centrado horizontal y verticalmente.
- Arte vectorial original sin marcas ni recursos de terceros incompatibles.

## Pruebas

El runner `tests/test_runner.gd` valida los 30 niveles sin depender de Android ni
de la IA. Comprueba configuracion, dimensiones, conectividad, ruta de cobertura,
recogida de pellets, spawns seguros y ausencia de coleccionables en infierno.

El runner `tests/save_test_runner.gd` valida guardado, migraciones v1/v2, archivo
ausente, corrupto, version futura, tipos invalidos, escritura fallida, records de
tiempo del modo infierno y el aislamiento de modos especiales.

El runner `tests/progression_test_runner.gd` valida los catalogos de logros,
cosmeticos y audio, el calculo de progreso, las reglas de desbloqueo, el contraste
visual, la generacion de pistas musicales, el cierre del interstitial simulado y
las reglas y curva de oleadas del modo infierno.

Resultado validado actualmente: `410 passed, 0 failed` en mapas, `106 passed, 0 failed`
en guardado y `95 passed, 0 failed` en progresion.

Para obtener un codigo de salida fiable en PowerShell se recomienda usar
`Start-Process -Wait -PassThru`, porque el ejecutable Mono puede dejar
`$LASTEXITCODE` vacio aunque termine correctamente.

## Pendientes principales

- Balancear la progresion completa jugando niveles iniciales, intermedios y finales.
- Balancear la curva de oleadas del modo infierno en Android real.
- Probar rendimiento del nivel 30 en Android.
- Generar AAB release, completar Play Console y realizar closed testing 12/14.

## Reglas de trabajo

- Leer `AGENTS.md` antes de modificar el proyecto.
- No usar nombres, sprites, sonidos ni laberintos de Pac-Man.
- Mantener el arte original.
- Validar en Godot headless antes de instalar.
- Probar el APK en el telefono despues de cada cambio relevante.
- No hacer commit ni push automaticamente sin solicitarlo.
