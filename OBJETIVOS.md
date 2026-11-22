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
- [ ] Crear menu de inicio.
- [ ] Añadir boton `INICIAR`.
- [ ] Hacer que `INICIAR` oculte el menu y muestre el laberinto.
- [ ] Añadir pellets coleccionables reales.
- [ ] Añadir score por pellet.
- [ ] Añadir vidas y respawn.
- [ ] Añadir condicion de nivel completado.
- [ ] Añadir gatos rivales con IA.
- [ ] Añadir power-up y modo vulnerable.
- [ ] Añadir menu de pausa y game over.
- [ ] Añadir audio y efectos.
- [ ] Integrar AdMob y UMP.
- [ ] Crear ficha de Google Play.
- [ ] Completar test cerrado con 12 testers durante 14 dias.
- [ ] Publicar la primera version.

## Siguiente objetivo: menu de inicio

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
