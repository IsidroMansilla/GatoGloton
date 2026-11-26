# Objetivos del proyecto

## 1. Objetivo final

Crear y publicar en Google Play un arcade 2D original de laberintos para Android.

El jugador controla un gato que recoge bolas de pelo, evita perros rivales y utiliza power-ups. El juego tendra dos modos, dificultad progresiva, partidas personalizadas, logros, desbloqueos y personalizacion visual.

El producto final debe ser jugable con controles tactiles, funcionar en portrait, mantener una buena visibilidad en pantallas pequenas y no depender de propiedad intelectual de terceros.

## 2. Modos de juego

### 2.1. Modo Progresion

El jugador empieza en el nivel 1 y avanza hasta un maximo inicial de 30 niveles.

- Los niveles 1-10 forman el bloque de aprendizaje.
- Los niveles 11-20 forman el bloque avanzado.
- Los niveles 21-30 forman el bloque de dificultad maxima.
- La dificultad aumenta de forma gradual y por bloques.
- Cada partida termina al perder todas las vidas.
- El nivel maximo alcanzado se guarda de forma persistente.
- Solo este modo genera logros, desbloqueos y progreso principal.

La dificultad puede aumentar mediante:

- Numero de perros rivales.
- Velocidad del jugador.
- Velocidad de los rivales.
- Diferencia de velocidad entre jugador y rivales.
- Complejidad del mapa.
- Tamano del mapa dentro de limites de visibilidad.
- Dificultad de la inteligencia artificial.
- Distribucion y frecuencia de power-ups.

Ninguna variable debe superar limites que hagan el juego injusto, ilegible o dificil de controlar mediante pantalla tactil.

### 2.2. Modo Personalizado

El jugador puede crear partidas personalizadas usando cualquier nivel que haya desbloqueado en el modo progresion.

Puede configurar:

- Velocidad del jugador.
- Velocidad y numero de rivales.
- Tamano y dificultad del mapa.
- Dificultad de la inteligencia artificial.
- Numero y frecuencia de power-ups.
- Otras variables de balance que se incorporen posteriormente.

Las partidas personalizadas:

- No aumentan el nivel maximo del modo progresion.
- No conceden logros.
- No desbloquean cosmeticos.
- No generan recompensas de progreso.
- Sirven para practicar y experimentar.

### 2.3. Modo Infierno

Se desbloquea al completar los 30 niveles del modo progresion. Permite elegir
libremente cualquiera de los 30 niveles existentes.

- Objetivo: sobrevivir el mayor tiempo posible.
- Sin bolas de pelo ni power-ups; la partida solo termina al morir.
- Una unica vida, sin reapariciones.
- Comienza con un demonio y aparecen mas cada pocos segundos.
- La curva de aparicion acelera hasta volverse practicamente imposible.
- HUD con cronometro y numero de demonios.
- Al morir se muestra un interstitial y despues los resultados.
- Los resultados muestran el tiempo, el record por nivel y una insignia de
  `NUEVO RECORD!` cuando corresponde.
- Acciones disponibles: `VOLVER A INTENTARLO` y `VOLVER AL MENU`.
- Los records de tiempo se guardan por nivel.
- Las partidas de infierno no alteran estadisticas, logros ni desbloqueos del
  modo normal.

## 3. Reglas de una partida

- Una partida finaliza al perder todas las vidas.
- Al perder una vida, el jugador permanece en el nivel actual.
- El nivel se reinicia completamente.
- El mapa conserva su configuracion.
- El jugador reaparece en una celda transitable aleatoria y valida.
- El punto de reaparicion debe tener una ruta de salida.
- El punto de reaparicion no puede estar ocupado ni demasiado cerca de un rival.
- El jugador recibe un breve periodo de invulnerabilidad tras reaparecer.
- La puntuacion y el nivel de la partida se conservan al perder una vida.

## 4. Pantallas y flujo principal

El menu inicial debe incluir:

- Boton `INICIAR` para el modo progresion.
- Boton `MODO PERSONALIZADO`.
- Boton `PERSONALIZAR`.
- Boton `LOGROS`.
- Boton `AJUSTES`.
- Nivel maximo alcanzado.
- Mejor puntuacion.
- Resumen de desbloqueos recientes.

El flujo del modo progresion sera:

1. Menu inicial.
2. Seleccion de modo progresion.
3. Inicio de una nueva partida en el nivel 1.
4. Juego y avance de nivel.
5. Pantalla de nivel completado.
6. Siguiente nivel o game over.

El flujo del modo personalizado sera:

1. Menu inicial.
2. Seleccion de modo personalizado.
3. Seleccion de nivel desbloqueado.
4. Configuracion de variables.
5. Validacion de limites.
6. Inicio de la partida personalizada.

## 5. Pantalla Game Over

Cuando el jugador pierde todas las vidas se muestra una pantalla `GAME OVER` con estas opciones:

### Continuar con anuncio

- Mostrar un anuncio recompensado.
- Conceder una vida adicional.
- Continuar en el nivel actual.
- Reiniciar completamente el nivel actual.
- Conservar la puntuacion y el nivel alcanzado.
- Permitir esta opcion una sola vez por partida.
- Deshabilitar la opcion si el anuncio no esta disponible.

### Volver al menu

- Guardar estadisticas, puntuacion y nivel maximo.
- Finalizar la partida actual.
- Volver al menu inicial.

### Empezar desde el nivel 1

- Guardar la partida anterior.
- Finalizar la partida actual.
- Iniciar una nueva partida progresiva desde el nivel 1.

## 6. Mapas

Los mapas se generan de forma controlada con un algoritmo de laberinto y una semilla determinista por nivel. Esto permite 30 geometrias distintas, reproducibles y validadas sin depender de mapas pintados a mano.

- Definir al menos 10 variantes base de mapa.
- Asignar mapas y variaciones a los 30 niveles.
- Mantener rutas de escape razonables.
- Definir celdas validas de inicio y reaparicion.
- Garantizar que las zonas transitables sean alcanzables.
- Mantener la geometria visible en portrait.
- Probar cada mapa con diferentes cantidades y velocidades de rivales.
- Crear estilos visuales desbloqueables sin alterar necesariamente la geometria.
- Hacer crecer el mapa proporcionalmente de 13x11 celdas en el nivel 1 a 25x21 en el nivel 30.
- Ajustar automaticamente el tamano de las celdas para conservar la visibilidad en portrait.

## 7. Logros

Los logros solo se pueden conseguir en el modo progresion.

Objetivos iniciales de logros:

- Alcanzar niveles concretos.
- Completar partidas.
- Jugar un numero determinado de partidas.
- Completar un nivel sin perder vidas.
- Obtener determinadas puntuaciones.
- Recoger power-ups concretos.
- Superar grupos de niveles.
- Llegar al nivel 30.

Cada logro tendra:

- Identificador estable.
- Nombre.
- Descripcion.
- Condicion.
- Progreso actual.
- Estado completado.
- Recompensa opcional.

## 8. Desbloqueos y personalizacion

El jugador podra personalizar:

- Estilo del gato del jugador.
- Estilo de los perros rivales.
- Estilo del mapa.
- Estilo de paredes y fondo.
- Estilo de las bolas de pelo.
- Estilo de los power-ups.
- Efectos visuales.
- Efectos de sonido.
- Musica.
- Animaciones.

Los desbloqueos dependeran de partidas y niveles alcanzados en el modo progresion.

- Jugar un numero de partidas puede desbloquear contenido.
- Completar partidas puede desbloquear contenido.
- Alcanzar niveles concretos puede desbloquear contenido.
- Conseguir puntuaciones concretas puede desbloquear contenido.
- Las partidas personalizadas no cuentan para estos requisitos.
- Los cosmeticos no proporcionaran ventajas de gameplay.

Todo contenido desbloqueable tendra un identificador, categoria, requisito, recurso visual o sonoro y estado guardado.

## 9. Objetivos tecnicos ordenados

### Fase 0: Base del proyecto

- [x] Crear el proyecto Godot.
- [x] Configurar exportacion Android.
- [x] Configurar APK debug e instalacion mediante ADB.
- [x] Crear un laberinto original.
- [x] Crear movimiento grid-locked.
- [x] Anadir control por teclado y swipe.
- [x] Probar el APK en un telefono Android real.

### Fase 1: Bucle jugable base

- [x] Crear menu de inicio.
- [x] Anadir boton de inicio.
- [x] Mostrar el laberinto al comenzar una partida.
- [x] Anadir bolas de pelo coleccionables.
- [x] Anadir puntuacion.
- [x] Anadir vidas y respawn.
- [x] Anadir condicion de nivel completado.
- [x] Anadir perros rivales con IA inicial.
- [x] Anadir power-ups y modo vulnerable.
- [x] Anadir pausa y game over.
- [x] Anadir audio y efectos.

### Fase 2: Arquitectura de niveles

- [x] Crear `LevelConfig` como recurso de datos.
- [x] Separar balance y reglas de los scripts de gameplay.
- [x] Definir los limites de velocidad, rivales y tamano de mapa.
- [x] Crear la tabla de dificultad de los 30 niveles.
- [x] Crear validacion de configuraciones de nivel.
- [x] Crear celdas validas de inicio y reaparicion.
- [x] Implementar busqueda de reaparicion segura y aleatoria.

### Fase 3: Mapas y progresion de laberintos

- [x] Disenar el generador de mapas y sus variantes base.
- [x] Generar al menos 10 variantes de mapa para la primera version.
- [x] Asignar mapas y semillas a los niveles progresivos.
- [x] Validar conectividad y rutas de escape.
- [x] Validar visibilidad en portrait.
- [ ] Probar rendimiento con mapas grandes.

### Fase 4: Modo progresion

- [x] Crear `ProgressionManager`.
- [x] Iniciar siempre en el nivel 1 cuando corresponda.
- [x] Aplicar la configuracion de cada nivel.
- [x] Avanzar al siguiente nivel al completar el mapa.
- [x] Mostrar nivel y dificultad en el HUD.
- [x] Implementar los 30 niveles iniciales.
- [x] Guardar el nivel maximo alcanzado.
- [ ] Probar el balance completo de la progresion.

### Fase 5: Game over y anuncios

- [x] Implementar las tres acciones de la pantalla game over.
- [x] Reiniciar el nivel al continuar con una vida adicional.
- [x] Limitar la continuacion con anuncio a una vez por partida.
- [x] Deshabilitar continuar cuando no haya anuncio disponible.
- [x] Integrar AdMob y UMP.
- [x] Verificar el flujo de anuncio recompensado en Android.
- [x] Mostrar interstitial al completar cada nivel progresivo y esperar la confirmacion del siguiente nivel.

### Fase 6: Modo personalizado

- [x] Crear `CustomGameConfig`.
- [x] Crear pantalla de configuracion personalizada.
- [x] Permitir seleccionar solo niveles progresivos desbloqueados.
- [x] Anadir controles para las variables de juego.
- [x] Validar valores minimos y maximos.
- [x] Mostrar una estimacion de dificultad.
- [x] Evitar que el modo personalizado genere progreso.

### Fase 7: Guardado y estadisticas

- [x] Versionar el formato de `SaveManager`.
- [x] Guardar partidas iniciadas y completadas.
- [x] Guardar nivel maximo.
- [x] Guardar mejor puntuacion.
- [x] Guardar progreso de logros.
- [x] Guardar desbloqueos.
- [x] Guardar cosmeticos seleccionados.
- [x] Guardar la ultima configuracion personalizada.
- [x] Implementar migraciones de datos.
- [x] Probar archivo inexistente, corrupto y de versiones anteriores.

### Fase 8: Logros y desbloqueos

- [x] Crear `AchievementManager`.
- [x] Crear `UnlockManager`.
- [x] Crear catalogo de logros.
- [x] Crear catalogo de cosmeticos.
- [x] Evaluar logros solo durante partidas progresivas.
- [x] Desbloquear contenido segun partidas y nivel alcanzado.
- [x] Mostrar notificacion de desbloqueo.
- [x] Crear pantalla de logros.
- [x] Crear pantalla de personalizacion.

### Fase 9: Contenido visual y sonoro

- [x] Aplicar `Press Start 2P` a la interfaz.
- [x] Crear tema arcade compartido.
- [x] Crear HUD retro en tabla horizontal.
- [x] Integrar visualmente pausa, game over y modo personalizado.
- [x] Centrar el laberinto horizontal y verticalmente.

- [x] Crear estilos alternativos del jugador.
- [x] Crear estilos alternativos de rivales.
- [x] Crear estilos alternativos de mapas.
- [x] Crear estilos alternativos de bolas de pelo y power-ups.
- [x] Crear efectos visuales desbloqueables.
- [x] Crear efectos de sonido desbloqueables.
- [x] Crear musica desbloqueable.
- [x] Validar contraste y visibilidad de todos los estilos.

### Fase 9.5: Modo Infierno

- [x] Desbloquearlo al completar los 30 niveles del modo normal.
- [x] Crear selector libre de los 30 niveles.
- [x] Implementar supervivencia sin pellets y con una unica vida.
- [x] Implementar oleadas progresivas de demonios.
- [x] Añadir cronometro y HUD especifico.
- [x] Aplicar tema infernal al laberinto y convertir a los rivales en demonios.
- [x] Mostrar interstitial al morir y resultados despues del anuncio.
- [x] Guardar records de tiempo por nivel.
- [x] Añadir botones `VOLVER A INTENTARLO` y `VOLVER AL MENU`.
- [x] Aislar el modo de estadisticas, logros y desbloqueos normales.
- [x] Añadir pruebas de reglas, tiempo y ausencia de coleccionables.

### Fase 9.6: Ajustes y pulido movil

- [x] Anadir pantalla `AJUSTES` desde el menu y desde la pausa.
- [x] Persistir mute, volumenes, vibracion, reducir movimiento y tutorial visto.
- [x] Anadir vibracion opcional con permiso `VIBRATE`.
- [x] Pausar automaticamente al perder el foco o pasar a segundo plano.
- [x] Mostrar intro `READY` con gracia al iniciar cada nivel.
- [x] Anadir tutorial de primer arranque.
- [x] Reiniciar progreso con doble confirmacion conservando ajustes.

### Fase 10: Publicacion y calidad

- [x] Ejecutar importacion headless sin errores.
- [x] Ejecutar pruebas de logica y guardado.
- [x] Probar menu, personalizado, pausa y game over en Android real.
- [ ] Probar el modo infierno completo en Android real.
- [ ] Probar rendimiento con el nivel 30.
- [ ] Verificar ausencia de crashes en logcat.
- [ ] Generar AAB release firmado.
- [ ] Completar ficha de Google Play.
- [ ] Completar formularios de privacidad, anuncios, IARC y publico objetivo.
- [ ] Completar test cerrado con 12 testers durante 14 dias.
- [ ] Publicar la primera version.

## 10. Sistemas previstos

- `GameState`: estado de la partida actual.
- `SaveManager`: persistencia versionada.
- `ProgressionManager`: niveles y dificultad progresiva.
- `CustomGameConfig`: configuracion personalizada.
- `HellRules`: reglas, tiempos y curva de oleadas del modo infierno.
- `AchievementManager`: logros y progreso.
- `UnlockManager`: requisitos y desbloqueos.
- `CosmeticManager`: estilos seleccionados.
- `AudioManager`: musica, efectos y volumen.
- `AdsManager`: anuncios y recompensas.
- `Main`: maquina de estados del juego.
- `Maze`: mapa, pellets, conectividad y celdas validas.
- `Player`: movimiento, vidas y reaparicion.
- `RivalDog`: movimiento e inteligencia artificial.
- `HUD`: puntuacion, nivel, vidas y estado de partida.

## 11. Definicion de hecho

- La aplicacion arranca sin errores en desktop y Android.
- El menu permite acceder a los modos progresion, personalizado e infierno.
- El modo progresion contiene los 30 niveles iniciales.
- El modo personalizado respeta el nivel maximo desbloqueado.
- El modo infierno se desbloquea al completar los 30 niveles.
- Las partidas personalizadas y de infierno no alteran logros ni progreso normal.
- El respawn siempre usa una posicion valida y segura.
- El game over ofrece las acciones definidas.
- El guardado sobrevive al cierre y reapertura de la aplicacion.
- Los logros y desbloqueos se conceden correctamente.
- Todos los cosmeticos mantienen la legibilidad del juego.
- Las pruebas de logica estan en verde.
- El AAB se puede instalar y probar en Android real.
- No hay secretos ni recursos con licencias incompatibles.

## 12. Estado de publicacion

- [x] Integrar AdMob y UMP.
- [ ] Crear y revisar ficha de Google Play.
- [ ] Completar test cerrado con 12 testers durante 14 dias.
- [ ] Publicar la primera version.
