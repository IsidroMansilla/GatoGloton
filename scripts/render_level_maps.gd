extends SceneTree

const LEVEL_CATALOG: LevelCatalog = preload("res://src/data/progression_levels.tres")
const TILE_SIZE: int = 24
const MARGIN: int = 24
const HEADER_HEIGHT: int = 44
const WALL_COLOR := Color("#2563EB")
const WALL_EDGE_COLOR := Color("#60A5FA")
const FLOOR_COLOR := Color("#0B1220")
const PELLET_COLOR := Color("#FDE68A")
const POWER_COLOR := Color("#F97316")
const PLAYER_COLOR := Color("#F59E0B")
const RIVAL_COLOR := Color("#EC4899")


func _initialize() -> void:
	var output_dir := ProjectSettings.globalize_path("res://assets/maps")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for level_number in range(1, 31):
		_render_level(level_number, output_dir)
	quit()


func _render_level(level_number: int, output_dir: String) -> void:
	var config := LEVEL_CATALOG.get_level(level_number)
	var map_data := MazeCatalog.get_map(config.map_id, level_number)
	var width := map_data.rows[0].length() * TILE_SIZE + MARGIN * 2
	var height := map_data.rows.size() * TILE_SIZE + MARGIN * 2 + HEADER_HEIGHT
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color("#050816"))
	var active_power_cells: Array[Vector2i] = []
	var selected_count := mini(config.power_up_count, map_data.power_pellet_cells.size())
	for index in selected_count:
		var selected_index := mini(index * map_data.power_pellet_cells.size() / maxi(selected_count, 1), map_data.power_pellet_cells.size() - 1)
		active_power_cells.append(map_data.power_pellet_cells[selected_index])

	var difficulty_color := Color("#22C55E").lerp(Color("#EF4444"), config.map_difficulty)
	_fill_rect(image, Rect2i(MARGIN, MARGIN, width - MARGIN * 2, HEADER_HEIGHT - 8), Color("#111827"))
	_fill_rect(image, Rect2i(MARGIN, MARGIN + HEADER_HEIGHT - 8, width - MARGIN * 2, 3), difficulty_color)

	for y in map_data.rows.size():
		for x in map_data.rows[y].length():
			var cell := Vector2i(x, y)
			var rect := Rect2i(MARGIN + x * TILE_SIZE, MARGIN + HEADER_HEIGHT + y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			if map_data.is_walkable(cell):
				_fill_rect(image, rect, FLOOR_COLOR)
				var pellet_center := Vector2i(rect.position.x + TILE_SIZE / 2, rect.position.y + TILE_SIZE / 2)
				if cell in active_power_cells:
					_fill_circle(image, pellet_center, 5, POWER_COLOR)
				else:
					_fill_circle(image, pellet_center, 2, PELLET_COLOR)
			else:
				_fill_rect(image, rect.grow(-2), WALL_COLOR)
				_fill_rect(image, Rect2i(rect.position + Vector2i(5, 5), rect.size - Vector2i(10, 10)), WALL_EDGE_COLOR)

	_draw_marker(image, map_data.player_spawn, PLAYER_COLOR)
	for rival_spawn in map_data.rival_spawns:
		_draw_marker(image, rival_spawn, RIVAL_COLOR)

	var output_path := output_dir.path_join("level_%02d.png" % level_number)
	var error := image.save_png(output_path)
	if error != OK:
		push_error("No se pudo guardar %s: %s" % [output_path, error_string(error)])


func _draw_marker(image: Image, cell: Vector2i, color: Color) -> void:
	var center := Vector2i(MARGIN + cell.x * TILE_SIZE + TILE_SIZE / 2, MARGIN + HEADER_HEIGHT + cell.y * TILE_SIZE + TILE_SIZE / 2)
	_fill_circle(image, center, 8, color)
	_fill_circle(image, center, 4, Color("#111827"))


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			image.set_pixel(x, y, color)


func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_squared := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_squared_to(center) <= radius_squared and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)
