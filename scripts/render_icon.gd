extends SceneTree

const SOURCE_PATH := "res://assets/source/gato_icon_reference.jpg"
const OUTPUT_ICON := "res://assets/icon_pixel.png"
const OUTPUT_STORE_ICON := "res://assets/store/icon_512.png"
const OUTPUT_FOREGROUND := "res://assets/icon_adaptive_foreground.png"
const OUTPUT_BACKGROUND := "res://assets/icon_adaptive_background.png"

const BG_COLOR := Color("#1f2937")
const ICON_SIZE := 512
const FOREGROUND_SIZE := 432
const BASE_SIZE := 128
const PALETTE_MAX := 48


func _initialize() -> void:
	var source := Image.new()
	var err := source.load(ProjectSettings.globalize_path(SOURCE_PATH))
	if err != OK:
		push_error("No se pudo cargar la referencia: %s" % error_string(err))
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	_remove_white_background(source)

	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("La referencia quedo vacia tras quitar el fondo")
		quit(1)
		return
	var cropped := source.get_region(used)
	print("Recorte del gato: %s" % cropped.get_size())

	var base := _downscale_fit(cropped, BASE_SIZE)
	var palette := _extract_palette(base, PALETTE_MAX)
	print("Colores de paleta: %d" % palette.size())
	_apply_palette(base, palette)

	var icon := _new_canvas(ICON_SIZE)
	_paint_rounded_pixel_rect(icon, ICON_SIZE, 8, 112, BG_COLOR)
	_place_cat(icon, base, int(ICON_SIZE * 0.84))
	_save(icon, OUTPUT_ICON)

	var store_icon := _new_canvas(ICON_SIZE)
	store_icon.fill(BG_COLOR)
	_place_cat(store_icon, base, int(ICON_SIZE * 0.84))
	_save(store_icon, OUTPUT_STORE_ICON)

	var foreground := _new_canvas(FOREGROUND_SIZE)
	_place_cat(foreground, base, int(FOREGROUND_SIZE * 0.72))
	_save(foreground, OUTPUT_FOREGROUND)

	var background := _new_canvas(FOREGROUND_SIZE)
	background.fill(BG_COLOR)
	_save(background, OUTPUT_BACKGROUND)

	quit()


func _new_canvas(size: int) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


func _save(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("No se pudo guardar %s: %s" % [path, error_string(error)])
	else:
		print("Generado: %s" % path)


func _remove_white_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var total := width * height
	var visited := PackedByteArray()
	visited.resize(total)
	var stack: Array[int] = []

	for x in width:
		stack.append(x)
		stack.append((height - 1) * width + x)
	for y in height:
		stack.append(y * width)
		stack.append(y * width + width - 1)

	while not stack.is_empty():
		var index: int = stack.pop_back()
		if visited[index] == 1:
			continue
		visited[index] = 1
		var x := index % width
		var y := int(floor(float(index) / float(width)))
		var color := image.get_pixel(x, y)
		if not _is_background(color):
			continue
		image.set_pixel(x, y, Color(0, 0, 0, 0))
		if x > 0:
			stack.append(index - 1)
		if x < width - 1:
			stack.append(index + 1)
		if y > 0:
			stack.append(index - width)
		if y < height - 1:
			stack.append(index + width)


func _is_background(color: Color) -> bool:
	var max_channel := maxf(color.r, maxf(color.g, color.b))
	var min_channel := minf(color.r, minf(color.g, color.b))
	return min_channel > 0.78 and (max_channel - min_channel) < 0.10


func _downscale_fit(image: Image, max_side: int) -> Image:
	var scale := float(max_side) / float(maxi(image.get_width(), image.get_height()))
	var target_width := maxi(1, int(round(image.get_width() * scale)))
	var target_height := maxi(1, int(round(image.get_height() * scale)))
	var scaled := image.duplicate() as Image
	scaled.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)
	return scaled


func _extract_palette(image: Image, max_colors: int) -> Array[Color]:
	var buckets := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := (int(color.r * 63.0) << 12) | (int(color.g * 63.0) << 6) | int(color.b * 63.0)
			var entry: Array = buckets.get(key, [])
			if entry.is_empty():
				buckets[key] = [color.r, color.g, color.b, 1]
			else:
				entry[0] += color.r
				entry[1] += color.g
				entry[2] += color.b
				entry[3] += 1

	var entries: Array = []
	for key in buckets:
		entries.append(buckets[key])
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[3] > b[3])

	var palette: Array[Color] = []
	for index in mini(max_colors, entries.size()):
		var entry: Array = entries[index]
		var count: int = entry[3]
		palette.append(Color(entry[0] / count, entry[1] / count, entry[2] / count, 1.0))
	return palette


func _apply_palette(image: Image, palette: Array[Color]) -> void:
	var cache := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := (int(color.r * 255.0) << 16) | (int(color.g * 255.0) << 8) | int(color.b * 255.0)
			var mapped: Color = cache.get(key, Color(0, 0, 0, 0))
			if mapped.a == 0.0:
				mapped = _nearest_color(color, palette)
				cache[key] = mapped
			image.set_pixel(x, y, Color(mapped.r, mapped.g, mapped.b, color.a))


func _nearest_color(color: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var dr := color.r - candidate.r
		var dg := color.g - candidate.g
		var db := color.b - candidate.b
		var distance := dr * dr + dg * dg + db * db
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _paint_rounded_pixel_rect(image: Image, size: int, block: int, radius: int, color: Color) -> void:
	for by in range(0, size, block):
		for bx in range(0, size, block):
			var center := Vector2(float(bx) + block * 0.5, float(by) + block * 0.5)
			if _inside_rounded_rect(center, size, radius):
				_fill_rect(image, Rect2i(bx, by, block, block), color)


func _inside_rounded_rect(point: Vector2, size: int, radius: int) -> bool:
	var nearest := Vector2(
		clampf(point.x, float(radius), float(size - radius)),
		clampf(point.y, float(radius), float(size - radius))
	)
	var delta := point - nearest
	return delta.length_squared() <= float(radius * radius)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			image.set_pixel(x, y, color)


func _place_cat(canvas: Image, cat: Image, box: int) -> void:
	var scale := float(box) / float(maxi(cat.get_width(), cat.get_height()))
	var target_width := maxi(1, int(round(cat.get_width() * scale)))
	var target_height := maxi(1, int(round(cat.get_height() * scale)))
	var scaled := cat.duplicate() as Image
	scaled.resize(target_width, target_height, Image.INTERPOLATE_NEAREST)
	var position := Vector2i(
		(canvas.get_width() - target_width) / 2,
		(canvas.get_height() - target_height) / 2
	)
	canvas.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), position)
