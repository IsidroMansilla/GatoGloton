extends Node2D

@onready var _maze: Maze = $Maze
@onready var _player: Player = $Player
@onready var _rival: RivalCat = $RivalCat
@onready var _status: Label = $UI/Status
@onready var _pause_button: Button = $UI/PauseButton
@onready var _pause_overlay: Control = $UI/PauseOverlay
@onready var _pause_title: Label = $UI/PauseOverlay/Title
@onready var _pause_message: Label = $UI/PauseOverlay/Message
@onready var _resume_button: Button = $UI/PauseOverlay/ResumeButton
@onready var _restart_button: Button = $UI/PauseOverlay/RestartButton
@onready var _menu: Control = $UI/Menu
@onready var _start_button: Button = $UI/Menu/StartButton

enum GameMode { MENU, PLAYING, PAUSED, GAME_OVER, LEVEL_CLEAR }
var _mode: GameMode = GameMode.MENU
var _swipe_start: Vector2
const START_CELL := Vector2i(1, 1)


func _ready() -> void:
	_maze.visible = false
	_player.visible = false
	_rival.visible = false
	_menu.visible = true
	_status.visible = false
	_pause_button.visible = false
	_pause_overlay.visible = false
	_start_button.pressed.connect(_start_game)
	_pause_button.pressed.connect(_toggle_pause)
	_resume_button.pressed.connect(_resume_game)
	_restart_button.pressed.connect(_restart_game)
	_player.hit_received.connect(_on_player_hit)
	_rival.player_caught.connect(_on_rival_caught)
	_maze.pellet_collected.connect(_on_pellet_collected)
	_maze.power_pellet_collected.connect(_on_power_pellet_collected)
	_maze.level_completed.connect(_on_level_completed)
	_rival.rival_eaten.connect(_on_rival_eaten)
	$UI/Menu/HighScore.text = "RECORD  %04d" % [SaveManager.high_score]


func _start_game() -> void:
	if _mode != GameMode.MENU:
		return
	_mode = GameMode.PLAYING
	GameState.reset_run()
	_maze.reset_pellets(START_CELL)
	_maze.visible = true
	_player.visible = true
	_rival.visible = true
	_menu.visible = false
	_status.visible = true
	_pause_button.visible = true
	_pause_overlay.visible = false
	_set_game_physics(true)
	_maze.queue_redraw()
	_player.queue_redraw()
	_player.configure(_maze, START_CELL)
	_rival.configure(_maze, _player)
	AudioManager.play_sfx("start")
	print("[Main] partida iniciada")
	_update_status()


func _on_pellet_collected(points: int) -> void:
	GameState.add_score(points)
	AudioManager.play_sfx("pellet")
	_update_status()


func _on_power_pellet_collected() -> void:
	_rival.set_frightened(8.0)
	AudioManager.play_sfx("power")
	_status.text = "MODO VULNERABLE\nPuntos: %d | Vidas: %d" % [GameState.score, GameState.lives]


func _on_rival_eaten() -> void:
	GameState.add_score(200)
	AudioManager.play_sfx("eat")
	_update_status()


func _on_level_completed() -> void:
	_mode = GameMode.LEVEL_CLEAR
	_set_game_physics(false)
	_pause_button.visible = false
	AudioManager.play_sfx("complete")
	_show_result_overlay("LABERINTO COMPLETO", "Puntos: %d | Record: %d" % [
		GameState.score,
		SaveManager.high_score,
	])


func _on_player_hit() -> void:
	if _mode != GameMode.PLAYING:
		return
	if GameState.lose_life():
		_mode = GameMode.GAME_OVER
		_set_game_physics(false)
		_pause_button.visible = false
		AudioManager.play_sfx("hit")
		_show_result_overlay("GAME OVER", "Puntos: %d" % GameState.score)
		return
	_player.respawn(START_CELL)
	_rival.reset_position()
	AudioManager.play_sfx("hit")
	_update_status()


func _on_rival_caught() -> void:
	_player.receive_hit()


func _update_status() -> void:
	_status.text = "Puntos: %d | Record: %d\nFlechas/WASD o desliza | Vidas: %d" % [
		GameState.score,
		SaveManager.high_score,
		GameState.lives,
	]


func _toggle_pause() -> void:
	if _mode == GameMode.PLAYING:
		_mode = GameMode.PAUSED
		_set_game_physics(false)
		_pause_button.visible = false
		_pause_title.text = "PAUSA"
		_pause_message.text = "La partida esta detenida"
		_resume_button.visible = true
		_restart_button.text = "REINICIAR"
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
	_restart_button.text = "JUGAR DE NUEVO"
	_pause_overlay.visible = true


func _set_game_physics(enabled: bool) -> void:
	_player.set_physics_process(enabled)
	_rival.set_physics_process(enabled)


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
