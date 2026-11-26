extends SceneTree

const SAVE_MANAGER_SCRIPT := preload("res://src/autoload/save_manager.gd")
const TEST_DIR := "user://save_tests"

var passed: int = 0
var failed: int = 0
var _last_failed_path: String = ""
var _uses_quit_after: bool = false


func _initialize() -> void:
	_uses_quit_after = _detect_quit_after()
	await process_frame
	_prepare_dir()
	_test_missing_file()
	_test_round_trip()
	_test_v1_migration()
	_test_v2_migration()
	_test_unversioned_migration()
	_test_corrupt_file()
	_test_future_version()
	_test_invalid_types()
	_test_write_failure()
	_test_custom_config_persistence()
	_test_custom_game_does_not_affect_stats()
	_cleanup_dir()
	for frame in 10:
		await process_frame
	print("Save test: %d passed, %d failed" % [passed, failed])
	if failed > 0 or not _uses_quit_after:
		call_deferred("quit", 1 if failed > 0 else 0)


func _detect_quit_after() -> bool:
	for argument in OS.get_cmdline_args():
		if argument == "--quit-after" or argument.begins_with("--quit-after="):
			return true
	return false


func _test_missing_file() -> void:
	var path := _path("missing.json")
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(not manager.load_game(), "archivo ausente no carga")
	_check(manager.high_score == 0, "archivo ausente deja high_score 0")
	_check(manager.highest_level == 1, "archivo ausente deja highest_level 1")
	_check(manager.get_stats().get("runs_started", -1) == 0, "archivo ausente deja estadisticas a 0")
	_check(not manager.has_custom_config(), "archivo ausente no tiene config personalizada")
	manager.free()


func _test_round_trip() -> void:
	var path := _path("round_trip.json")
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	manager.high_score = 1234
	manager.highest_level = 17
	manager.record_run_started()
	manager.record_run_started()
	manager.record_run_finished()
	manager.record_run_won()
	manager.record_level_completed(false, false)
	manager.record_level_completed(false, true)
	manager.record_pellet_collected()
	manager.record_power_pellet_collected()
	manager.record_rival_eaten()
	manager.record_life_lost()
	manager.set_achievement_progress("level_10", 3)
	manager.set_unlock_state("skin_gold", true)
	manager.set_cosmetic("player", "gold")
	var config := CustomGameConfig.new()
	config.level_number = 12
	config.player_speed = 80.0
	config.rival_speed = 60.0
	config.rival_count = 3
	config.map_difficulty = 0.5
	config.power_up_count = 2
	manager.record_custom_config(config)
	_check(manager.record_hell_time(3, 42.5), "round trip registra record infernal")
	_check(not manager.record_hell_time(3, 10.0), "record inferior no reemplaza")
	manager.free()

	_check(FileAccess.file_exists(path), "round trip escribe archivo")
	var loaded := SAVE_MANAGER_SCRIPT.new()
	loaded.save_path = path
	_check(loaded.load_game(), "round trip carga archivo")
	_check(loaded.high_score == 1234, "round trip conserva high_score")
	_check(loaded.highest_level == 17, "round trip conserva highest_level")
	var loaded_stats := loaded.get_stats()
	_check(loaded_stats.get("runs_started", -1) == 2, "round trip conserva runs_started")
	_check(loaded_stats.get("runs_finished", -1) == 1, "round trip conserva runs_finished")
	_check(loaded_stats.get("runs_won", -1) == 1, "round trip conserva runs_won")
	_check(loaded_stats.get("levels_completed", -1) == 2, "round trip conserva levels_completed")
	_check(loaded_stats.get("levels_completed_no_damage", -1) == 1, "round trip conserva niveles sin dano")
	_check(loaded_stats.get("pellets_collected", -1) == 1, "round trip conserva pellets")
	_check(loaded_stats.get("power_pellets_collected", -1) == 1, "round trip conserva power pellets")
	_check(loaded_stats.get("rivals_eaten", -1) == 1, "round trip conserva rivales comidos")
	_check(loaded_stats.get("lives_lost", -1) == 1, "round trip conserva vidas perdidas")
	_check(loaded.get_achievement_progress("level_10") == 3, "round trip conserva progreso de logros")
	_check(loaded.get_unlock_state("skin_gold"), "round trip conserva desbloqueos")
	_check(loaded.get_cosmetic("player") == "gold", "round trip conserva cosmeticos")
	_check(loaded.has_custom_config(), "round trip conserva config personalizada")
	var loaded_config := loaded.get_last_custom_config()
	_check(int(loaded_config.get("level_number", 0)) == 12, "round trip conserva nivel personalizado")
	_check(is_equal_approx(float(loaded_config.get("player_speed", 0.0)), 80.0), "round trip conserva velocidad del jugador")
	_check(is_equal_approx(float(loaded_config.get("rival_speed", 0.0)), 60.0), "round trip conserva velocidad rival")
	_check(int(loaded_config.get("rival_count", 0)) == 3, "round trip conserva numero de rivales")
	_check(is_equal_approx(float(loaded_config.get("map_difficulty", 0.0)), 0.5), "round trip conserva dificultad")
	_check(int(loaded_config.get("power_up_count", 0)) == 2, "round trip conserva power-ups")
	_check(is_equal_approx(loaded.get_hell_best_time(3), 42.5), "round trip conserva record infernal")
	_check(is_equal_approx(loaded.get_hell_best_time(4), 0.0), "niveles sin record infernal empiezan a 0")
	_check(loaded.has_completed_normal_game(), "detecta partida normal completada")
	_check(int(loaded.get_save_data().get("version", 0)) == 3, "round trip guarda version 3")
	loaded.free()


func _test_v1_migration() -> void:
	var path := _path("v1.json")
	_write_raw(path, JSON.stringify({
		"version": 1,
		"high_score": 500,
		"highest_level": 7,
		"legacy_field": "ignorado",
	}))
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(manager.load_game(), "v1 se carga")
	_check(manager.high_score == 500, "v1 conserva high_score")
	_check(manager.highest_level == 7, "v1 conserva highest_level")
	_check(manager.get_stats().get("runs_started", -1) == 0, "v1 crea estadisticas por defecto")
	_check(manager.get_cosmetic("player") == "player_ember", "v1 crea cosmeticos por defecto")
	_check(is_equal_approx(manager.get_hell_best_time(1), 0.0), "v1 crea records infernales por defecto")
	_check(int(manager.get_save_data().get("version", 0)) == 3, "v1 migra a version 3")
	var persisted := _read_json(path)
	_check(int(persisted.get("version", 0)) == 3, "v1 migrado se persiste en disco")
	_check(int(persisted.get("high_score", 0)) == 500, "v1 migrado conserva high_score en disco")
	_check(manager.save_game(), "v1 migrado se puede guardar")
	manager.free()


func _test_v2_migration() -> void:
	var path := _path("v2.json")
	_write_raw(path, JSON.stringify({
		"version": 2,
		"high_score": 800,
		"highest_level": 12,
	}))
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(manager.load_game(), "v2 se carga")
	_check(manager.high_score == 800, "v2 conserva high_score")
	_check(manager.highest_level == 12, "v2 conserva highest_level")
	_check(manager.get_stats().get("runs_won", -1) == 0, "v2 crea estadisticas por defecto")
	_check(manager.get_stats().size() == 9, "v2 crea las 9 estadisticas")
	_check(int(manager.get_save_data().get("version", 0)) == 3, "v2 migra a version 3")
	manager.free()


func _test_unversioned_migration() -> void:
	var path := _path("unversioned.json")
	_write_raw(path, JSON.stringify({
		"high_score": 250,
		"highest_level": 4,
	}))
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(manager.load_game(), "save sin version se carga como v1")
	_check(manager.high_score == 250, "save sin version conserva high_score")
	_check(manager.highest_level == 4, "save sin version conserva highest_level")
	_check(int(manager.get_save_data().get("version", 0)) == 3, "save sin version migra a version 3")
	manager.free()


func _test_corrupt_file() -> void:
	var path := _path("corrupt.json")
	_write_raw(path, "{ esto no es json")
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(not manager.load_game(), "save corrupto no carga")
	_check(manager.high_score == 0, "save corrupto deja high_score 0")
	_check(manager.highest_level == 1, "save corrupto deja highest_level 1")
	_check(not FileAccess.file_exists(path), "save corrupto se aparta")
	_check(FileAccess.file_exists(path + ".corrupt"), "save corrupto queda en cuarentena")
	manager.free()


func _test_future_version() -> void:
	var path := _path("future.json")
	_write_raw(path, JSON.stringify({
		"version": 99,
		"high_score": 9999,
		"highest_level": 30,
	}))
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(not manager.load_game(), "version futura no carga")
	_check(manager.high_score == 0, "version futura deja high_score 0")
	_check(manager.highest_level == 1, "version futura deja highest_level 1")
	_check(FileAccess.file_exists(path), "version futura no se aparta")
	_check(not FileAccess.file_exists(path + ".corrupt"), "version futura no se marca corrupta")
	manager.free()


func _test_invalid_types() -> void:
	var path := _path("invalid_types.json")
	_write_raw(path, JSON.stringify({
		"version": 3,
		"high_score": "999",
		"highest_level": -5,
		"stats": {
			"runs_started": "4",
			"runs_finished": -2,
			"pellets_collected": 2.9,
		},
		"achievements": "no es diccionario",
		"unlocks": [],
		"cosmetics": {
			"player": 5,
			"rival": "gold",
		},
		"last_custom_config": {
			"level_number": 99,
			"player_speed": 9999.0,
			"rival_speed": -1.0,
			"rival_count": 99,
			"map_difficulty": 2.0,
			"power_up_count": 0,
		},
		"hell_best_times": {
			"3": 12.5,
			"99": 5.0,
			"4": -1.0,
			"x": 2.0,
		},
	}))
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(manager.load_game(), "tipos invalidos se cargan saneados")
	_check(manager.high_score == 999, "high_score numerico en texto se convierte")
	_check(manager.highest_level == 1, "highest_level negativo se corrige")
	var stats := manager.get_stats()
	_check(int(stats.get("runs_started", -1)) == 4, "estadistica en texto se convierte")
	_check(int(stats.get("runs_finished", -1)) == 0, "estadistica negativa se corrige")
	_check(int(stats.get("pellets_collected", -1)) == 2, "estadistica flotante se trunca")
	_check(manager.achievements.is_empty(), "logros invalidos quedan vacios")
	_check(manager.unlocks.is_empty(), "desbloqueos invalidos quedan vacios")
	_check(manager.get_cosmetic("player") == "player_ember", "cosmetico invalido usa default")
	_check(manager.get_cosmetic("rival") == "gold", "cosmetico valido se conserva")
	var config := manager.get_last_custom_config()
	_check(int(config.get("level_number", 0)) == 30, "nivel personalizado se acota")
	_check(is_equal_approx(float(config.get("player_speed", 0.0)), GameLimits.MAX_PLAYER_SPEED), "velocidad alta se acota")
	_check(is_equal_approx(float(config.get("rival_speed", 0.0)), GameLimits.MIN_RIVAL_SPEED), "velocidad baja se acota")
	_check(int(config.get("rival_count", 0)) == GameLimits.MAX_RIVAL_COUNT, "rivales altos se acotan")
	_check(is_equal_approx(float(config.get("map_difficulty", 0.0)), GameLimits.MAX_MAP_DIFFICULTY), "dificultad alta se acota")
	_check(int(config.get("power_up_count", 0)) == GameLimits.MIN_POWER_UP_COUNT, "power-ups bajos se acotan")
	_check(is_equal_approx(manager.get_hell_best_time(3), 12.5), "record infernal valido se conserva")
	_check(is_equal_approx(manager.get_hell_best_time(4), 0.0), "record infernal negativo se descarta")
	_check(is_equal_approx(manager.get_hell_best_time(99), 0.0), "record infernal fuera de rango se descarta")
	manager.free()


func _test_write_failure() -> void:
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = "user://gatogloton_missing_%d/save.json" % Time.get_ticks_usec()
	_last_failed_path = ""
	manager.save_failed.connect(_on_save_failed)
	_check(not manager.save_game(), "escritura fallida devuelve false")
	_check(_last_failed_path == manager.save_path, "escritura fallida emite save_failed")
	manager.free()


func _test_custom_config_persistence() -> void:
	var path := _path("custom_config.json")
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	_check(not manager.has_custom_config(), "config personalizada empieza vacia")
	var config := CustomGameConfig.new()
	config.level_number = 8
	config.player_speed = 75.0
	config.rival_speed = 50.0
	config.rival_count = 2
	config.map_difficulty = 0.25
	config.power_up_count = 3
	manager.record_custom_config(config)
	_check(manager.has_custom_config(), "config personalizada queda registrada")
	manager.free()

	var loaded := SAVE_MANAGER_SCRIPT.new()
	loaded.save_path = path
	_check(loaded.load_game(), "config personalizada se recarga")
	_check(loaded.has_custom_config(), "config personalizada persiste")
	var loaded_config := loaded.get_last_custom_config()
	_check(int(loaded_config.get("level_number", 0)) == 8, "config persiste nivel")
	_check(int(loaded_config.get("rival_count", 0)) == 2, "config persiste rivales")
	_check(int(loaded_config.get("power_up_count", 0)) == 3, "config persiste power-ups")
	loaded.free()


func _test_custom_game_does_not_affect_stats() -> void:
	var path := _path("custom_guard.json")
	var manager := SAVE_MANAGER_SCRIPT.new()
	manager.save_path = path
	manager.record_run_started(true)
	manager.record_run_finished(true)
	manager.record_run_won(true)
	manager.record_level_completed(true, true)
	manager.record_pellet_collected(true)
	manager.record_power_pellet_collected(true)
	manager.record_rival_eaten(true)
	manager.record_life_lost(true)
	var stats := manager.get_stats()
	for key in stats.keys():
		_check(int(stats[key]) == 0, "partida personalizada no toca %s" % key)
	_check(manager.high_score == 0, "partida personalizada no toca high_score")
	_check(manager.highest_level == 1, "partida personalizada no toca highest_level")
	_check(manager.achievements.is_empty(), "partida personalizada no toca logros")
	_check(manager.unlocks.is_empty(), "partida personalizada no toca desbloqueos")
	_check(not FileAccess.file_exists(path), "partida personalizada no escribe save")
	manager.free()


func _on_save_failed(path: String) -> void:
	_last_failed_path = path


func _prepare_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR + "/" + file))


func _cleanup_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR + "/" + file))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR))


func _path(file_name: String) -> String:
	return TEST_DIR + "/" + file_name


func _write_raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "no se pudo escribir fixture %s" % path)
		return
	file.store_string(text)
	file.close()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(raw) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: %s" % label)
