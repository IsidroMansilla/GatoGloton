# Objetivos del proyecto

## Objetivo principal

Crear y publicar en Google Play un juego arcade 2D original, desarrollado principalmente con ayuda de IA, monetizado inicialmente con anuncios.

## Estado de objetivos

- [x] Crear el proyecto Godot.
- [x] Configurar exportacion Android.
- [x] Configurar APK debug e instalacion mediante ADB.
- [x] Crear un laberinto original.
- [x] Crear movimiento grid-locked.
- [x] Añadir control por teclado y swipe.
- [x] Probar el APK en un telefono Android real.
- [x] Crear menu de inicio.
- [x] Añadir boton `INICIAR`.
- [x] Hacer que `INICIAR` oculte el menu y muestre el laberinto.
- [x] Añadir pellets coleccionables reales.
- [x] Añadir score por pellet.
- [x] Añadir vidas y respawn.
- [x] Añadir condicion de nivel completado.
- [x] Añadir gatos rivales con IA.
- [x] Añadir power-up y modo vulnerable.
- [x] Añadir menu de pausa y game over.
- [x] Añadir audio y efectos.
- [x] Integrar AdMob y UMP.
- [ ] Crear ficha de Google Play.
- [ ] Completar test cerrado con 12 testers durante 14 dias.
- [ ] Publicar la primera version.

## Objetivo completado: menu de inicio

### Resultado esperado

Al abrir la aplicacion debe aparecer un menu de inicio con:

- Nombre `Gato Gloton`.
- Boton grande `INICIAR`.
- Record actual opcional.
- Fondo visual que no tape el gameplay cuando se inicie.

Al pulsar `INICIAR`:

1. Se oculta el menu.
2. Se muestra el laberinto.
3. Se muestra el gato.
4. Se inicializa una partida nueva.
5. El jugador puede moverse inmediatamente.

### Implementacion prevista

- Mantener `Main` como controlador de estados.
- Añadir estados `MENU` y `PLAYING`.
- Crear un `Control` o `CanvasLayer` exclusivo para el menu.
- Usar un boton Godot con `mouse_filter` correcto.
- No usar un `ColorRect` opaco por encima del laberinto durante `PLAYING`.
- Conectar la señal `pressed` del boton a `_start_game()`.
- Mantener un fallback tactil solo si es necesario y documentarlo.
- Añadir una prueba manual en Android: abrir → pulsar `INICIAR` → mover por swipe.

### Criterios de aceptacion

- El menu aparece al abrir la app.
- El laberinto no aparece mientras el menu esta visible.
- `INICIAR` responde al toque real en el telefono.
- El laberinto aparece despues del toque.
- El gato se mueve despues de iniciar.
- No hay errores `SCRIPT ERROR` ni crashes en logcat.
- El APK actualizado se instala mediante `scripts\install_debug.ps1`.

## Siguiente objetivo: M2, coleccionables y puntuacion

La base de pellets, puntuacion y deteccion de nivel completado ya esta implementada. Falta continuar con vidas, respawn y la progresion de partida.

## Roadmap posterior

### M2: coleccionables y puntuacion

- Convertir las bolas visuales en pellets reales.
- Eliminar pellet al tocarlo.
- Sumar puntos.
- Mostrar score en HUD.
- Detectar laberinto completado.

### M3: rivales

- Crear gatos rivales.
- Estados `Scatter`, `Chase`, `Frightened` y `Eaten`.
- Target tile por personalidad.
- Colision jugador/rival.

### M4: partida completa

- Power-up.
- Vidas.
- Respawn.
- Game over.
- Pausa.
- Dificultad por nivel.

### M5: monetizacion y publicacion

- Integrar AdMob real.
- Añadir consentimiento UMP/GDPR.
- Usar rewarded para continuar.
- Generar AAB release.
- Crear ficha Play Store.
- Test cerrado 12/14.
- Publicar.
