class_name LevelCatalog
extends Resource

@export var levels: Array[LevelConfig] = []


func get_level(level_number: int) -> LevelConfig:
	for level in levels:
		if level.level_number == level_number:
			return level
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if levels.size() != 30:
		errors.append("El catalogo debe contener exactamente 30 niveles")
	var expected_level := 1
	for level in levels:
		if level == null:
			errors.append("El catalogo contiene un nivel nulo")
			continue
		for error in level.validate():
			errors.append("Nivel %d: %s" % [level.level_number, error])
		if level.level_number != expected_level:
			errors.append("Se esperaba el nivel %d y se encontro el %d" % [expected_level, level.level_number])
		expected_level += 1
	return errors


func is_valid() -> bool:
	return validate().is_empty()
