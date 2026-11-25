# Mapas de niveles

Esta carpeta contiene una imagen PNG por cada nivel de la progresion.

- `level_01.png` a `level_30.png`: mapas correspondientes a cada nivel.
- El nivel 1 comienza en `13x11` celdas y crece progresivamente hasta `25x21` en el nivel 30.
- Azul: paredes.
- Amarillo: bolas de pelo normales.
- Naranja: power-ups.
- Dorado: spawn del jugador.
- Rosa: spawn de los rivales.
- La linea superior representa la dificultad configurada del nivel.
- Los mapas usan paredes de bloques completos y una morfologia de laberinto
  diferente por nivel, generada con semilla determinista.
- Los niveles iniciales incluyen mas rutas alternativas; los avanzados son mas
  grandes, sinuosos y con menos atajos.

Las imagenes se generan con:

```powershell
godot --headless --path . --script res://scripts/render_level_maps.gd
```
