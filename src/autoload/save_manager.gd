extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 4
const MIN_SUPPORTED_VERSION := 1
const STAT_KEYS: PackedStringArray = [
	"runs_started",
	"runs_finished",
	"runs_won",
	"levels_completed",
	"levels_completed_no_damage",
	"pellets_collected",
	"power_pellets_collected",
	"rivals_eaten",
	"lives_lost",
]
const DEFAULT_COSMETICS: Dictionary = {
	"player": "player_ember",
	"rival": "rival_rose",
	"maze": "maze_classic",
	"pellets": "pellets_classic",
	"effects": "effects_classic",
	"sfx": "sfx_classic",
	"music": "music_off",
}
const DEFAULT_SETTINGS: Dictionary = {
	"muted": false,
	"music_volume_db": -6.0,
	"sfx_volume_db": -3.0,
	"vibration": true,
	"reduce_motion": false,
	"tutorial_seen": false,
}

signal high_score_changed(value: int)
signal highest_level_changed(value: int)
signal stats_changed(stats: Dictionary)
signal custom_config_changed(config: Dictionary)
signal settings_changed(settings: Dictionary)
signal progress_reset
signal save_failed(path: String)

var high_score: int = 0
var highest_level: int = 1
var stats: Dictionary = {}
var achievements: Dictionary = {}
var unlocks: Dictionary = {}
var cosmetics: Dictionary = {}
var last_custom_config: Dictionary = {}
var hell_best_times: Dictionary = {}
var settings: Dictionary = {}
var save_path: String = SAVE_PATH


func _init() -> void:
	_reset_to_defaults()


func _ready() -> void:
	load_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		flush()


func record_score(value: int) -> void:
	if value <= high_score:
		return
	high_score = value
	high_score_changed.emit(high_score)
	save_game()


func record_level(value: int) -> void:
	if value <= highest_level:
		return
	highest_level = value
	highest_level_changed.emit(highest_level)
	save_game()


func record_run_started(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("runs_started")
	save_game()


func record_run_finished(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("runs_finished")
	save_game()


func record_run_won(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("runs_won")
	save_game()


func record_level_completed(is_custom: bool = false, no_damage: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("levels_completed")
	if no_damage:
		_increment_stat("levels_completed_no_damage")
	save_game()


func record_pellet_collected(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("pellets_collected")


func record_power_pellet_collected(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("power_pellets_collected")


func record_rival_eaten(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("rivals_eaten")


func record_life_lost(is_custom: bool = false) -> void:
	if is_custom:
		return
	_increment_stat("lives_lost")
	save_game()


func record_custom_config(config: CustomGameConfig) -> void:
	if config == null:
		return
	var sanitized := _sanitize_custom_config({
		"level_number": config.level_number,
		"player_speed": config.player_speed,
		"rival_speed": config.rival_speed,
		"rival_count": config.rival_count,
		"map_difficulty": config.map_difficulty,
		"power_up_count": config.power_up_count,
	})
	if sanitized.is_empty():
		return
	last_custom_config = sanitized
	custom_config_changed.emit(last_custom_config.duplicate(true))
	save_game()


func has_custom_config() -> bool:
	return not last_custom_config.is_empty()


func get_last_custom_config() -> Dictionary:
	return last_custom_config.duplicate(true)


func get_settings() -> Dictionary:
	return settings.duplicate(true)


func get_setting(key: String, fallback: Variant = null) -> Variant:
	return settings.get(key, fallback)


func set_setting(key: String, value: Variant, persist: bool = true) -> void:
	if not DEFAULT_SETTINGS.has(key):
		return
	var sanitized := _sanitize_settings({key: value})
	settings[key] = sanitized[key]
	settings_changed.emit(get_settings())
	if persist:
		save_game()


func reset_progress() -> void:
	high_score = 0
	highest_level = 1
	stats = _default_stats()
	achievements = {}
	unlocks = {}
	cosmetics = DEFAULT_COSMETICS.duplicate(true)
	last_custom_config = {}
	hell_best_times = {}
	save_game()
	high_score_changed.emit(high_score)
	highest_level_changed.emit(highest_level)
	stats_changed.emit(get_stats())
	progress_reset.emit()


func has_completed_normal_game() -> bool:
	return int(stats.get("runs_won", 0)) > 0


func get_hell_best_time(level_number: int) -> float:
	return float(hell_best_times.get(str(level_number), 0.0))


func record_hell_time(level_number: int, seconds: float) -> bool:
	if level_number < 1 or level_number > 30 or seconds <= 0.0:
		return false
	var key := str(level_number)
	var previous := float(hell_best_times.get(key, 0.0))
	if seconds <= previous:
		return false
	hell_best_times[key] = seconds
	save_game()
	return true


func get_stats() -> Dictionary:
	return stats.duplicate(true)


func get_achievement_progress(id: String) -> int:
	return int(achievements.get(id, 0))


func set_achievement_progress(id: String, value: int, persist: bool = true) -> void:
	if id.is_empty():
		return
	achievements[id] = maxi(0, value)
	if persist:
		save_game()


func get_unlock_state(id: String) -> bool:
	return bool(unlocks.get(id, false))


func set_unlock_state(id: String, unlocked: bool, persist: bool = true) -> void:
	if id.is_empty():
		return
	unlocks[id] = unlocked
	if persist:
		save_game()


func get_cosmetic(slot: String) -> String:
	return String(cosmetics.get(slot, ""))


func set_cosmetic(slot: String, value: String, persist: bool = true) -> void:
	if slot.is_empty() or value.is_empty():
		return
	cosmetics[slot] = value
	if persist:
		save_game()


func get_save_data() -> Dictionary:
	return _build_data()


func load_game(path: String = "") -> bool:
	var target := _resolve_path(path)
	_reset_to_defaults()
	if not FileAccess.file_exists(target):
		return false

	var file := FileAccess.open(target, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir %s" % target)
		return false

	var raw := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(raw)
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("Save corrupto en %s; se ignora" % target)
		_quarantine_corrupt(target)
		return false

	var source := json.data as Dictionary
	var loaded_version := int(source.get("version", MIN_SUPPORTED_VERSION))
	var migrated := _migrate(source)
	if migrated.is_empty():
		return false

	_apply_data(migrated)
	high_score_changed.emit(high_score)
	highest_level_changed.emit(highest_level)
	if loaded_version < SAVE_VERSION:
		save_game(target)
	return true


func save_game(path: String = "") -> bool:
	var target := _resolve_path(path)
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo escribir %s" % target)
		save_failed.emit(target)
		return false

	file.store_string(JSON.stringify(_build_data(), "\t"))
	file.close()
	return true


func flush() -> bool:
	return save_game()


func _resolve_path(path: String) -> String:
	return save_path if path.is_empty() else path


func _build_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"high_score": high_score,
		"highest_level": highest_level,
		"stats": stats.duplicate(true),
		"achievements": achievements.duplicate(true),
		"unlocks": unlocks.duplicate(true),
		"cosmetics": cosmetics.duplicate(true),
		"last_custom_config": last_custom_config.duplicate(true),
		"hell_best_times": hell_best_times.duplicate(true),
		"settings": settings.duplicate(true),
	}


func _reset_to_defaults() -> void:
	high_score = 0
	highest_level = 1
	stats = _default_stats()
	achievements = {}
	unlocks = {}
	cosmetics = DEFAULT_COSMETICS.duplicate(true)
	last_custom_config = {}
	hell_best_times = {}
	settings = DEFAULT_SETTINGS.duplicate(true)


func _default_stats() -> Dictionary:
	var result := {}
	for key in STAT_KEYS:
		result[key] = 0
	return result


func _increment_stat(key: String) -> void:
	stats[key] = int(stats.get(key, 0)) + 1
	stats_changed.emit(get_stats())


func _migrate(data: Dictionary) -> Dictionary:
	var working := data.duplicate(true)
	var version := int(working.get("version", MIN_SUPPORTED_VERSION))
	if version > SAVE_VERSION:
		push_warning("Save de version futura (%d); se ignora" % version)
		return {}
	if version < MIN_SUPPORTED_VERSION:
		version = MIN_SUPPORTED_VERSION
	if version == 1:
		working = _migrate_v1_to_v2(working)
		version = 2
	if version == 2:
		working = _migrate_v2_to_v3(working)
		version = 3
	if version == 3:
		working = _migrate_v3_to_v4(working)
		version = 4
	working["version"] = SAVE_VERSION
	return working


func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result["high_score"] = maxi(0, int(result.get("high_score", 0)))
	result["highest_level"] = maxi(1, int(result.get("highest_level", 1)))
	result["version"] = 2
	return result


func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	var raw_stats: Variant = result.get("stats", {})
	var migrated_stats := _default_stats()
	if typeof(raw_stats) == TYPE_DICTIONARY:
		for key in STAT_KEYS:
			migrated_stats[key] = maxi(0, int((raw_stats as Dictionary).get(key, 0)))
	result["stats"] = migrated_stats
	result["achievements"] = _sanitize_int_dict(result.get("achievements", {}))
	result["unlocks"] = _sanitize_bool_dict(result.get("unlocks", {}))
	result["cosmetics"] = _sanitize_cosmetics(result.get("cosmetics", {}))
	result["last_custom_config"] = _sanitize_custom_config(result.get("last_custom_config", {}))
	result["hell_best_times"] = _sanitize_hell_times(result.get("hell_best_times", {}))
	result["version"] = 3
	return result


func _migrate_v3_to_v4(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result["settings"] = _sanitize_settings(result.get("settings", {}))
	result["version"] = 4
	return result


func _apply_data(data: Dictionary) -> void:
	high_score = maxi(0, int(data.get("high_score", 0)))
	highest_level = maxi(1, int(data.get("highest_level", 1)))
	stats = _default_stats()
	var raw_stats: Variant = data.get("stats", {})
	if typeof(raw_stats) == TYPE_DICTIONARY:
		for key in STAT_KEYS:
			stats[key] = maxi(0, int((raw_stats as Dictionary).get(key, 0)))
	achievements = _sanitize_int_dict(data.get("achievements", {}))
	unlocks = _sanitize_bool_dict(data.get("unlocks", {}))
	cosmetics = _sanitize_cosmetics(data.get("cosmetics", {}))
	last_custom_config = _sanitize_custom_config(data.get("last_custom_config", {}))
	hell_best_times = _sanitize_hell_times(data.get("hell_best_times", {}))
	settings = _sanitize_settings(data.get("settings", {}))


func _sanitize_int_dict(raw: Variant) -> Dictionary:
	var result := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	for key: Variant in (raw as Dictionary).keys():
		result[String(key)] = maxi(0, int((raw as Dictionary)[key]))
	return result


func _sanitize_bool_dict(raw: Variant) -> Dictionary:
	var result := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	for key: Variant in (raw as Dictionary).keys():
		result[String(key)] = bool((raw as Dictionary)[key])
	return result


func _sanitize_cosmetics(raw: Variant) -> Dictionary:
	var result := DEFAULT_COSMETICS.duplicate(true)
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	for slot: Variant in (raw as Dictionary).keys():
		var key := String(slot)
		if not result.has(key):
			continue
		var value: Variant = (raw as Dictionary)[slot]
		if typeof(value) == TYPE_STRING and not String(value).is_empty():
			result[key] = value
	return result


func _sanitize_custom_config(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = raw
	if data.is_empty():
		return {}
	return {
		"level_number": clampi(int(data.get("level_number", 1)), 1, 30),
		"player_speed": clampf(float(data.get("player_speed", 72.0)), GameLimits.MIN_PLAYER_SPEED, GameLimits.MAX_PLAYER_SPEED),
		"rival_speed": clampf(float(data.get("rival_speed", 54.0)), GameLimits.MIN_RIVAL_SPEED, GameLimits.MAX_RIVAL_SPEED),
		"rival_count": clampi(int(data.get("rival_count", 1)), GameLimits.MIN_RIVAL_COUNT, GameLimits.MAX_RIVAL_COUNT),
		"map_difficulty": clampf(float(data.get("map_difficulty", 0.0)), GameLimits.MIN_MAP_DIFFICULTY, GameLimits.MAX_MAP_DIFFICULTY),
		"power_up_count": clampi(int(data.get("power_up_count", 1)), GameLimits.MIN_POWER_UP_COUNT, GameLimits.MAX_POWER_UP_COUNT),
	}


func _sanitize_hell_times(raw: Variant) -> Dictionary:
	var result := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	for key: Variant in (raw as Dictionary).keys():
		var level_number := int(key)
		if level_number < 1 or level_number > 30:
			continue
		var seconds := float((raw as Dictionary)[key])
		if seconds > 0.0:
			result[str(level_number)] = seconds
	return result


func _sanitize_settings(raw: Variant) -> Dictionary:
	var result := DEFAULT_SETTINGS.duplicate(true)
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = raw
	for key: Variant in data.keys():
		var name := String(key)
		if not result.has(name):
			continue
		var value: Variant = data[key]
		if typeof(value) == TYPE_BOOL:
			result[name] = value
		elif typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			match name:
				"muted", "vibration", "reduce_motion", "tutorial_seen":
					result[name] = float(value) != 0.0
				"music_volume_db", "sfx_volume_db":
					result[name] = clampf(float(value), -40.0, 0.0)
		elif typeof(value) == TYPE_STRING:
			match name:
				"muted", "vibration", "reduce_motion", "tutorial_seen":
					result[name] = String(value).to_lower() in ["true", "1", "si"]
				"music_volume_db", "sfx_volume_db":
					result[name] = clampf(String(value).to_float(), -40.0, 0.0)
	return result


func _quarantine_corrupt(target: String) -> void:
	var backup := target + ".corrupt"
	var absolute_target := ProjectSettings.globalize_path(target)
	var absolute_backup := ProjectSettings.globalize_path(backup)
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(absolute_backup)
	var error := DirAccess.rename_absolute(absolute_target, absolute_backup)
	if error != OK:
		push_warning("No se pudo apartar el save corrupto (%d)" % error)
