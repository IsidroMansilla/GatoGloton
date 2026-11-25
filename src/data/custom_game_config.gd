class_name CustomGameConfig
extends Resource

@export_range(1, 30, 1) var level_number: int = 1
@export_range(GameLimits.MIN_PLAYER_SPEED, GameLimits.MAX_PLAYER_SPEED, 1.0) var player_speed: float = 72.0
@export_range(GameLimits.MIN_RIVAL_SPEED, GameLimits.MAX_RIVAL_SPEED, 1.0) var rival_speed: float = 54.0
@export_range(GameLimits.MIN_RIVAL_COUNT, GameLimits.MAX_RIVAL_COUNT, 1) var rival_count: int = 1
@export_range(GameLimits.MIN_MAP_DIFFICULTY, GameLimits.MAX_MAP_DIFFICULTY, 0.05) var map_difficulty: float = 0.0
@export_range(GameLimits.MIN_POWER_UP_COUNT, GameLimits.MAX_POWER_UP_COUNT, 1) var power_up_count: int = 1


func validate() -> PackedStringArray:
	var config := LevelConfig.new()
	config.level_number = level_number
	config.player_speed = player_speed
	config.rival_speed = rival_speed
	config.rival_count = rival_count
	config.map_difficulty = map_difficulty
	config.power_up_count = power_up_count
	return config.validate()
