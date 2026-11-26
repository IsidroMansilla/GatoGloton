class_name Maze
extends Node2D

signal pellet_collected(points: int)
signal power_pellet_collected
signal level_completed

const TILE_SIZE: float = 16.0
const PLAYFIELD_WIDTH: float = 360.0
const PLAYFIELD_TOP: float = 0.0
const PLAYFIELD_BOTTOM: float = 640.0
var MAP: Array[String] = [
	"#####################",
	"#.........#.........#",
	"#.###.###.#.###.###.#",
	"#...................#",
	"#.###.#.#####.#.###.#",
	"#.....#...#...#.....#",
	"#####.#.#.#.#.#.#####",
	"#.....#.#...#.#.....#",
	"#.###.#.#####.#.###.#",
	"#...................#",
	"#.###.#.#####.#.###.#",
	"#.....#...#...#.....#",
	"#####.#.#.#.#.#.#####",
	"#.....#.#...#.#.....#",
	"#.###.#.#####.#.###.#",
	"#...................#",
	"#.###.###.#.###.###.#",
	"#.........#.........#",
	"#####################",
]

const WALL_COLOR := Color("#2563EB")
const WALL_EDGE_COLOR := Color("#60A5FA")
const FLOOR_COLOR := Color("#0B1220")
const DOT_COLOR := Color("#FDE68A")
const HELL_WALL_COLOR := Color("#991B1B")
const HELL_EDGE_COLOR := Color("#F97316")
const HELL_FLOOR_COLOR := Color("#1A0505")
const HELL_FLAME_COLOR := Color("#F97316")
const HELL_FLAME_CORE_COLOR := Color("#FDE68A")
const PELLET_POINTS: int = 10
const POWER_PELLET_POINTS: int = 50
var POWER_PELLET_CELLS: Array[Vector2i] = [Vector2i(19, 1), Vector2i(1, 17), Vector2i(19, 17)]
var _active_power_pellet_cells: Array[Vector2i] = []

var origin: Vector2 = Vector2(12.0, 104.0)
var tile_size: float = TILE_SIZE
var _pellets: Dictionary = {}
var _effects: Array[Dictionary] = []
var _walkable_cells: Array[Vector2i] = []
var hell_mode: bool = false
var map_id: String = "map_01"
var player_spawn_cell: Vector2i = Vector2i(1, 1)
var rival_spawn_cells: Array[Vector2i] = [Vector2i(10, 9)]


func _ready() -> void:
	_assert_map_is_valid()
	_cache_walkable_cells()
	queue_redraw()


func _process(delta: float) -> void:
	if _effects.is_empty():
		return
	for index in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[index]
		effect["age"] = float(effect.get("age", 0.0)) + delta
		if float(effect["age"]) >= float(effect.get("duration", 0.3)):
			_effects.remove_at(index)
	queue_redraw()


func set_hell_mode(value: bool) -> void:
	hell_mode = value
	queue_redraw()


func configure_map(map_data: MazeData) -> void:
	if map_data == null:
		push_error("No se puede configurar un mapa nulo")
		return
	var errors := map_data.validate()
	for error in errors:
		push_error("Mapa %s: %s" % [map_data.map_id, error])
	map_id = map_data.map_id
	MAP = map_data.rows.duplicate()
	tile_size = minf(TILE_SIZE, minf(336.0 / float(MAP[0].length()), 320.0 / float(MAP.size())))
	origin.x = (PLAYFIELD_WIDTH - float(MAP[0].length()) * tile_size) / 2.0
	origin.y = PLAYFIELD_TOP + (PLAYFIELD_BOTTOM - PLAYFIELD_TOP - float(MAP.size()) * tile_size) / 2.0
	player_spawn_cell = map_data.player_spawn
	POWER_PELLET_CELLS = map_data.power_pellet_cells.duplicate()
	_active_power_pellet_cells = POWER_PELLET_CELLS.duplicate()
	rival_spawn_cells = map_data.rival_spawns.duplicate()
	_assert_map_is_valid()
	_cache_walkable_cells()
	queue_redraw()


func reset_pellets(start_cell: Vector2i, power_up_count: int = POWER_PELLET_CELLS.size()) -> void:
	_pellets.clear()
	_effects.clear()
	_active_power_pellet_cells.clear()
	var selected_count := mini(power_up_count, POWER_PELLET_CELLS.size())
	for index in selected_count:
		var selected_index := mini(index * POWER_PELLET_CELLS.size() / maxi(selected_count, 1), POWER_PELLET_CELLS.size() - 1)
		_active_power_pellet_cells.append(POWER_PELLET_CELLS[selected_index])
	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			if is_walkable(cell) and cell != start_cell:
				_pellets[cell] = POWER_PELLET_POINTS if cell in _active_power_pellet_cells else PELLET_POINTS
	queue_redraw()


func reset_hell() -> void:
	_pellets.clear()
	_active_power_pellet_cells.clear()
	_effects.clear()
	queue_redraw()


func collect_pellet(cell: Vector2i) -> bool:
	if not _pellets.has(cell):
		return false
	var points := int(_pellets[cell])
	_pellets.erase(cell)
	_spawn_collect_effect(cell, points == POWER_PELLET_POINTS)
	pellet_collected.emit(points)
	if points == POWER_PELLET_POINTS:
		power_pellet_collected.emit()
	if _pellets.is_empty():
		level_completed.emit()
	queue_redraw()
	return true


func pellets_remaining() -> int:
	return _pellets.size()


func _spawn_collect_effect(cell: Vector2i, is_power: bool) -> void:
	var data := _cosmetic_data("effects")
	if not bool(data.get("burst", false)):
		return
	var palette := _cosmetic_palette("effects")
	var ring_color: Color = palette.get("ring", palette.get("burst", DOT_COLOR))
	var particle_color: Color = palette.get("burst", ring_color)
	_effects.append({
		"position": cell_to_position(cell),
		"age": 0.0,
		"duration": 0.45 if is_power else 0.3,
		"radius": 18.0 if is_power else 11.0,
		"color": ring_color,
		"particle_color": particle_color,
		"particles": bool(data.get("particles", false)),
	})
	if _effects.size() > 32:
		_effects.pop_front()


func cell_to_position(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size


func is_walkable(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= MAP.size():
		return false
	if cell.x < 0 or cell.x >= MAP[cell.y].length():
		return false
	return MAP[cell.y].substr(cell.x, 1) != "#"


func is_valid_spawn_cell(cell: Vector2i) -> bool:
	if not is_walkable(cell):
		return false
	for direction in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		if is_walkable(_wrapped_cell(cell + direction)):
			return true
	return false


func get_spawn_cells() -> Array[Vector2i]:
	var spawn_cells: Array[Vector2i] = []
	for cell in _walkable_cells:
		if is_valid_spawn_cell(cell):
			spawn_cells.append(cell)
	return spawn_cells


func get_random_safe_spawn_cell(occupied_cells: Array[Vector2i] = [], min_distance: int = GameLimits.MIN_RESPAWN_DISTANCE, rng: RandomNumberGenerator = null) -> Vector2i:
	var candidates := get_spawn_cells()
	if candidates.is_empty():
		return Vector2i(1, 1)
	var random := rng
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()
	var start_index := random.randi_range(0, candidates.size() - 1)
	for offset in candidates.size():
		var candidate := candidates[(start_index + offset) % candidates.size()]
		if _is_safe_spawn(candidate, occupied_cells, min_distance):
			return candidate
	return _fallback_spawn_cell(candidates, occupied_cells)


func _draw() -> void:
	var wall_color: Color = HELL_WALL_COLOR
	var edge_color: Color = HELL_EDGE_COLOR
	var floor_color: Color = HELL_FLOOR_COLOR
	if not hell_mode:
		var palette := _cosmetic_palette("maze")
		wall_color = palette.get("wall", WALL_COLOR)
		edge_color = palette.get("edge", WALL_EDGE_COLOR)
		floor_color = palette.get("floor", FLOOR_COLOR)
	var pellet_palette := _cosmetic_palette("pellets")
	var pellet_data := _cosmetic_data("pellets")
	var pellet_color: Color = pellet_palette.get("pellet", DOT_COLOR)
	var power_color: Color = pellet_palette.get("power", DOT_COLOR)
	var map_size := Vector2(MAP[0].length(), MAP.size()) * tile_size
	draw_rect(Rect2(origin - Vector2(5.0, 5.0), map_size + Vector2(10.0, 10.0)), floor_color)

	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(cell) * tile_size, Vector2.ONE * tile_size)
			if not is_walkable(cell):
				draw_rect(rect.grow(-1.5), wall_color)
				draw_rect(rect.grow(-3.5), edge_color, false, 1.0)
				if hell_mode:
					_draw_hell_flames(rect, cell)
			elif _pellets.has(cell):
				var is_power := int(_pellets[cell]) == POWER_PELLET_POINTS
				var radius := 2.8 if is_power else 1.2
				var position := cell_to_position(cell)
				draw_circle(position, radius, power_color if is_power else pellet_color)
				if is_power and bool(pellet_data.get("power_ring", false)):
					draw_arc(position, radius + 2.0, 0.0, TAU, 16, power_color, 1.0, true)

	for effect in _effects:
		var progress := float(effect["age"]) / float(effect["duration"])
		var color: Color = effect["color"]
		color.a = 1.0 - progress
		var effect_position: Vector2 = effect["position"]
		var radius := lerpf(3.0, float(effect["radius"]), progress)
		draw_arc(effect_position, radius, 0.0, TAU, 24, color, 2.0, true)
		if bool(effect["particles"]):
			var particle_color: Color = effect["particle_color"]
			particle_color.a = (1.0 - progress) * 0.9
			for index in 6:
				var angle := TAU * float(index) / 6.0 + progress * 1.5
				var point := effect_position + Vector2(cos(angle), sin(angle)) * radius
				draw_circle(point, 1.6 * (1.0 - progress), particle_color)


func _draw_hell_flames(rect: Rect2, cell: Vector2i) -> void:
	var seed := (cell.x * 13 + cell.y * 7) % 6
	for index in 3:
		var x := rect.position.x + 3.0 + fmod(float(seed) * 2.7 + float(index) * 4.3, maxf(rect.size.x - 6.0, 1.0))
		var base_y := rect.position.y + rect.size.y - 2.0
		var height := 2.0 + float((seed + index) % 3)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 1.6, base_y),
			Vector2(x, base_y - height),
			Vector2(x + 1.6, base_y),
		]), HELL_FLAME_COLOR)
		draw_circle(Vector2(x, base_y - height * 0.55), 0.8, HELL_FLAME_CORE_COLOR)


func _assert_map_is_valid() -> void:
	var width := MAP[0].length()
	for row in MAP:
		assert(row.length() == width, "Todas las filas del laberinto deben tener la misma anchura")


func _cache_walkable_cells() -> void:
	_walkable_cells.clear()
	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			if is_walkable(cell):
				_walkable_cells.append(cell)


func _is_safe_spawn(candidate: Vector2i, occupied_cells: Array[Vector2i], min_distance: int) -> bool:
	for occupied_cell in occupied_cells:
		if _wrapped_manhattan_distance(candidate, occupied_cell) < min_distance:
			return false
	return true


func _fallback_spawn_cell(candidates: Array[Vector2i], occupied_cells: Array[Vector2i]) -> Vector2i:
	var best_cell := candidates[0]
	var best_distance := -1
	for candidate in candidates:
		var nearest_distance := 999999
		for occupied_cell in occupied_cells:
			nearest_distance = mini(nearest_distance, _wrapped_manhattan_distance(candidate, occupied_cell))
		if occupied_cells.is_empty():
			return candidate
		if nearest_distance > best_distance:
			best_distance = nearest_distance
			best_cell = candidate
	return best_cell


func _wrapped_cell(cell: Vector2i) -> Vector2i:
	var result := cell
	result.x = wrapi(result.x, 0, MAP[0].length())
	return result


func _wrapped_manhattan_distance(first: Vector2i, second: Vector2i) -> int:
	var horizontal_distance := absi(first.x - second.x)
	var width := MAP[0].length()
	horizontal_distance = mini(horizontal_distance, width - horizontal_distance)
	return horizontal_distance + absi(first.y - second.y)


func _cosmetic_palette(category: String) -> Dictionary:
	var manager := get_node_or_null("/root/UnlockManager")
	if manager == null:
		return {}
	var result: Dictionary = manager.call("get_palette", category)
	return result


func _cosmetic_data(category: String) -> Dictionary:
	var manager := get_node_or_null("/root/UnlockManager")
	if manager == null:
		return {}
	var result: Dictionary = manager.call("get_data", category)
	return result
