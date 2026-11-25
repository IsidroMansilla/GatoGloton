class_name MazeData
extends RefCounted

const MIN_WIDTH: int = 13
const MAX_WIDTH: int = 25
const MIN_HEIGHT: int = 11
const MAX_HEIGHT: int = 21

var map_id: String
var rows: Array[String]
var player_spawn: Vector2i
var rival_spawns: Array[Vector2i]
var power_pellet_cells: Array[Vector2i]
var size_tier: int


func configure(id: String, layout: Array[String], player_start: Vector2i, rival_starts: Array[Vector2i], power_cells: Array[Vector2i], tier: int) -> MazeData:
	map_id = id
	rows = layout
	player_spawn = player_start
	rival_spawns = rival_starts
	power_pellet_cells = power_cells
	size_tier = tier
	return self


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if map_id.is_empty():
		errors.append("map_id no puede estar vacio")
	if rows.size() < MIN_HEIGHT or rows.size() > MAX_HEIGHT or rows.size() % 2 == 0:
		errors.append("la altura debe ser impar entre %d y %d" % [MIN_HEIGHT, MAX_HEIGHT])
		return errors
	var width := rows[0].length()
	if width < MIN_WIDTH or width > MAX_WIDTH or width % 2 == 0:
		errors.append("la anchura debe ser impar entre %d y %d" % [MIN_WIDTH, MAX_WIDTH])
	for row in rows:
		if row.length() != width:
			errors.append("todas las filas deben tener la misma anchura")
			break
	if size_tier < GameLimits.MIN_MAP_SIZE_TIER or size_tier > GameLimits.MAX_MAP_SIZE_TIER:
		errors.append("size_tier esta fuera de los limites")
	if not is_walkable(player_spawn):
		errors.append("player_spawn no es transitable")
	for spawn in rival_spawns:
		if not is_walkable(spawn):
			errors.append("rival_spawn %s no es transitable" % spawn)
	for power_cell in power_pellet_cells:
		if not is_walkable(power_cell):
			errors.append("power_pellet %s no es transitable" % power_cell)
	if not _is_connected():
		errors.append("el mapa contiene zonas transitables aisladas")
	if not _has_route_to_every_rival():
		errors.append("el jugador no tiene ruta hasta todos los rivales")
	return errors


func is_walkable(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[0].length():
		return false
	return rows[cell.y].substr(cell.x, 1) != "#"


func _is_connected() -> bool:
	var walkable_cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[0].length():
			var cell := Vector2i(x, y)
			if is_walkable(cell):
				walkable_cells.append(cell)
	var visited: Dictionary = {player_spawn: true}
	var pending: Array[Vector2i] = [player_spawn]
	while not pending.is_empty():
		var current: Vector2i = pending.pop_front()
		for neighbor: Vector2i in _neighbors(current):
			if is_walkable(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				pending.append(neighbor)
	return visited.size() == walkable_cells.size()


func _has_route_to_every_rival() -> bool:
	for rival_spawn in rival_spawns:
		if not _has_route(player_spawn, rival_spawn):
			return false
	return true


func _has_route(start: Vector2i, target: Vector2i) -> bool:
	var visited: Dictionary = {start: true}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var current: Vector2i = pending.pop_front()
		if current == target:
			return true
		for neighbor: Vector2i in _neighbors(current):
			if is_walkable(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				pending.append(neighbor)
	return false


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		var neighbor: Vector2i = cell + direction
		if neighbor.x < 0 or neighbor.x >= rows[0].length():
			neighbor.x = wrapi(neighbor.x, 0, rows[0].length())
		neighbors.append(neighbor)
	return neighbors
