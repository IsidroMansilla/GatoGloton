extends Control


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var center := size * 0.5
	var frame := Rect2(12.0, 22.0, size.x - 24.0, size.y - 44.0)

	draw_rect(Rect2(Vector2.ZERO, size), Color("#070817"))
	for y in range(0, int(size.y), 8):
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.18, 0.12, 0.32, 0.18), 1.0)

	# Halo central para dar profundidad sin usar imagenes externas.
	for radius in range(150, 20, -10):
		var alpha := 0.008 + float(150 - radius) * 0.0002
		draw_circle(center + Vector2(0.0, 30.0), float(radius), Color(0.12, 0.35, 0.65, alpha))

	draw_style_box(_panel_style(Color("#11152F"), Color("#273B82"), 2.0), frame)
	draw_line(Vector2(frame.position.x, 116.0), Vector2(frame.end.x, 116.0), Color("#F97316"), 2.0)
	draw_line(Vector2(frame.position.x, frame.end.y - 62.0), Vector2(frame.end.x, frame.end.y - 62.0), Color("#273B82"), 1.0)

	# Luces de marquesina y pequeños remaches de cabinet.
	for x in range(32, int(size.x) - 20, 28):
		draw_circle(Vector2(x, 42.0), 3.0, Color("#FDE68A"))
		draw_circle(Vector2(x, 42.0), 6.0, Color(0.98, 0.58, 0.12, 0.12))
	for point in [Vector2(23.0, 34.0), Vector2(size.x - 23.0, 34.0), Vector2(23.0, size.y - 34.0), Vector2(size.x - 23.0, size.y - 34.0)]:
		draw_circle(point, 3.0, Color("#60A5FA"))


func _panel_style(fill: Color, border: Color, width: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(int(width))
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
