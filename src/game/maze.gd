class_name Maze
extends Node2D

signal pellet_collected(points: int)
signal power_pellet_collected
signal level_completed

const TILE_SIZE: float = 16.0
const MAP: Array[String] = [
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
const POWER_PELLET_CELLS: Array[Vector2i] = [Vector2i(19, 1), Vector2i(1, 17), Vector2i(19, 17)]

var origin: Vector2 = Vector2(12.0, 104.0)
var _pellets: Dictionary = {}


func _ready() -> void:
	_assert_map_is_valid()
	queue_redraw()


func reset_pellets(start_cell: Vector2i) -> void:
	_pellets.clear()
	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			if is_walkable(cell) and cell != start_cell:
				_pellets[cell] = POWER_PELLET_POINTS if cell in POWER_PELLET_CELLS else PELLET_POINTS
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


func cell_to_position(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


func is_walkable(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= MAP.size():
		return false
	if cell.x < 0 or cell.x >= MAP[cell.y].length():
		return false
	return MAP[cell.y].substr(cell.x, 1) != "#"


func _draw() -> void:
	var map_size := Vector2(MAP[0].length(), MAP.size()) * TILE_SIZE
	draw_rect(Rect2(origin - Vector2(5.0, 5.0), map_size + Vector2(10.0, 10.0)), FLOOR_COLOR)

	for y in MAP.size():
		for x in MAP[y].length():
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
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
