extends SceneTree


func _initialize() -> void:
	for level in range(1, 31):
		var config := (preload("res://src/data/progression_levels.tres") as LevelCatalog).get_level(level)
		var map := MazeCatalog.get_map(config.map_id, level)
		var errors := map.validate()
		if not errors.is_empty():
			print("Nivel %02d %dx%d %s: %s" % [level, map.rows[0].length(), map.rows.size(), config.map_id, ", ".join(errors)])
	quit()
