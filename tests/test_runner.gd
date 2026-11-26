extends SceneTree

const LEVEL_CATALOG: LevelCatalog = preload("res://src/data/progression_levels.tres")

var passed: int = 0
var failed: int = 0
var _uses_quit_after: bool = false


func _initialize() -> void:
	_uses_quit_after = _detect_quit_after()
	var maze := Maze.new()
	root.add_child(maze)
	await process_frame

	var previous_width := 0
	var previous_height := 0
	for level in range(1, 31):
		_check_level(level, maze, previous_width, previous_height)
		var config := LEVEL_CATALOG.get_level(level)
		var map := MazeCatalog.get_map(config.map_id, level)
		previous_width = map.rows[0].length()
		previous_height = map.rows.size()

	maze.queue_free()
	await process_frame
	print("Automated map test: %d passed, %d failed" % [passed, failed])
	if failed > 0 or not _uses_quit_after:
		call_deferred("quit", 1 if failed > 0 else 0)


func _detect_quit_after() -> bool:
	for argument in OS.get_cmdline_args():
		if argument == "--quit-after" or argument.begins_with("--quit-after="):
			return true
	return false


func _check_level(level_number: int, maze: Maze, previous_width: int, previous_height: int) -> void:
	var config := LEVEL_CATALOG.get_level(level_number)
	_check(config != null, "nivel %02d tiene configuracion" % level_number)
	if config == null:
		return
	_check(config.is_valid(), "nivel %02d respeta limites" % level_number)
	var map := MazeCatalog.get_map(config.map_id, level_number)
	var map_errors := map.validate()
	_check(map_errors.is_empty(), "nivel %02d mapa valido: %s" % [level_number, ", ".join(map_errors)])
	var width := map.rows[0].length()
	var height := map.rows.size()
	_check(width >= previous_width, "nivel %02d no reduce anchura" % level_number)
	_check(height >= previous_height, "nivel %02d no reduce altura" % level_number)
	_check(width >= MazeData.MIN_WIDTH and width <= MazeData.MAX_WIDTH, "nivel %02d anchura acotada" % level_number)
	_check(height >= MazeData.MIN_HEIGHT and height <= MazeData.MAX_HEIGHT, "nivel %02d altura acotada" % level_number)

	maze.configure_map(map)
	maze.reset_pellets(map.player_spawn, config.power_up_count)
	var route := _build_cover_route(map)
	_check(not route.is_empty(), "nivel %02d tiene ruta de cobertura" % level_number)
	_check(_route_is_valid(map, route), "nivel %02d ruta solo usa pasos validos" % level_number)
	for cell in route:
		maze.collect_pellet(cell)
	_check(maze.pellets_remaining() == 0, "nivel %02d se puede completar recogiendo pellets" % level_number)
	maze.reset_hell()
	_check(maze.pellets_remaining() == 0, "nivel %02d no genera pellets en infierno" % level_number)

	var occupied_cells: Array[Vector2i] = [map.player_spawn]
	for rival_index in config.rival_count:
		var spawn := maze.get_random_safe_spawn_cell(occupied_cells, config.respawn_distance)
		_check(spawn not in occupied_cells, "nivel %02d spawn rival %d es unico" % [level_number, rival_index + 1])
		occupied_cells.append(spawn)


func _build_cover_route(map: MazeData) -> Array[Vector2i]:
	var route: Array[Vector2i] = [map.player_spawn]
	var visited: Dictionary = {map.player_spawn: true}
	var stack: Array[Vector2i] = [map.player_spawn]
	while not stack.is_empty():
		var current: Vector2i = stack[stack.size() - 1]
		var next_cell := _first_unvisited_neighbor(map, current, visited)
		if next_cell == Vector2i(-1, -1):
			stack.pop_back()
			if not stack.is_empty():
				route.append(stack[stack.size() - 1])
			continue
		visited[next_cell] = true
		stack.append(next_cell)
		route.append(next_cell)
	return route


func _first_unvisited_neighbor(map: MazeData, cell: Vector2i, visited: Dictionary) -> Vector2i:
	for neighbor: Vector2i in _neighbors(map, cell):
		if map.is_walkable(neighbor) and not visited.has(neighbor):
			return neighbor
	return Vector2i(-1, -1)


func _neighbors(map: MazeData, cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var width := map.rows[0].length()
	for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		var neighbor: Vector2i = cell + direction
		if neighbor.x < 0 or neighbor.x >= width:
			neighbor.x = wrapi(neighbor.x, 0, width)
		result.append(neighbor)
	return result


func _route_is_valid(map: MazeData, route: Array[Vector2i]) -> bool:
	for index in range(1, route.size()):
		if not map.is_walkable(route[index]) or not _neighbors(map, route[index - 1]).has(route[index]):
			return false
	return true


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: %s" % label)
