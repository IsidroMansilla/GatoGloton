class_name HellRules
extends RefCounted

const LEVEL_COUNT: int = 30
const PLAYER_LIVES: int = 1
const SPAWN_INTERVAL_START: float = 7.0
const SPAWN_INTERVAL_MIN: float = 2.0
const SPAWN_INTERVAL_DECAY: float = 0.25


static func spawn_interval(elapsed: float) -> float:
	return clampf(
		SPAWN_INTERVAL_START - elapsed * SPAWN_INTERVAL_DECAY,
		SPAWN_INTERVAL_MIN,
		SPAWN_INTERVAL_START,
	)


static func format_time(seconds: float) -> String:
	var clamped := maxf(seconds, 0.0)
	var minutes := int(clamped) / 60
	var remaining := int(clamped) % 60
	var tenths := int((clamped - floor(clamped)) * 10.0)
	return "%02d:%02d.%d" % [minutes, remaining, tenths]
