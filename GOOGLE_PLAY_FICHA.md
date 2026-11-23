# Ficha de Google Play - Gato Gloton

Ficha preparada para Play Console. Antes de publicar hay que subir los recursos
graficos, publicar `PRIVACIDAD.md` en una URL HTTPS y revisar Data safety con la
configuracion final de AdMob.

## Informacion basica

- Nombre de la aplicacion: `Gato Gloton`
- Package name: `com.isidro.gatogloton`
- Categoria: `Juegos > Arcade`
- Precio: `Gratis`
- Contiene anuncios: `Si`
- Compras dentro de la aplicacion: `No`
- Orientacion: `Vertical`
- Idioma principal: `Español`
- Correo de contacto: `isidro.mansilla.1994@outlook.es`
- Politica de privacidad: `https://github.com/IsidroMansilla/GatoGloton/blob/main/PRIVACIDAD.md`

## Textos de la ficha

### Titulo

`Gato Gloton`

### Descripcion breve

`Come bolas de pelo, esquiva rivales y supera cada laberinto arcade.`

### Descripcion completa

`Gato Gloton es un arcade de laberinto original y directo al juego.`

`Mueve a tu gato por pasillos llenos de bolas de pelo, recoge puntos y activa
power-ups para poner a los rivales en modo vulnerable. Cada partida combina
reflejos, rutas cortas y decisiones rapidas.`

`Incluye:`

- `Laberintos arcade en orientacion vertical.`
- `Controles por deslizamiento, flechas y WASD.`
- `Pellets normales y power-ups especiales.`
- `Rivales con persecucion y patrulla.`
- `Vidas, respawn, pausa y record local.`
- `Efectos de sonido originales y anuncios integrados con consentimiento.`

`Juega una partida rapida, supera tu record y vuelve a intentarlo.`

## Recursos graficos

- Icono de aplicacion: disponible en `assets/icon.svg`, 512x512.
- Grafico de funciones: disponible en `assets/store/feature_graphic.png`, 1024x500.
- Captura vertical 1: menu arcade.
- Captura vertical 2: gameplay con pellets y rival.
- Captura vertical 3: power-up y rival vulnerable.
- Captura vertical 4: pausa o game over.
- Video promocional: opcional, `PENDIENTE`.

Las capturas deben usar exclusivamente arte propio y no incluir referencias a
marcas o juegos de terceros.

## Declaraciones de Play Console

### Anuncios

- Declarar que la aplicacion contiene anuncios.
- Mantener IDs de prueba hasta tener una version cerrada estable.
- Revisar el formulario UMP en cada instalacion nueva.
- No hacer clic en anuncios propios durante las pruebas.

### Data safety - declaracion preparada para revisar

La aplicacion no tiene cuentas, login, chat ni servidor propio. El guardado de
record se hace localmente en `user://save.json`. AdMob/UMP puede procesar datos
del dispositivo, identificadores, interacciones con anuncios, diagnosticos y
ubicacion aproximada segun el consentimiento, la region y la configuracion de
Google Mobile Ads.

- Proveedor que recibe datos: Google Mobile Ads / AdMob.
- Finalidades posibles: publicidad, analitica de anuncios, prevencion de fraude
  y funcionamiento del servicio.
- Comparticion y recopilacion: confirmar en Play Console con la version final
  del SDK y la configuracion de consentimiento.
- Eliminacion de datos: no hay cuenta propia; el usuario puede borrar datos de
  la aplicacion. La retencion de datos de AdMob depende de Google.

La declaracion final debe contrastarse con la ficha de datos vigente de Google
Mobile Ads antes de enviarla.

### Publico objetivo y contenido

- Seleccionar el rango de edad solo despues de confirmar la estrategia de
  publico del proyecto.
- Declarar que el juego contiene anuncios.
- Revisar si el contenido y los anuncios son adecuados para menores si se
  selecciona un rango que los incluya.
- Completar IARC antes de publicar.

## Checklist de lanzamiento

- [x] Definir correo publico de soporte: `isidro.mansilla.1994@outlook.es`.
- [ ] Publicar `PRIVACIDAD.md` en una URL HTTPS publica y comprobar el enlace.
- [ ] Crear ficha en Play Console con package `com.isidro.gatogloton`.
- [ ] Subir icono, `assets/store/feature_graphic.png` y capturas.
- [ ] Completar IARC, anuncios, publico objetivo y Data safety.
- [ ] Sustituir IDs de anuncios de prueba por IDs de produccion solo en release.
- [ ] Generar AAB firmado con upload key.
- [ ] Crear closed testing.
- [ ] Invitar al menos 12 testers y mantenerlos opt-in durante 14 dias.
- [ ] Revisar crashes y ANR antes de solicitar produccion.
