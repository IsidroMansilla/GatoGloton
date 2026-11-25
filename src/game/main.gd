extends Node2D

const LEVEL_CATALOG: LevelCatalog = preload("res://src/data/progression_levels.tres")
const MAZE_CATALOG = preload("res://src/data/maze_catalog.gd")
const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")

@onready var _maze: Maze = $Maze
@onready var _player: Player = $Player
@onready var _rival: RivalCat = $RivalCat
@onready var _status: Label = $UI/Status
@onready var _status_frame: Panel = $UI/StatusFrame
@onready var _pause_button: Button = $UI/PauseButton
@onready var _pause_overlay: Control = $UI/PauseOverlay
@onready var _pause_title: Label = $UI/PauseOverlay/Title
@onready var _pause_message: Label = $UI/PauseOverlay/Message
@onready var _resume_button: Button = $UI/PauseOverlay/ResumeButton
@onready var _restart_button: Button = $UI/PauseOverlay/RestartButton
@onready var _menu_button: Button = $UI/PauseOverlay/MenuButton
@onready var _menu: Control = $UI/Menu
@onready var _start_button: Button = $UI/Menu/StartButton
@onready var _custom_button: Button = $UI/Menu/CustomButton

enum GameMode { MENU, PLAYING, PAUSED, GAME_OVER, LEVEL_CLEAR }
var _mode: GameMode = GameMode.MENU
var _swipe_start: Vector2
var _level_config: LevelConfig
var _rivals: Array[RivalCat] = []
var _continue_used: bool = false
var _waiting_reward: bool = false
var _is_custom_game: bool = false
var _custom_config: CustomGameConfig
var _custom_panel: Control
var _custom_level: HSlider
var _custom_player_speed: HSlider
var _custom_rival_speed: HSlider
var _custom_rival_count: HSlider
var _custom_difficulty: HSlider
var _custom_power_ups: HSlider
var _custom_value_labels: Dictionary = {}


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
	_pause_button.pressed.connect(_toggle_pause)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_restart_button.pressed.connect(_restart_game)
	_menu_button.pressed.connect(_return_to_menu)
	AdsManager.rewarded_completed.connect(_on_rewarded_completed)
	AdsManager.rewarded_failed.connect(_on_rewarded_failed)
	_player.hit_received.connect(_on_player_hit)
	_bind_rival(_rival)
	_maze.pellet_collected.connect(_on_pellet_collected)
	_maze.power_pellet_collected.connect(_on_power_pellet_collected)
	_maze.level_completed.connect(_on_level_completed)
	$UI/Menu/HighScore.text = "RECORD  %04d\nNIVEL MAXIMO  %02d" % [SaveManager.high_score, SaveManager.highest_level]
	_build_custom_panel()


func _start_game() -> void:
	if _mode != GameMode.MENU:
		return
	_mode = GameMode.PLAYING
	GameState.reset_run()
	GameState.is_custom_game = _is_custom_game
	if not _is_custom_game:
		ProgressionManager.start_run()
	_continue_used = false
	_waiting_reward = false
	_resume_button.disabled = false
	_start_current_level()


func _start_current_level() -> void:
	if _is_custom_game:
		_level_config = _custom_level_config()
		GameState.level = _custom_config.level_number
	else:
		_level_config = ProgressionManager.start_current_level()
	if _level_config == null:
		_mode = GameMode.MENU
		return
	_mode = GameMode.PLAYING
	_maze.configure_map(MAZE_CATALOG.get_map(_level_config.map_id, GameState.level))
	_maze.reset_pellets(_maze.player_spawn_cell, _level_config.power_up_count)
	_maze.visible = true
	_player.visible = true
	_configure_rivals()
	_menu.visible = false
	_status.visible = true
	_status_frame.visible = true
	_pause_button.visible = true
	_pause_overlay.visible = false
	_set_game_physics(true)
	_maze.queue_redraw()
	_player.queue_redraw()
	_player.configure(_maze, _maze.player_spawn_cell, _level_config)
	AudioManager.play_sfx("start")
	print("[Main] nivel %d iniciado (%s)" % [GameState.level, _level_config.map_id])
	_update_status()


func _on_pellet_collected(points: int) -> void:
	GameState.add_score(points)
	AudioManager.play_sfx("pellet")
	_update_status()


func _on_power_pellet_collected() -> void:
	for rival in _rivals:
		if rival.visible:
			rival.set_frightened(8.0)
	AudioManager.play_sfx("power")
	_status.text = "NIVEL %02d/30  IA %02d%%\nPUNTOS %05d  VIDAS %d" % [GameState.level, int(_level_config.map_difficulty * 100.0), GameState.score, GameState.lives]


func _on_rival_eaten() -> void:
	GameState.add_score(200)
	AudioManager.play_sfx("eat")
	_update_status()


func _on_level_completed() -> void:
	_mode = GameMode.LEVEL_CLEAR
	_set_game_physics(false)
	_pause_button.visible = false
	AudioManager.play_sfx("complete")
	var completed_level := GameState.level
	if _is_custom_game:
		_show_result_overlay("PARTIDA COMPLETADA", "Mapa personalizado superado\nPuntos: %d" % GameState.score)
		return
	if ProgressionManager.complete_current_level():
		_show_result_overlay("NIVEL %d COMPLETO" % completed_level, "Preparando nivel %d..." % GameState.level)
		_continue_to_next_level()
	else:
		_show_result_overlay("JUEGO COMPLETADO", "Has superado los 30 niveles\nPuntos: %d" % GameState.score)


func _on_player_hit() -> void:
	if _mode != GameMode.PLAYING:
		return
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


func _update_status() -> void:
	var mode_label := "PERSONALIZADA" if _is_custom_game else "NIVEL"
	_status.text = "%s %02d/30  IA %02d%%\nPUNTOS %05d  VIDAS %d" % [mode_label, GameState.level, int(_level_config.map_difficulty * 100.0), GameState.score, GameState.lives]


func _toggle_pause() -> void:
	if _mode == GameMode.PLAYING:
		_mode = GameMode.PAUSED
		_set_game_physics(false)
		_pause_button.visible = false
		_pause_title.text = "PAUSA"
		_pause_message.text = "La partida esta detenida"
		_resume_button.visible = true
		_resume_button.disabled = false
		_resume_button.text = "CONTINUAR"
		_restart_button.text = "REINICIAR"
		_menu_button.text = "SALIR"
		_menu_button.visible = true
		_pause_overlay.visible = true
		AudioManager.play_sfx("pause")
	elif _mode == GameMode.PAUSED:
		_resume_game()


func _resume_game() -> void:
	if _mode != GameMode.PAUSED:
		return
	_mode = GameMode.PLAYING
	_set_game_physics(true)
	_pause_overlay.visible = false
	_pause_button.visible = true
	AudioManager.play_sfx("resume")


func _restart_game() -> void:
	_pause_overlay.visible = false
	_mode = GameMode.MENU
	_start_game()


func _show_result_overlay(title: String, message: String) -> void:
	_pause_title.text = title
	_pause_message.text = message
	_resume_button.visible = false
	_restart_button.visible = true
	_restart_button.text = "JUGAR DE NUEVO"
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
	_menu_button.text = "VOLVER AL MENU"
	_menu_button.visible = true
	_pause_overlay.visible = true


func _on_resume_button_pressed() -> void:
	if _mode == GameMode.PAUSED:
		_resume_game()
	elif _mode == GameMode.GAME_OVER:
		_request_rewarded_continue()


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


func _return_to_menu() -> void:
	_set_game_physics(false)
	_mode = GameMode.MENU
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
	_custom_panel.visible = false
	$UI/Menu/HighScore.text = "RECORD  %04d\nNIVEL MAXIMO  %02d" % [SaveManager.high_score, SaveManager.highest_level]


func _open_custom_menu() -> void:
	if _mode != GameMode.MENU:
		return
	_is_custom_game = false
	_custom_panel.visible = true
	_menu.visible = false
	var max_level := maxi(1, SaveManager.highest_level)
	_custom_level.max_value = max_level
	_custom_level.value = max_level
	var base_config := LEVEL_CATALOG.get_level(max_level)
	_custom_player_speed.value = base_config.player_speed
	_custom_rival_speed.value = base_config.rival_speed
	_custom_rival_count.value = base_config.rival_count
	_custom_difficulty.value = base_config.map_difficulty
	_custom_power_ups.value = base_config.power_up_count
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
	_is_custom_game = true
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
	var panel := Panel.new()
	panel.position = Vector2(18.0, 42.0)
	panel.size = Vector2(324.0, 550.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#11152F")
	style.border_color = Color("#273B82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	_custom_panel.add_child(panel)
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
		var rival := RivalCat.new()
		add_child(rival)
		_rivals.append(rival)
		_bind_rival(rival)
	var occupied_cells: Array[Vector2i] = [_maze.player_spawn_cell]
	for index in _rivals.size():
		var rival := _rivals[index]
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


func _bind_rival(rival: RivalCat) -> void:
	rival.player_caught.connect(_on_rival_caught)
	rival.rival_eaten.connect(_on_rival_eaten)


func _continue_to_next_level() -> void:
	await get_tree().create_timer(1.25).timeout
	if _mode != GameMode.LEVEL_CLEAR:
		return
	_pause_overlay.visible = false
	_start_current_level()


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
