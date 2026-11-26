class_name SettingsScreen
extends Control

signal closed

const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")
const VOLUME_MIN_DB: float = -40.0
const VOLUME_MAX_DB: float = 0.0
const RESET_CONFIRM_SECONDS: float = 3.0

var _sound_toggle: Button
var _vibration_toggle: Button
var _motion_toggle: Button
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _reset_button: Button
var _reset_armed: bool = false
var _reset_time_left: float = 0.0
var _refreshing: bool = false


func _ready() -> void:
	theme = ARCADE_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func _process(delta: float) -> void:
	if not _reset_armed:
		return
	_reset_time_left -= delta
	if _reset_time_left <= 0.0:
		_disarm_reset()


func open() -> void:
	_disarm_reset()
	_refresh()
	visible = true


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color("#070817")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var page := SafeAreaPage.new()
	add_child(page)
	var panel := Panel.new()
	panel.position = Vector2(18.0, 42.0)
	panel.size = Vector2(324.0, 550.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#11152F"), Color("#273B82")))
	page.add_child(panel)
	var title := _label("AJUSTES", Vector2(30.0, 18.0), Vector2(264.0, 30.0), 12, Color("#FDE68A"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var subtitle := _label("PREFERENCIAS", Vector2(30.0, 50.0), Vector2(264.0, 20.0), 6, Color("#60A5FA"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(subtitle)
	panel.add_child(_label("SONIDO", Vector2(30.0, 86.0), Vector2(160.0, 30.0), 7, Color("#E5E7EB")))
	_sound_toggle = _toggle_button(Vector2(212.0, 82.0), Vector2(82.0, 32.0))
	_sound_toggle.pressed.connect(_on_sound_toggled)
	panel.add_child(_sound_toggle)
	panel.add_child(_label("MUSICA", Vector2(30.0, 130.0), Vector2(110.0, 22.0), 7, Color("#E5E7EB")))
	_music_slider = _volume_slider(Vector2(146.0, 128.0))
	_music_value = _label("", Vector2(256.0, 130.0), Vector2(38.0, 22.0), 6, Color("#93C5FD"))
	_music_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_music_slider)
	panel.add_child(_music_value)
	panel.add_child(_label("EFECTOS", Vector2(30.0, 170.0), Vector2(110.0, 22.0), 7, Color("#E5E7EB")))
	_sfx_slider = _volume_slider(Vector2(146.0, 168.0))
	_sfx_value = _label("", Vector2(256.0, 170.0), Vector2(38.0, 22.0), 6, Color("#93C5FD"))
	_sfx_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_sfx_slider)
	panel.add_child(_sfx_value)
	panel.add_child(_label("VIBRACION", Vector2(30.0, 214.0), Vector2(160.0, 30.0), 7, Color("#E5E7EB")))
	_vibration_toggle = _toggle_button(Vector2(212.0, 210.0), Vector2(82.0, 32.0))
	_vibration_toggle.pressed.connect(_on_vibration_toggled)
	panel.add_child(_vibration_toggle)
	var motion_label := _label("REDUCIR MOVIMIENTO", Vector2(30.0, 258.0), Vector2(170.0, 34.0), 6, Color("#E5E7EB"))
	motion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(motion_label)
	_motion_toggle = _toggle_button(Vector2(212.0, 256.0), Vector2(82.0, 32.0))
	_motion_toggle.pressed.connect(_on_motion_toggled)
	panel.add_child(_motion_toggle)
	_reset_button = _button("REINICIAR PROGRESO", Vector2(42.0, 320.0), Vector2(240.0, 44.0), 8)
	_reset_button.pressed.connect(_on_reset_pressed)
	panel.add_child(_reset_button)
	var hint := _label(
		"Borra record, logros,\ndesbloqueos y records.\nConserva los ajustes.",
		Vector2(42.0, 374.0),
		Vector2(240.0, 52.0),
		6,
		Color("#94A3B8"),
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(hint)
	var back := _button("VOLVER", Vector2(90.0, 466.0), Vector2(144.0, 52.0), 10)
	back.pressed.connect(func() -> void: closed.emit())
	panel.add_child(back)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.drag_ended.connect(_on_volume_drag_ended)
	_sfx_slider.drag_ended.connect(_on_volume_drag_ended)


func _refresh() -> void:
	_refreshing = true
	_update_toggle(_sound_toggle, not AudioManager.muted)
	_update_toggle(_vibration_toggle, bool(SaveManager.get_setting("vibration", true)))
	_update_toggle(_motion_toggle, bool(SaveManager.get_setting("reduce_motion", false)))
	_music_slider.value = _db_to_percent(AudioManager.music_volume_db)
	_sfx_slider.value = _db_to_percent(AudioManager.sfx_volume_db)
	_update_volume_labels()
	_refreshing = false


func _update_volume_labels() -> void:
	_music_value.text = "%d%%" % int(round(_music_slider.value))
	_sfx_value.text = "%d%%" % int(round(_sfx_slider.value))


func _on_sound_toggled() -> void:
	AudioManager.set_muted(not AudioManager.muted)
	_update_toggle(_sound_toggle, not AudioManager.muted)


func _on_vibration_toggled() -> void:
	var enabled := bool(SaveManager.get_setting("vibration", true))
	SaveManager.set_setting("vibration", not enabled)
	_update_toggle(_vibration_toggle, not enabled)


func _on_motion_toggled() -> void:
	var enabled := bool(SaveManager.get_setting("reduce_motion", false))
	SaveManager.set_setting("reduce_motion", not enabled)
	_update_toggle(_motion_toggle, not enabled)


func _on_music_changed(value: float) -> void:
	if not _refreshing:
		AudioManager.set_music_volume_db(_percent_to_db(value), false)
	_update_volume_labels()


func _on_sfx_changed(value: float) -> void:
	if not _refreshing:
		AudioManager.set_sfx_volume_db(_percent_to_db(value), false)
	_update_volume_labels()


func _on_volume_drag_ended(_value_changed: bool) -> void:
	SaveManager.save_game()


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_time_left = RESET_CONFIRM_SECONDS
		_reset_button.text = "PULSA OTRA VEZ"
		return
	_disarm_reset()
	SaveManager.reset_progress()


func _disarm_reset() -> void:
	_reset_armed = false
	_reset_time_left = 0.0
	if _reset_button != null:
		_reset_button.text = "REINICIAR PROGRESO"


func _update_toggle(button: Button, enabled: bool) -> void:
	button.text = "SI" if enabled else "NO"
	button.add_theme_stylebox_override("normal", _toggle_style(enabled))
	button.add_theme_stylebox_override("pressed", _toggle_style(enabled))
	button.add_theme_stylebox_override("hover", _toggle_style(enabled))


func _db_to_percent(db: float) -> float:
	return clampf((db - VOLUME_MIN_DB) / (VOLUME_MAX_DB - VOLUME_MIN_DB) * 100.0, 0.0, 100.0)


func _percent_to_db(percent: float) -> float:
	return lerpf(VOLUME_MIN_DB, VOLUME_MAX_DB, clampf(percent, 0.0, 100.0) / 100.0)


func _volume_slider(position: Vector2) -> HSlider:
	var slider := HSlider.new()
	slider.position = position
	slider.size = Vector2(104.0, 24.0)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	return slider


func _toggle_button(position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 7)
	return button


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, position: Vector2, size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _button_style(Color("#F97316")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#C8320A")))
	return button


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _toggle_style(enabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#22C55E") if enabled else Color("#1F2937")
	style.border_color = Color("#FDE68A") if enabled else Color("#273B82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#FDE68A")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
