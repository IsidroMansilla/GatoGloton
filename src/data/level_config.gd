class_name LevelConfig
extends Resource

@export_range(1, 30, 1) var level_number: int = 1
@export var map_id: String = "map_01"
@export_range(GameLimits.MIN_PLAYER_SPEED, GameLimits.MAX_PLAYER_SPEED, 1.0) var player_speed: float = 72.0
@export_range(GameLimits.MIN_RIVAL_SPEED, GameLimits.MAX_RIVAL_SPEED, 1.0) var rival_speed: float = 54.0
@export_range(GameLimits.MIN_RIVAL_COUNT, GameLimits.MAX_RIVAL_COUNT, 1) var rival_count: int = 1
@export_range(GameLimits.MIN_MAP_DIFFICULTY, GameLimits.MAX_MAP_DIFFICULTY, 0.05) var map_difficulty: float = 0.0
@export_range(GameLimits.MIN_MAP_SIZE_TIER, GameLimits.MAX_MAP_SIZE_TIER, 1) var map_size_tier: int = 1
@export_range(GameLimits.MIN_POWER_UP_COUNT, GameLimits.MAX_POWER_UP_COUNT, 1) var power_up_count: int = 1
@export_range(GameLimits.MIN_RESPAWN_DISTANCE, GameLimits.MAX_RESPAWN_DISTANCE, 1) var respawn_distance: int = 4


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if level_number < 1 or level_number > 30:
		errors.append("level_number debe estar entre 1 y 30")
	if map_id.is_empty():
		errors.append("map_id no puede estar vacio")
	if player_speed < GameLimits.MIN_PLAYER_SPEED or player_speed > GameLimits.MAX_PLAYER_SPEED:
		errors.append("player_speed esta fuera de los limites")
	if rival_speed < GameLimits.MIN_RIVAL_SPEED or rival_speed > GameLimits.MAX_RIVAL_SPEED:
		errors.append("rival_speed esta fuera de los limites")
	if rival_count < GameLimits.MIN_RIVAL_COUNT or rival_count > GameLimits.MAX_RIVAL_COUNT:
		errors.append("rival_count esta fuera de los limites")
	if map_difficulty < GameLimits.MIN_MAP_DIFFICULTY or map_difficulty > GameLimits.MAX_MAP_DIFFICULTY:
		errors.append("map_difficulty esta fuera de los limites")
	if map_size_tier < GameLimits.MIN_MAP_SIZE_TIER or map_size_tier > GameLimits.MAX_MAP_SIZE_TIER:
		errors.append("map_size_tier esta fuera de los limites")
	if power_up_count < GameLimits.MIN_POWER_UP_COUNT or power_up_count > GameLimits.MAX_POWER_UP_COUNT:
		errors.append("power_up_count esta fuera de los limites")
	if respawn_distance < GameLimits.MIN_RESPAWN_DISTANCE or respawn_distance > GameLimits.MAX_RESPAWN_DISTANCE:
		errors.append("respawn_distance esta fuera de los limites")
	return errors


func is_valid() -> bool:
	return validate().is_empty()
