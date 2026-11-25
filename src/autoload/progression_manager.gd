extends Node

const LEVEL_CATALOG: LevelCatalog = preload("res://src/data/progression_levels.tres")
const MAX_LEVEL: int = 30

signal level_started(level_number: int, config: LevelConfig)
signal level_completed(level_number: int)


func start_run() -> void:
	GameState.level = 1
	GameState.level_changed.emit(GameState.level)
	SaveManager.record_level(GameState.level)


func get_current_config() -> LevelConfig:
	return LEVEL_CATALOG.get_level(GameState.level)


func start_current_level() -> LevelConfig:
	var config := get_current_config()
	if config == null:
		push_error("No existe configuracion para el nivel %d" % GameState.level)
		return null
	SaveManager.record_level(GameState.level)
	level_started.emit(GameState.level, config)
	return config


func complete_current_level() -> bool:
	level_completed.emit(GameState.level)
	if GameState.level >= MAX_LEVEL:
		return false
	GameState.next_level()
	SaveManager.record_level(GameState.level)
	return true


func is_final_level() -> bool:
	return GameState.level >= MAX_LEVEL
