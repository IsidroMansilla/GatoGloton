extends Node2D

const LEVEL_CATALOG: LevelCatalog = preload("res://src/data/progression_levels.tres")
const MAZE_CATALOG = preload("res://src/data/maze_catalog.gd")
const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")

@onready var _maze: Maze = $Maze
@onready var _player: Player = $Player
@onready var _rival: RivalDog = $RivalDog
@onready var _status: Label = $UI/Status
@onready var _status_frame: Panel = $UI/StatusFrame
@onready var _pause_button: Button = $UI/PauseButton
@onready var _pause_overlay: Control = $UI/PauseOverlay
@onready var _pause_title: Label = $UI/PauseOverlay/Title
@onready var _pause_message: Label = $UI/PauseOverlay/Message
@onready var _resume_button: Button = $UI/PauseOverlay/ResumeButton
@onready var _restart_button: Button = $UI/PauseOverlay/RestartButton
@onready var _pause_settings_button: Button = $UI/PauseOverlay/SettingsButton
@onready var _menu_button: Button = $UI/PauseOverlay/MenuButton
@onready var _menu: Control = $UI/Menu
@onready var _high_score: Label = $UI/Menu/HighScore
@onready var _start_button: Button = $UI/Menu/StartButton
@onready var _custom_button: Button = $UI/Menu/CustomButton
@onready var _achievements_button: Button = $UI/Menu/AchievementsButton
@onready var _customize_button: Button = $UI/Menu/CustomizeButton
@onready var _settings_button: Button = $UI/Menu/SettingsButton
@onready var _hell_button: Button = $UI/Menu/HellButton

const LEVEL_INTRO_SECONDS: float = 1.2
const LEVEL_READY_AT: float = 0.6
const LEVEL_GRACE_SECONDS: float = 1.0

enum GameMode { MENU, PLAYING, PAUSED, GAME_OVER, LEVEL_CLEAR }
enum InterstitialAction { NONE, NEXT_LEVEL, HELL_RESULTS }
var _mode: GameMode = GameMode.MENU
var _swipe_start: Vector2
var _level_config: LevelConfig
var _rivals: Array[RivalDog] = []
var _continue_used: bool = false
var _waiting_reward: bool = false
var _waiting_interstitial: bool = false
var _interstitial_action: InterstitialAction = InterstitialAction.NONE
var _pending_next_level: int = 0
var _is_custom_game: bool = false
var _is_hell_game: bool = false
var _hell_level: int = 1
var _hell_time: float = 0.0
var _hell_spawn_timer: float = 0.0
var _hell_final_time: float = 0.0
var _hell_new_record: bool = false
var _run_finished_counted: bool = false
var _level_lives_lost: int = 0
var _custom_config: CustomGameConfig
var _custom_panel: Control
var _custom_level: HSlider
var _custom_player_speed: HSlider
var _custom_rival_speed: HSlider
var _custom_rival_count: HSlider
var _custom_difficulty: HSlider
var _custom_power_ups: HSlider
var _custom_value_labels: Dictionary = {}
var _achievements_screen: AchievementsScreen
var _customization_screen: CustomizationScreen
var _hell_screen: HellSelectScreen
var _settings_screen: SettingsScreen
var _tutorial_screen: TutorialScreen
var _settings_from_pause: bool = false
var _intro_label: Label
var _intro_time_left: float = 0.0
var _grace_time_left: float = 0.0
var _toast_panel: Panel
var _toast_label: Label
var _toast_queue: Array[String] = []
var _toast_active: bool = false


func _ready() -> void:
	var catalog_errors := LEVEL_CATALOG.validate()
	for error in catalog_errors:
		push_error("[Main] Error de configuracion: %s" % error)
	for error in MAZE_CATALOG.validate_all():
		push_error("[Main] Error de mapa: %s" % error)
	_level_config = ProgressionManager.get_current_config()
	_rivals.append(_rival)
	_maze.visible = false
	_player.visible = false
	_rival.visible = false
	_menu.visible = true
	_status.visible = false
	_status_frame.visible = false
	_pause_button.visible = false
	_pause_overlay.visible = false
	_start_button.pressed.connect(_start_game)
	_custom_button.pressed.connect(_open_custom_menu)
	_achievements_button.pressed.connect(_open_achievements)
	_customize_button.pressed.connect(_open_customization)
	_settings_button.pressed.connect(_open_settings_from_menu)
	_hell_button.pressed.connect(_open_hell_menu)
	_pause_button.pressed.connect(_toggle_pause)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_restart_button.pressed.connect(_restart_game)
	_pause_settings_button.pressed.connect(_open_settings_from_pause)
	_menu_button.pressed.connect(_return_to_menu)
	SaveManager.progress_reset.connect(_on_progress_reset)
	AdsManager.rewarded_completed.connect(_on_rewarded_completed)
	AdsManager.rewarded_failed.connect(_on_rewarded_failed)
	AdsManager.interstitial_dismissed.connect(_on_interstitial_dismissed)
	_player.hit_received.connect(_on_player_hit)
	_bind_rival(_rival)
	_maze.pellet_collected.connect(_on_pellet_collected)
	_maze.power_pellet_collected.connect(_on_power_pellet_collected)
	_maze.level_completed.connect(_on_level_completed)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	UnlockManager.cosmetic_unlocked.connect(_on_cosmetic_unlocked)
	UnlockManager.cosmetics_changed.connect(_on_cosmetics_changed)
	_high_score.text = "RECORD  %04d\nNIVEL MAXIMO  %02d" % [SaveManager.high_score, SaveManager.highest_level]
	_build_custom_panel()
	_build_progress_screens()
	_build_hell_screen()
	_build_unlock_toast()
	_build_intro_label()
	_setup_safe_area()
	_update_hell_button()
	if not bool(SaveManager.get_setting("tutorial_seen", false)):
		_open_tutorial()


func _process(delta: float) -> void:
	if _mode != GameMode.PLAYING:
		return
	if _intro_time_left > 0.0:
		_intro_time_left = maxf(0.0, _intro_time_left - delta)
		if _intro_label != null:
			var ready := _intro_time_left <= LEVEL_INTRO_SECONDS - LEVEL_READY_AT
			_intro_label.text = "LISTO!" if ready else "NIVEL %02d" % GameState.level
		if _intro_time_left <= 0.0:
			_finish_level_intro()
		return
	_grace_time_left = maxf(0.0, _grace_time_left - delta)
	if not _is_hell_game:
		return
	_hell_time += delta
	_hell_spawn_timer -= delta
	if _hell_spawn_timer <= 0.0:
		_spawn_hell_enemy()
		_hell_spawn_timer = HellRules.spawn_interval(_hell_time)
	_update_status()


func _start_game() -> void:
	if _mode != GameMode.MENU:
		return
	_mode = GameMode.PLAYING
	GameState.reset_run()
	GameState.is_custom_game = _is_custom_game
	GameState.is_hell_game = _is_hell_game
	_continue_used = false
	_waiting_reward = false
	_waiting_interstitial = false
	_interstitial_action = InterstitialAction.NONE
	_pending_next_level = 0
	_run_finished_counted = false
	_resume_button.disabled = false
	if _is_hell_game:
		GameState.level = _hell_level
		GameState.lives = HellRules.PLAYER_LIVES
		GameState.level_changed.emit(GameState.level)
		GameState.lives_changed.emit(GameState.lives)
		_hell_time = 0.0
		_hell_spawn_timer = HellRules.spawn_interval(0.0)
		_hell_final_time = 0.0
		_hell_new_record = false
	elif not _is_custom_game:
		ProgressionManager.start_run()
		SaveManager.record_run_started()
	_start_current_level()


func _start_current_level() -> void:
	if _is_custom_game:
		_level_config = _custom_level_config()
		GameState.level = _custom_config.level_number
	elif _is_hell_game:
		_level_config = LEVEL_CATALOG.get_level(_hell_level)
		GameState.level = _hell_level
	else:
		_level_config = ProgressionManager.start_current_level()
	if _level_config == null:
		_mode = GameMode.MENU
		return
	_mode = GameMode.PLAYING
	_level_lives_lost = 0
	_maze.set_hell_mode(_is_hell_game)
	_maze.configure_map(MAZE_CATALOG.get_map(_level_config.map_id, GameState.level))
	if _is_hell_game:
		_maze.reset_hell()
	else:
		_maze.reset_pellets(_maze.player_spawn_cell, _level_config.power_up_count)
	_maze.visible = true
	_player.visible = true
	if _is_hell_game:
		_configure_hell_rivals()
	else:
		_configure_rivals()
	_menu.visible = false
	_status.visible = true
	_status_frame.visible = true
	_pause_button.visible = false
	_pause_overlay.visible = false
	_maze.queue_redraw()
	_player.queue_redraw()
	_player.configure(_maze, _maze.player_spawn_cell, _level_config)
	AudioManager.play_sfx("start")
	print("[Main] nivel %d iniciado (%s)" % [GameState.level, _level_config.map_id])
	_update_status()
	_begin_level_intro()


func _begin_level_intro() -> void:
	_intro_time_left = LEVEL_INTRO_SECONDS
	_grace_time_left = LEVEL_GRACE_SECONDS
	_set_game_physics(false)
	if _intro_label != null:
		_intro_label.text = "NIVEL %02d" % GameState.level
		_intro_label.visible = true


func _finish_level_intro() -> void:
	_intro_time_left = 0.0
	_set_game_physics(true)
	_pause_button.visible = true
	if _intro_label != null:
		_intro_label.visible = false
	if _is_hell_game:
		_hell_spawn_timer = HellRules.spawn_interval(_hell_time)


func _on_pellet_collected(points: int) -> void:
	GameState.add_score(points)
	SaveManager.record_pellet_collected(_blocks_progress())
	AudioManager.play_sfx("pellet")
	HapticsManager.pulse("pellet")
	_update_status()


func _on_power_pellet_collected() -> void:
	SaveManager.record_power_pellet_collected(_blocks_progress())
	for rival in _rivals:
		if rival.visible:
			rival.set_frightened(8.0)
	AudioManager.play_sfx("power")
	HapticsManager.pulse("power")
	_status.text = "NIVEL %02d/30  IA %02d%%\nPUNTOS %05d  VIDAS %d" % [GameState.level, int(_level_config.map_difficulty * 100.0), GameState.score, GameState.lives]


func _on_rival_eaten() -> void:
	GameState.add_score(200)
	SaveManager.record_rival_eaten(_blocks_progress())
	AudioManager.play_sfx("eat")
	HapticsManager.pulse("eat")
	_update_status()


func _on_level_completed() -> void:
	if _is_hell_game:
		return
	_mode = GameMode.LEVEL_CLEAR
	_set_game_physics(false)
	_pause_button.visible = false
	AudioManager.play_sfx("complete")
	HapticsManager.pulse("complete")
	var completed_level := GameState.level
	if _is_custom_game:
		_show_result_overlay("PARTIDA COMPLETADA", "Mapa personalizado superado\nPuntos: %d" % GameState.score)
		return
	SaveManager.record_level_completed(false, _level_lives_lost == 0)
	if ProgressionManager.complete_current_level():
		_request_level_break(GameState.level, completed_level)
	else:
		SaveManager.record_run_won()
		_update_hell_button()
		_show_result_overlay(
			"JUEGO COMPLETADO",
			"Has superado los 30 niveles\nMODO INFIERNO DESBLOQUEADO\nPuntos: %d" % GameState.score,
		)
		_menu_button.visible = true


func _request_level_break(next_level: int, completed_level: int) -> void:
	_pending_next_level = next_level
	_show_level_break_wait(completed_level)
	if AdsManager.is_interstitial_ready():
		_start_interstitial(InterstitialAction.NEXT_LEVEL)
	else:
		_show_next_level_menu(next_level)


func _show_level_break_wait(completed_level: int) -> void:
	_pause_title.text = "NIVEL %d COMPLETO" % completed_level
	_pause_message.text = "Cargando anuncio..."
	_resume_button.visible = false
	_resume_button.disabled = true
	_restart_button.visible = false
	_pause_settings_button.visible = false
	_menu_button.visible = false
	_pause_overlay.visible = true


func _start_interstitial(action: InterstitialAction) -> void:
	_waiting_interstitial = true
	_interstitial_action = action
	AdsManager.show_interstitial()
	_interstitial_fallback(action)


func _on_interstitial_dismissed() -> void:
	if not _waiting_interstitial:
		return
	_waiting_interstitial = false
	var action := _interstitial_action
	_interstitial_action = InterstitialAction.NONE
	_resolve_interstitial(action)


func _interstitial_fallback(action: InterstitialAction) -> void:
	await get_tree().create_timer(15.0).timeout
	if not _waiting_interstitial or _interstitial_action != action:
		return
	_waiting_interstitial = false
	_interstitial_action = InterstitialAction.NONE
	_resolve_interstitial(action)


func _resolve_interstitial(action: InterstitialAction) -> void:
	match action:
		InterstitialAction.NEXT_LEVEL:
			if _mode == GameMode.LEVEL_CLEAR and _pending_next_level > 0:
				_show_next_level_menu(_pending_next_level)
		InterstitialAction.HELL_RESULTS:
			if _mode == GameMode.GAME_OVER and _is_hell_game:
				_show_hell_results()


func _show_next_level_menu(next_level: int) -> void:
	_pause_title.text = "NIVEL %d COMPLETO" % (next_level - 1)
	_pause_message.text = "Siguiente nivel"
	_resume_button.text = "NIVEL %d" % next_level
	_resume_button.visible = true
	_resume_button.disabled = false
	_restart_button.visible = false
	_pause_settings_button.visible = false
	_menu_button.visible = false
	_pause_overlay.visible = true


func _start_pending_level() -> void:
	if _pending_next_level <= 0:
		return
	var next_level := _pending_next_level
	_pending_next_level = 0
	if GameState.level != next_level:
		GameState.level = next_level
		GameState.level_changed.emit(GameState.level)
	_pause_overlay.visible = false
	_start_current_level()


func _finish_hell_run() -> void:
	_hell_final_time = _hell_time
	_hell_new_record = SaveManager.record_hell_time(_hell_level, _hell_final_time)
	_show_hell_wait()
	if AdsManager.is_interstitial_ready():
		_start_interstitial(InterstitialAction.HELL_RESULTS)
	else:
		_show_hell_results()


func _show_hell_wait() -> void:
	_pause_title.text = "MODO INFIERNO"
	_pause_message.text = "Cargando anuncio..."
	_resume_button.visible = false
	_resume_button.disabled = true
	_restart_button.visible = false
	_pause_settings_button.visible = false
	_menu_button.visible = false
	_pause_overlay.visible = true


func _show_hell_results() -> void:
	_pause_title.text = "MODO INFIERNO"
	var best := SaveManager.get_hell_best_time(_hell_level)
	var record_text := "NUEVO RECORD!" if _hell_new_record else "MEJOR " + HellRules.format_time(best)
	if _hell_new_record:
		HapticsManager.pulse("record")
	_pause_message.text = "Tiempo: %s\n%s" % [HellRules.format_time(_hell_final_time), record_text]
	_resume_button.visible = false
	_restart_button.visible = true
	_restart_button.text = "VOLVER A INTENTARLO"
	_pause_settings_button.visible = false
	_menu_button.text = "VOLVER AL MENU"
	_menu_button.visible = true
	_pause_overlay.visible = true


func _visible_rival_count() -> int:
	var total := 0
	for rival in _rivals:
		if rival.visible:
			total += 1
	return total


func _hide_all_rivals() -> void:
	for rival in _rivals:
		rival.visible = false
		rival.stop_movement()
		rival.set_physics_process(false)


func _configure_hell_rivals() -> void:
	_hide_all_rivals()
	_spawn_hell_enemy()


func _spawn_hell_enemy() -> void:
	var visible_count := _visible_rival_count()
	var rival: RivalDog
	if visible_count < _rivals.size():
		rival = _rivals[visible_count]
	else:
		rival = RivalDog.new()
		add_child(rival)
		_rivals.append(rival)
		_bind_rival(rival)
	var occupied_cells: Array[Vector2i] = [_maze.player_spawn_cell, _player.cell]
	for other in _rivals:
		if other.visible:
			occupied_cells.append(other.cell)
	var spawn_cell := _maze.get_random_safe_spawn_cell(occupied_cells, 6)
	rival.visible = true
	rival.set_hell_mode(true)
	rival.configure(_maze, _player, spawn_cell, _level_config)
	rival.set_physics_process(true)


func _on_player_hit() -> void:
	if _mode != GameMode.PLAYING:
		return
	if _intro_time_left > 0.0 or _grace_time_left > 0.0:
		return
	HapticsManager.pulse("hit")
	if _is_hell_game:
		_level_lives_lost += 1
		GameState.lose_life()
		_mode = GameMode.GAME_OVER
		_set_game_physics(false)
		_pause_button.visible = false
		AudioManager.play_sfx("hit")
		_finish_hell_run()
		return
	_level_lives_lost += 1
	SaveManager.record_life_lost(_blocks_progress())
	if GameState.lose_life():
		_mode = GameMode.GAME_OVER
		_set_game_physics(false)
		_pause_button.visible = false
		AudioManager.play_sfx("hit")
		_show_game_over()
		return
	var occupied_cells: Array[Vector2i] = []
	for rival in _rivals:
		if rival.visible:
			occupied_cells.append(rival.cell)
	var respawn_cell := _maze.get_random_safe_spawn_cell(occupied_cells, _level_config.respawn_distance)
	_player.respawn(respawn_cell)
	for rival in _rivals:
		if rival.visible:
			rival.reset_position()
	AudioManager.play_sfx("hit")
	_update_status()


func _on_rival_caught() -> void:
	_player.receive_hit()


func _blocks_progress() -> bool:
	return _is_custom_game or _is_hell_game


func _update_status() -> void:
	if _is_hell_game:
		_status.text = "MODO INFIERNO  NIVEL %02d\nTIEMPO %s  PERROS %02d" % [
			GameState.level,
			HellRules.format_time(_hell_time),
			_visible_rival_count(),
		]
		return
	var mode_label := "PERSONALIZADA" if _is_custom_game else "NIVEL"
	_status.text = "%s %02d/30  IA %02d%%\nPUNTOS %05d  VIDAS %d" % [mode_label, GameState.level, int(_level_config.map_difficulty * 100.0), GameState.score, GameState.lives]


func _toggle_pause() -> void:
	if _mode == GameMode.PLAYING:
		_pause_game()
	elif _mode == GameMode.PAUSED:
		_resume_game()


func _pause_game() -> void:
	if _mode != GameMode.PLAYING or _intro_time_left > 0.0:
		return
	_mode = GameMode.PAUSED
	_set_game_physics(false)
	_pause_button.visible = false
	_pause_title.text = "PAUSA"
	_pause_message.text = "La partida esta detenida"
	_resume_button.visible = true
	_resume_button.disabled = false
	_resume_button.text = "CONTINUAR"
	_restart_button.visible = true
	_restart_button.text = "REINICIAR"
	_pause_settings_button.visible = true
	_menu_button.text = "SALIR"
	_menu_button.visible = true
	_pause_overlay.visible = true
	AudioManager.play_sfx("pause")


func _resume_game() -> void:
	if _mode != GameMode.PAUSED:
		return
	_mode = GameMode.PLAYING
	_set_game_physics(_intro_time_left <= 0.0)
	_pause_overlay.visible = false
	_pause_button.visible = _intro_time_left <= 0.0
	AudioManager.play_sfx("resume")


func _restart_game() -> void:
	if _mode == GameMode.GAME_OVER:
		_finish_run_if_needed()
	_pause_overlay.visible = false
	_mode = GameMode.MENU
	_start_game()


func _show_result_overlay(title: String, message: String) -> void:
	_pause_title.text = title
	_pause_message.text = message
	_resume_button.visible = false
	_restart_button.visible = true
	_restart_button.text = "JUGAR DE NUEVO"
	_pause_settings_button.visible = false
	_menu_button.text = "VOLVER AL MENU"
	_menu_button.visible = _is_custom_game
	_pause_overlay.visible = true


func _show_game_over(message: String = "") -> void:
	if message.is_empty():
		message = "Puntos: %d" % GameState.score
	_pause_title.text = "GAME OVER"
	_pause_message.text = message
	_resume_button.text = "VER ANUNCIO Y CONTINUAR"
	_resume_button.visible = not _continue_used and not _waiting_reward and AdsManager.is_rewarded_ready()
	_restart_button.text = "EMPEZAR NIVEL 1"
	_restart_button.visible = true
	_pause_settings_button.visible = false
	_menu_button.text = "VOLVER AL MENU"
	_menu_button.visible = true
	_pause_overlay.visible = true


func _on_resume_button_pressed() -> void:
	if _mode == GameMode.PAUSED:
		_resume_game()
	elif _mode == GameMode.GAME_OVER:
		_request_rewarded_continue()
	elif _mode == GameMode.LEVEL_CLEAR:
		_start_pending_level()


func _request_rewarded_continue() -> void:
	if _continue_used or _waiting_reward or not AdsManager.is_rewarded_ready():
		return
	_waiting_reward = true
	_resume_button.disabled = true
	_resume_button.text = "CARGANDO ANUNCIO..."
	AdsManager.show_rewarded()


func _on_rewarded_completed() -> void:
	if _mode != GameMode.GAME_OVER or not _waiting_reward:
		return
	_waiting_reward = false
	_continue_used = true
	GameState.lives = 1
	GameState.lives_changed.emit(GameState.lives)
	_pause_overlay.visible = false
	_start_current_level()


func _on_rewarded_failed(reason: String) -> void:
	if not _waiting_reward:
		return
	_waiting_reward = false
	_resume_button.disabled = false
	_show_game_over("No se pudo mostrar el anuncio\nPuntos: %d" % GameState.score)
	push_warning("No se pudo continuar con anuncio: %s" % reason)


func _finish_run_if_needed() -> void:
	if _is_custom_game or _is_hell_game or _run_finished_counted:
		return
	_run_finished_counted = true
	SaveManager.record_run_finished()


func _return_to_menu() -> void:
	if _mode == GameMode.GAME_OVER:
		_finish_run_if_needed()
	SaveManager.flush()
	_set_game_physics(false)
	_mode = GameMode.MENU
	_intro_time_left = 0.0
	_grace_time_left = 0.0
	if _intro_label != null:
		_intro_label.visible = false
	_waiting_interstitial = false
	_interstitial_action = InterstitialAction.NONE
	_pending_next_level = 0
	_hell_time = 0.0
	_maze.visible = false
	_player.visible = false
	for rival in _rivals:
		rival.visible = false
	_pause_overlay.visible = false
	_pause_button.visible = false
	_status.visible = false
	_status_frame.visible = false
	_menu.visible = true
	_is_custom_game = false
	_is_hell_game = false
	_custom_panel.visible = false
	_hell_screen.visible = false
	_update_hell_button()
	_high_score.text = "RECORD  %04d\nNIVEL MAXIMO  %02d" % [SaveManager.high_score, SaveManager.highest_level]


func _open_achievements() -> void:
	if _mode != GameMode.MENU:
		return
	_menu.visible = false
	_achievements_screen.open()


func _open_customization() -> void:
	if _mode != GameMode.MENU:
		return
	_menu.visible = false
	_customization_screen.open()


func _open_hell_menu() -> void:
	if _mode != GameMode.MENU or not SaveManager.has_completed_normal_game():
		return
	_is_custom_game = false
	_is_hell_game = false
	_menu.visible = false
	_hell_screen.open()


func _close_hell_screen() -> void:
	_hell_screen.visible = false
	_menu.visible = true


func _start_hell_game(level_number: int) -> void:
	_hell_level = clampi(level_number, 1, HellRules.LEVEL_COUNT)
	_is_custom_game = false
	_is_hell_game = true
	_custom_panel.visible = false
	_mode = GameMode.MENU
	_start_game()


func _on_hell_level_selected(level_number: int) -> void:
	_hell_screen.visible = false
	_start_hell_game(level_number)


func _update_hell_button() -> void:
	var unlocked := SaveManager.has_completed_normal_game()
	_hell_button.disabled = not unlocked
	_hell_button.text = "MODO INFIERNO" if unlocked else "MODO INFIERNO (BLOQ.)"


func _close_progress_screens() -> void:
	_achievements_screen.visible = false
	_customization_screen.visible = false
	_menu.visible = true


func _setup_safe_area() -> void:
	var menu_page := SafeAreaPage.new()
	_menu.add_child(menu_page)
	var menu_children: Array[Node] = [
		$UI/Menu/Title,
		$UI/Menu/Subtitle,
		_high_score,
		_start_button,
		_custom_button,
		_achievements_button,
		_customize_button,
		_settings_button,
		_hell_button,
		$UI/Menu/Hint,
		$UI/Menu/Footer,
	]
	for item in menu_children:
		item.reparent(menu_page, false)
	var pause_page := SafeAreaPage.new()
	_pause_overlay.add_child(pause_page)
	var pause_children: Array[Node] = [
		$UI/PauseOverlay/Card,
		_pause_title,
		_pause_message,
		_resume_button,
		_restart_button,
		_pause_settings_button,
		_menu_button,
	]
	for item in pause_children:
		item.reparent(pause_page, false)


func _build_progress_screens() -> void:
	_achievements_screen = AchievementsScreen.new()
	$UI.add_child(_achievements_screen)
	_achievements_screen.closed.connect(_close_progress_screens)
	_customization_screen = CustomizationScreen.new()
	$UI.add_child(_customization_screen)
	_customization_screen.closed.connect(_close_progress_screens)
	_settings_screen = SettingsScreen.new()
	$UI.add_child(_settings_screen)
	_settings_screen.closed.connect(_close_settings)
	_tutorial_screen = TutorialScreen.new()
	$UI.add_child(_tutorial_screen)
	_tutorial_screen.closed.connect(_close_tutorial)


func _build_hell_screen() -> void:
	_hell_screen = HellSelectScreen.new()
	$UI.add_child(_hell_screen)
	_hell_screen.closed.connect(_close_hell_screen)
	_hell_screen.level_selected.connect(_on_hell_level_selected)


func _build_intro_label() -> void:
	_intro_label = Label.new()
	_intro_label.theme = ARCADE_THEME
	_intro_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intro_label.add_theme_font_size_override("font_size", 20)
	_intro_label.add_theme_color_override("font_color", Color("#FDE68A"))
	_intro_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	_intro_label.add_theme_constant_override("shadow_offset_x", 2)
	_intro_label.add_theme_constant_override("shadow_offset_y", 2)
	_intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_label.visible = false
	$UI.add_child(_intro_label)


func _open_settings_from_menu() -> void:
	if _mode != GameMode.MENU:
		return
	_settings_from_pause = false
	_menu.visible = false
	_settings_screen.open()


func _open_settings_from_pause() -> void:
	if _mode != GameMode.PAUSED:
		return
	_settings_from_pause = true
	_pause_overlay.visible = false
	_settings_screen.open()


func _close_settings() -> void:
	_settings_screen.visible = false
	if _settings_from_pause and _mode == GameMode.PAUSED:
		_pause_overlay.visible = true
	else:
		_menu.visible = true
	_settings_from_pause = false


func _open_tutorial() -> void:
	if _mode != GameMode.MENU:
		return
	_menu.visible = false
	_tutorial_screen.open()


func _close_tutorial() -> void:
	SaveManager.set_setting("tutorial_seen", true)
	_tutorial_screen.visible = false
	_menu.visible = true


func _on_progress_reset() -> void:
	_settings_from_pause = false
	_settings_screen.visible = false
	_tutorial_screen.visible = false
	_return_to_menu()
	UnlockManager.ensure_selection_valid()
	_queue_unlock_toast("PROGRESO BORRADO")


func _build_unlock_toast() -> void:
	_toast_panel = Panel.new()
	_toast_panel.position = Vector2(30.0, 88.0)
	_toast_panel.size = Vector2(300.0, 46.0)
	_toast_panel.z_index = 100
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#11152F")
	style.border_color = Color("#FDE68A")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_toast_panel.add_theme_stylebox_override("panel", style)
	_toast_label = Label.new()
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 7)
	_toast_label.add_theme_color_override("font_color", Color("#FDE68A"))
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_panel.add_child(_toast_label)
	_toast_panel.visible = false
	var page := SafeAreaPage.new()
	page.z_index = 100
	$UI.add_child(page)
	page.add_child(_toast_panel)


func _on_achievement_unlocked(id: String) -> void:
	var definition := AchievementCatalog.get_by_id(id)
	if definition != null:
		_queue_unlock_toast("LOGRO: " + definition.title)


func _on_cosmetic_unlocked(id: String) -> void:
	var definition := CosmeticCatalog.get_by_id(id)
	if definition != null:
		_queue_unlock_toast("DESBLOQUEADO: " + definition.title)


func _on_cosmetics_changed(_category: String, _id: String) -> void:
	_player.queue_redraw()
	for rival in _rivals:
		rival.queue_redraw()
	_maze.queue_redraw()


func _queue_unlock_toast(text: String) -> void:
	_toast_queue.append(text)
	if not _toast_active:
		_show_next_unlock_toast()


func _show_next_unlock_toast() -> void:
	if _toast_queue.is_empty():
		_toast_active = false
		_toast_panel.visible = false
		return
	_toast_active = true
	_toast_label.text = _toast_queue.pop_front()
	_toast_panel.visible = true
	await get_tree().create_timer(2.6).timeout
	if not is_inside_tree():
		return
	_show_next_unlock_toast()


func _open_custom_menu() -> void:
	if _mode != GameMode.MENU:
		return
	_is_custom_game = false
	_custom_panel.visible = true
	_menu.visible = false
	var max_level := maxi(1, SaveManager.highest_level)
	_custom_level.max_value = max_level
	var saved := SaveManager.get_last_custom_config()
	var chosen_level := max_level
	if not saved.is_empty():
		chosen_level = clampi(int(saved.get("level_number", max_level)), 1, max_level)
	_custom_level.value = chosen_level
	var base_config := LEVEL_CATALOG.get_level(chosen_level)
	if saved.is_empty():
		_custom_player_speed.value = base_config.player_speed
		_custom_rival_speed.value = base_config.rival_speed
		_custom_rival_count.value = base_config.rival_count
		_custom_difficulty.value = base_config.map_difficulty
		_custom_power_ups.value = base_config.power_up_count
	else:
		_custom_player_speed.value = clampf(float(saved.get("player_speed", base_config.player_speed)), GameLimits.MIN_PLAYER_SPEED, GameLimits.MAX_PLAYER_SPEED)
		_custom_rival_speed.value = clampf(float(saved.get("rival_speed", base_config.rival_speed)), GameLimits.MIN_RIVAL_SPEED, GameLimits.MAX_RIVAL_SPEED)
		_custom_rival_count.value = clampi(int(saved.get("rival_count", base_config.rival_count)), GameLimits.MIN_RIVAL_COUNT, GameLimits.MAX_RIVAL_COUNT)
		_custom_difficulty.value = clampf(float(saved.get("map_difficulty", base_config.map_difficulty)), GameLimits.MIN_MAP_DIFFICULTY, GameLimits.MAX_MAP_DIFFICULTY)
		_custom_power_ups.value = clampi(int(saved.get("power_up_count", base_config.power_up_count)), GameLimits.MIN_POWER_UP_COUNT, GameLimits.MAX_POWER_UP_COUNT)
	_refresh_custom_values()


func _start_custom_game() -> void:
	_custom_config = CustomGameConfig.new()
	_custom_config.level_number = int(_custom_level.value)
	_custom_config.player_speed = _custom_player_speed.value
	_custom_config.rival_speed = _custom_rival_speed.value
	_custom_config.rival_count = int(_custom_rival_count.value)
	_custom_config.map_difficulty = _custom_difficulty.value
	_custom_config.power_up_count = int(_custom_power_ups.value)
	var errors := _custom_config.validate()
	if not errors.is_empty():
		_refresh_custom_values("CONFIGURACION INVALIDA")
		return
	SaveManager.record_custom_config(_custom_config)
	_is_custom_game = true
	_is_hell_game = false
	_custom_panel.visible = false
	_mode = GameMode.MENU
	_start_game()


func _custom_level_config() -> LevelConfig:
	var base_config := LEVEL_CATALOG.get_level(_custom_config.level_number)
	var config := LevelConfig.new()
	config.level_number = _custom_config.level_number
	config.map_id = base_config.map_id
	config.map_size_tier = base_config.map_size_tier
	config.respawn_distance = base_config.respawn_distance
	config.player_speed = _custom_config.player_speed
	config.rival_speed = _custom_config.rival_speed
	config.rival_count = _custom_config.rival_count
	config.map_difficulty = _custom_config.map_difficulty
	config.power_up_count = _custom_config.power_up_count
	return config


func _build_custom_panel() -> void:
	_custom_panel = Control.new()
	_custom_panel.theme = ARCADE_THEME
	_custom_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_custom_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_custom_panel.visible = false
	$UI.add_child(_custom_panel)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#070817")
	_custom_panel.add_child(shade)
	var page := SafeAreaPage.new()
	_custom_panel.add_child(page)
	var panel := Panel.new()
	panel.position = Vector2(18.0, 42.0)
	panel.size = Vector2(324.0, 550.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#11152F")
	style.border_color = Color("#273B82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	page.add_child(panel)
	var title := _custom_label("MODO PERSONALIZADO", Vector2(30.0, 18.0), Vector2(264.0, 32.0), 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_custom_level = _add_custom_slider(panel, "Nivel", 68.0, 1.0, 1.0, 1.0, 1.0)
	_custom_player_speed = _add_custom_slider(panel, "Velocidad gato", 128.0, GameLimits.MIN_PLAYER_SPEED, GameLimits.MAX_PLAYER_SPEED, 1.0, 72.0)
	_custom_rival_speed = _add_custom_slider(panel, "Velocidad rivales", 188.0, GameLimits.MIN_RIVAL_SPEED, GameLimits.MAX_RIVAL_SPEED, 1.0, 54.0)
	_custom_rival_count = _add_custom_slider(panel, "Numero rivales", 248.0, GameLimits.MIN_RIVAL_COUNT, GameLimits.MAX_RIVAL_COUNT, 1.0, 1.0)
	_custom_difficulty = _add_custom_slider(panel, "Dificultad de la IA", 308.0, 0.0, 1.0, 0.05, 0.0)
	_custom_power_ups = _add_custom_slider(panel, "Power-ups", 368.0, GameLimits.MIN_POWER_UP_COUNT, GameLimits.MAX_POWER_UP_COUNT, 1.0, 1.0)
	var summary := _custom_label("Solo practica: no genera logros ni progreso", Vector2(30.0, 425.0), Vector2(264.0, 30.0), 6)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(summary)
	var start := _custom_button_node("JUGAR", Vector2(42.0, 465.0), Vector2(114.0, 52.0))
	start.pressed.connect(_start_custom_game)
	panel.add_child(start)
	var back := _custom_button_node("VOLVER", Vector2(168.0, 465.0), Vector2(114.0, 52.0))
	back.pressed.connect(_return_to_menu)
	panel.add_child(back)
	for slider in [_custom_level, _custom_player_speed, _custom_rival_speed, _custom_rival_count, _custom_difficulty, _custom_power_ups]:
		slider.value_changed.connect(func(_value: float) -> void: _refresh_custom_values())


func _add_custom_slider(parent: Control, title: String, y: float, minimum: float, maximum: float, step: float, value: float) -> HSlider:
	var label := _custom_label(title, Vector2(14.0, y), Vector2(122.0, 26.0), 7)
	parent.add_child(label)
	var slider := HSlider.new()
	slider.position = Vector2(140.0, y + 2.0)
	slider.size = Vector2(138.0, 24.0)
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	parent.add_child(slider)
	var value_label := _custom_label("", Vector2(282.0, y), Vector2(30.0, 26.0), 7)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(value_label)
	_custom_value_labels[title] = value_label
	return slider


func _custom_label(text: String, position: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#E5E7EB"))
	return label


func _custom_button_node(text: String, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 10)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#F97316")
	normal.border_color = Color("#FDE68A")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#C8320A")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


func _refresh_custom_values(message: String = "") -> void:
	if _custom_value_labels.is_empty():
		return
	_custom_value_labels["Nivel"].text = "%d" % int(_custom_level.value)
	_custom_value_labels["Velocidad gato"].text = "%d" % int(_custom_player_speed.value)
	_custom_value_labels["Velocidad rivales"].text = "%d" % int(_custom_rival_speed.value)
	_custom_value_labels["Numero rivales"].text = "%d" % int(_custom_rival_count.value)
	_custom_value_labels["Dificultad de la IA"].text = "%d%%" % int(_custom_difficulty.value * 100.0)
	_custom_value_labels["Power-ups"].text = "%d" % int(_custom_power_ups.value)


func _set_game_physics(enabled: bool) -> void:
	_player.set_physics_process(enabled)
	for rival in _rivals:
		rival.set_physics_process(enabled and rival.visible)


func _configure_rivals() -> void:
	while _rivals.size() < _level_config.rival_count:
		var rival := RivalDog.new()
		add_child(rival)
		_rivals.append(rival)
		_bind_rival(rival)
	var occupied_cells: Array[Vector2i] = [_maze.player_spawn_cell]
	for index in _rivals.size():
		var rival := _rivals[index]
		rival.set_hell_mode(false)
		if index >= _level_config.rival_count:
			rival.visible = false
			rival.stop_movement()
			rival.set_physics_process(false)
			continue
		rival.visible = true
		var spawn_cell := _maze.rival_spawn_cells[index] if index < _maze.rival_spawn_cells.size() else _maze.get_random_safe_spawn_cell(occupied_cells, 6)
		if spawn_cell in occupied_cells:
			spawn_cell = _maze.get_random_safe_spawn_cell(occupied_cells, 6)
		occupied_cells.append(spawn_cell)
		rival.configure(_maze, _player, spawn_cell, _level_config)


func _bind_rival(rival: RivalDog) -> void:
	rival.player_caught.connect(_on_rival_caught)
	rival.rival_eaten.connect(_on_rival_eaten)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if is_inside_tree():
				_pause_game()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var shortcut_event := event as InputEventKey
		if shortcut_event.keycode == KEY_ESCAPE:
			if _mode == GameMode.PLAYING or _mode == GameMode.PAUSED:
				_toggle_pause()
			get_viewport().set_input_as_handled()
			return
	if _mode != GameMode.PLAYING:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_H:
			_player.receive_hit()
			get_viewport().set_input_as_handled()
			return
		var key_direction := _direction_from_key(key_event.keycode)
		if key_direction != Vector2i.ZERO:
			_player.request_direction(key_direction)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_swipe_start = touch_event.position
		else:
			_handle_swipe(touch_event.position - _swipe_start)
			get_viewport().set_input_as_handled()


func _handle_swipe(delta: Vector2) -> void:
	if delta.length() < 18.0:
		return
	if abs(delta.x) > abs(delta.y):
		_player.request_direction(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT)
	else:
		_player.request_direction(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)


func _direction_from_key(keycode: Key) -> Vector2i:
	match keycode:
		KEY_UP, KEY_W:
			return Vector2i.UP
		KEY_DOWN, KEY_S:
			return Vector2i.DOWN
		KEY_LEFT, KEY_A:
			return Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			return Vector2i.RIGHT
	return Vector2i.ZERO
