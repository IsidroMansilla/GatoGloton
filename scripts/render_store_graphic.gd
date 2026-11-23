extends SceneTree


func _init() -> void:
	var texture := load("res://assets/store/feature_graphic.svg") as Texture2D
	if texture == null:
		push_error("No se pudo cargar el grafico SVG")
		quit(1)
		return
	var image := texture.get_image()
	if image.save_png("res://assets/store/feature_graphic.png") != OK:
		push_error("No se pudo guardar el grafico PNG")
		quit(1)
		return
	print("Grafico generado: res://assets/store/feature_graphic.png")
	quit()
