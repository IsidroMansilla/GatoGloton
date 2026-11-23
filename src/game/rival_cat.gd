class_name RivalCat
extends Node2D

signal player_caught
signal rival_eaten

enum RivalState { SCATTER, CHASE, FRIGHTENED }

const MOVE_SPEED: float = 54.0
const STATE_DURATION: float = 6.0
const COLLISION_DISTANCE: float = 7.0

var maze: Maze
var player: Player
var spawn_cell: Vector2i = Vector2i(10, 9)
var cell: Vector2i = Vector2i(10, 9)
var direction: Vector2i = Vector2i.LEFT
var target_position: Vector2
var state: RivalState = RivalState.SCATTER
var movement_enabled: bool = true
var _state_time: float = 0.0
var _frightened_time_left: float = 0.0
var _collision_cooldown: float = 0.0


func configure(world: Maze, target_player: Player, start_cell: Vector2i = Vector2i(10, 9)) -> void:
	maze = world
	player = target_player
	spawn_cell = start_cell
	reset_position()


func reset_position() -> void:
	if maze == null:
		return
	cell = spawn_cell
	direction = Vector2i.LEFT
	target_position = maze.cell_to_position(cell)
	global_position = target_position
	state = RivalState.SCATTER
	_state_time = 0.0
	_frightened_time_left = 0.0
	_collision_cooldown = 1.0
	movement_enabled = true
	queue_redraw()


func stop_movement() -> void:
	movement_enabled = false


func set_frightened(duration: float) -> void:
	if not movement_enabled:
		return
	_frightened_time_left = maxf(_frightened_time_left, duration)
	state = RivalState.FRIGHTENED
	_state_time = 0.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if maze == null or player == null or not movement_enabled:
		return

	_state_time += delta
	_collision_cooldown = maxf(0.0, _collision_cooldown - delta)
	if _frightened_time_left > 0.0:
		_frightened_time_left = maxf(0.0, _frightened_time_left - delta)
		if _frightened_time_left <= 0.0:
			state = RivalState.CHASE
			_state_time = 0.0
			queue_redraw()
	elif _state_time >= STATE_DURATION:
		_state_time = 0.0
		state = RivalState.CHASE if state == RivalState.SCATTER else RivalState.SCATTER

	if global_position.distance_to(player.global_position) <= COLLISION_DISTANCE and _collision_cooldown <= 0.0:
		_collision_cooldown = 1.5
		if state == RivalState.FRIGHTENED:
			rival_eaten.emit()
			reset_position()
		else:
			player_caught.emit()

	if global_position.distance_to(target_position) <= 0.01:
		global_position = target_position
		cell = _next_cell(cell, direction)
		_choose_direction()
		target_position = maze.cell_to_position(_next_cell(cell, direction))
		return

	global_position = global_position.move_toward(target_position, MOVE_SPEED * delta)


func _choose_direction() -> void:
	var target := player.cell if state == RivalState.CHASE else Vector2i(19, 17)
	var candidates: Array[Vector2i] = []
	for candidate in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		if candidate == -direction:
			continue
		if maze.is_walkable(_next_cell(cell, candidate)):
			candidates.append(candidate)

	if candidates.is_empty():
		for candidate in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
			if maze.is_walkable(_next_cell(cell, candidate)):
				candidates.append(candidate)
	if candidates.is_empty():
		return

	var best_direction := candidates[0]
	var best_distance := _distance_to_target(_next_cell(cell, best_direction), target)
	for candidate in candidates:
		var distance := _distance_to_target(_next_cell(cell, candidate), target)
		var is_better := distance > best_distance if state == RivalState.FRIGHTENED else distance < best_distance
		if is_better:
			best_direction = candidate
			best_distance = distance
	direction = best_direction


func _next_cell(from_cell: Vector2i, move: Vector2i) -> Vector2i:
	var result := from_cell + move
	if result.x < 0 or result.x >= maze.MAP[0].length():
		result.x = wrapi(result.x, 0, maze.MAP[0].length())
	return result


func _distance_to_target(from_cell: Vector2i, target: Vector2i) -> int:
	return absi(from_cell.x - target.x) + absi(from_cell.y - target.y)


func _draw() -> void:
	var fur := Color("#60A5FA") if state == RivalState.FRIGHTENED else Color("#EC4899")
	var shadow := Color("#BE185D")
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
	draw_line(Vector2(-3.0, 3.0), Vector2(3.0, 3.0), shadow, 1.0)
