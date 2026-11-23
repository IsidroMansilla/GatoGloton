class_name Player
extends Node2D

signal hit_received

const MOVE_SPEED: float = 72.0
const INPUT_BUFFER_SECONDS: float = 0.15

var maze: Maze
var cell: Vector2i = Vector2i(1, 1)
var direction: Vector2i = Vector2i.RIGHT
var queued_direction: Vector2i = Vector2i.RIGHT
var target_position: Vector2
var moving: bool = false
var movement_enabled: bool = true
var _buffer_time_left: float = 0.0


func configure(world: Maze, start_cell: Vector2i = Vector2i(1, 1)) -> void:
	maze = world
	cell = start_cell
	movement_enabled = true
	global_position = maze.cell_to_position(cell)
	target_position = global_position
	queue_redraw()


func respawn(start_cell: Vector2i = Vector2i(1, 1)) -> void:
	if maze == null:
		return
	cell = start_cell
	direction = Vector2i.RIGHT
	queued_direction = Vector2i.RIGHT
	_buffer_time_left = 0.0
	moving = false
	movement_enabled = true
	global_position = maze.cell_to_position(cell)
	target_position = global_position
	queue_redraw()


func receive_hit() -> void:
	if movement_enabled:
		hit_received.emit()


func request_direction(new_direction: Vector2i) -> void:
	if not movement_enabled:
		return
	if new_direction == Vector2i.ZERO:
		return
	if abs(new_direction.x) + abs(new_direction.y) != 1:
		return
	queued_direction = new_direction
	_buffer_time_left = INPUT_BUFFER_SECONDS


func _physics_process(delta: float) -> void:
	if maze == null or not movement_enabled:
		return

	_buffer_time_left = maxf(0.0, _buffer_time_left - delta)

	if not moving:
		_start_next_move()

	if not moving:
		return

	global_position = global_position.move_toward(target_position, MOVE_SPEED * delta)
	if global_position.distance_to(target_position) > 0.01:
		return

	global_position = target_position
	cell += direction
	if cell.x < 0:
		cell.x = maze.MAP[0].length() - 1
	elif cell.x >= maze.MAP[0].length():
		cell.x = 0
	maze.collect_pellet(cell)
	moving = false
	_start_next_move()


func stop_movement() -> void:
	movement_enabled = false
	moving = false


func _start_next_move() -> void:
	if not movement_enabled:
		return
	if _can_move(queued_direction):
		direction = queued_direction
	elif not _can_move(direction):
		return

	var next_cell := cell + direction
	if next_cell.x < 0 or next_cell.x >= maze.MAP[0].length():
		next_cell.x = wrapi(next_cell.x, 0, maze.MAP[0].length())
	target_position = maze.cell_to_position(next_cell)
	moving = true


func _can_move(candidate: Vector2i) -> bool:
	if candidate == Vector2i.ZERO:
		return false
	var next_cell := cell + candidate
	if next_cell.x < 0 or next_cell.x >= maze.MAP[0].length():
		next_cell.x = wrapi(next_cell.x, 0, maze.MAP[0].length())
	return maze.is_walkable(next_cell)


func _draw() -> void:
	var fur := Color("#F59E0B")
	var ear_inner := Color("#FBBF24")
	draw_circle(Vector2.ZERO, 6.0, fur)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0, -3.0),
		Vector2(-5.0, -9.0),
		Vector2(-1.0, -5.0),
	]), fur)
	draw_colored_polygon(PackedVector2Array([
		Vector2(5.0, -3.0),
		Vector2(5.0, -9.0),
		Vector2(1.0, -5.0),
	]), fur)
	draw_circle(Vector2(-2.2, -1.0), 1.0, Color("#111827"))
	draw_circle(Vector2(2.2, -1.0), 1.0, Color("#111827"))
	draw_circle(Vector2(0.0, 2.0), 1.0, ear_inner)
