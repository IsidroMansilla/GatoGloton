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
const PELLET_POINTS: int = 10
const POWER_PELLET_POINTS: int = 50
var POWER_PELLET_CELLS: Array[Vector2i] = [Vector2i(19, 1), Vector2i(1, 17), Vector2i(19, 17)]
var _active_power_pellet_cells: Array[Vector2i] = []

var origin: Vector2 = Vector2(12.0, 104.0)
var tile_size: float = TILE_SIZE
var _pellets: Dictionary = {}
var _walkable_cells: Array[Vector2i] = []
var map_id: String = "map_01"
var player_spawn_cell: Vector2i = Vector2i(1, 1)
var rival_spawn_cells: Array[Vector2i] = [Vector2i(10, 9)]


func _ready() -> void:
	_assert_map_is_valid()
	_cache_walkable_cells()
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


func collect_pellet(cell: Vector2i) -> bool:
	if not _pellets.has(cell):
		return false
	var points := int(_pellets[cell])
	_pellets.erase(cell)
	pellet_collected.emit(points)
	if points == POWER_PELLET_POINTS:
		power_pellet_collected.emit()
	if _pellets.is_empty():
		level_completed.emit()
	queue_redraw()
	return true


func pellets_remaining() -> int:
	return _pellets.size()


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
	var map_size := Vector2(MAP[0].length(), MAP.size()) * tile_size
	draw_rect(Rect2(origin - Vector2(5.0, 5.0), map_size + Vector2(10.0, 10.0)), FLOOR_COLOR)

	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(cell) * tile_size, Vector2.ONE * tile_size)
			if not is_walkable(cell):
				draw_rect(rect.grow(-1.5), WALL_COLOR)
				draw_rect(rect.grow(-3.5), WALL_EDGE_COLOR, false, 1.0)
			elif _pellets.has(cell):
				var radius := 2.8 if int(_pellets[cell]) == POWER_PELLET_POINTS else 1.2
				draw_circle(cell_to_position(cell), radius, DOT_COLOR)


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
