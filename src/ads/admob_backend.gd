class_name AdMobBackend
extends AdsBackend

# TODO(M7): integrar poingstudios/godot-admob-plugin v5.x.
# Requisitos: Godot >= 4.5, Gradle build, minSdk 24, compileSdk 35+.
# MobileAds.initialize() es asincrono: no cargar anuncios hasta el callback.
# UMP/consentimiento antes de cargar. Usar IDs de prueba en debug.


func initialize() -> void:
	push_warning("AdMobBackend sin implementar (M7); usando flujo mock")


func is_ready() -> bool:
	return false
