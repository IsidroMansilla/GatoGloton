class_name MazeCatalog
extends RefCounted

const MAP_IDS: Array[String] = [
	"map_01", "map_02", "map_03", "map_04", "map_05",
	"map_06", "map_07", "map_08", "map_09", "map_10",
]


static func get_map(map_id: String, level_number: int = 15) -> MazeData:
	var dimensions := _dimensions_for_level(level_number)
	var variant := maxi(MAP_IDS.find(map_id), 0)
	var rows := _build_maze(dimensions.x, dimensions.y, level_number, variant)
	var walkable_cells := _get_walkable_cells(rows)
	var player_spawn := Vector2i(1, 1)
	var rival_spawn := _farthest_cell(walkable_cells, player_spawn)
	var power_cells := _select_power_cells(walkable_cells, player_spawn, rival_spawn)
	var map := MazeData.new()
	return map.configure(
		map_id,
		rows,
		player_spawn,
		[rival_spawn],
		power_cells,
		1 if dimensions.x <= 17 else (2 if dimensions.x <= 21 else 3),
	)


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	for level in range(1, 31):
		var map_id := MAP_IDS[(level - 1) % MAP_IDS.size()]
		for error in get_map(map_id, level).validate():
			errors.append("Nivel %02d %s: %s" % [level, map_id, error])
	return errors


static func _dimensions_for_level(level_number: int) -> Vector2i:
	var clamped_level := clampi(level_number, 1, 30)
	var width := 13 + int(roundf(float(clamped_level - 1) * 12.0 / 29.0))
	var height := 11 + int(roundf(float(clamped_level - 1) * 10.0 / 29.0))
	if width % 2 == 0:
		width += 1
	if height % 2 == 0:
		height += 1
	return Vector2i(mini(width, MazeData.MAX_WIDTH), mini(height, MazeData.MAX_HEIGHT))


static func _build_maze(width: int, height: int, level_number: int, variant: int) -> Array[String]:
	var grid: Array = []
	for y in height:
		var row: Array[String] = []
		for x in width:
			row.append("#")
		grid.append(row)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * level_number + 104729 * variant + 17
	var stack: Array[Vector2i] = [Vector2i(1, 1)]
	grid[1][1] = "."
	while not stack.is_empty():
		var current: Vector2i = stack[stack.size() - 1]
		var candidates: Array[Vector2i] = []
		for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
			var next_cell := current + direction * 2
			if next_cell.x > 0 and next_cell.x < width - 1 and next_cell.y > 0 and next_cell.y < height - 1 and grid[next_cell.y][next_cell.x] == "#":
				candidates.append(direction)
		if candidates.is_empty():
			stack.pop_back()
			continue
		var direction: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		var next_cell := current + direction * 2
		grid[current.y + direction.y][current.x + direction.x] = "."
		grid[next_cell.y][next_cell.x] = "."
		stack.append(next_cell)

	# Early levels receive more shortcuts; later levels preserve the winding maze.
	var shortcut_count := maxi(2, int(roundf(18.0 - float(level_number - 1) * 16.0 / 29.0)))
	var wall_candidates: Array[Vector2i] = []
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if grid[y][x] != "#":
				continue
			var horizontal_gap: bool = grid[y][x - 1] == "." and grid[y][x + 1] == "."
			var vertical_gap: bool = grid[y - 1][x] == "." and grid[y + 1][x] == "."
			if horizontal_gap or vertical_gap:
				wall_candidates.append(Vector2i(x, y))
	for index in shortcut_count:
		if wall_candidates.is_empty():
			break
		var candidate_index := rng.randi_range(0, wall_candidates.size() - 1)
		var shortcut: Vector2i = wall_candidates[candidate_index]
		grid[shortcut.y][shortcut.x] = "."
		wall_candidates.remove_at(candidate_index)

	var rows: Array[String] = []
	for row: Array in grid:
		rows.append(String("").join(row))
	return rows


static func _get_walkable_cells(rows: Array[String]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y].substr(x, 1) == ".":
				cells.append(Vector2i(x, y))
	return cells


static func _farthest_cell(cells: Array[Vector2i], origin: Vector2i) -> Vector2i:
	var result := origin
	var best_distance := -1
	for cell in cells:
		var distance := absi(cell.x - origin.x) + absi(cell.y - origin.y)
		if distance > best_distance:
			best_distance = distance
			result = cell
	return result


static func _select_power_cells(cells: Array[Vector2i], player_spawn: Vector2i, rival_spawn: Vector2i) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for cell in cells:
		if cell != player_spawn and cell != rival_spawn:
			candidates.append(cell)
	var result: Array[Vector2i] = []
	while result.size() < 3 and not candidates.is_empty():
		var best_cell := candidates[0]
		var best_distance := -1
		for candidate in candidates:
			var distance := absi(candidate.x - player_spawn.x) + absi(candidate.y - player_spawn.y)
			for selected in result:
				distance += absi(candidate.x - selected.x) + absi(candidate.y - selected.y)
			if distance > best_distance:
				best_distance = distance
				best_cell = candidate
		result.append(best_cell)
		candidates.erase(best_cell)
	return result
