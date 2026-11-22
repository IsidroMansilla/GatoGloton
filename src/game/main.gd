extends Node2D

@onready var _maze: Maze = $Maze
@onready var _player: Player = $Player
@onready var _status: Label = $UI/Status
@onready var _title: Label = $UI/Title
@onready var _start_button: Button = $UI/StartButton
@onready var _background: ColorRect = $UI/Background

var _game_started: bool = false


func _ready() -> void:
	GameState.reset_run()
	_maze.visible = false
	_player.visible = false
	_start_button.pressed.connect(_start_game)
	_status.text = "Come bolas de pelo y evita a los gatos\nRecord: %d" % [
		SaveManager.high_score,
	]
	# M1 entra directamente al gameplay para no bloquear la prueba en Android.
	_start_game()


func _input(event: InputEvent) -> void:
	if _game_started:
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_start_game()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_start_game()


func _start_game() -> void:
	if _game_started:
		return
	_game_started = true
	_maze.visible = true
	_player.visible = true
	_background.visible = false
	_maze.queue_redraw()
	_player.queue_redraw()
	_player.configure(_maze)
	_start_button.visible = false
	_title.text = "Gato Gloton"
	print("[Main] partida iniciada")
	_status.text = "M1: mueve al gato\nFlechas/WASD o desliza\nVidas: %d | Record: %d" % [
		GameState.lives,
		SaveManager.high_score,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
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


var _swipe_start: Vector2


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
