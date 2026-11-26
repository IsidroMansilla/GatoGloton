class_name HellSelectScreen
extends Control

signal level_selected(level_number: int)
signal closed

const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")

var _selected_level: int = 1
var _level_slider: HSlider
var _level_label: Label
var _best_label: Label


func _ready() -> void:
	theme = ARCADE_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func open() -> void:
	_level_slider.value = _selected_level
	refresh()
	visible = true


func refresh() -> void:
	_selected_level = int(_level_slider.value)
	_level_label.text = "NIVEL %02d" % _selected_level
	var best := SaveManager.get_hell_best_time(_selected_level)
	_best_label.text = ("MEJOR: " + HellRules.format_time(best)) if best > 0.0 else "SIN RECORD"
	_best_label.add_theme_color_override("font_color", Color("#FDE68A") if best > 0.0 else Color("#6B7280"))


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
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#1A0A0A"), Color("#DC2626")))
	page.add_child(panel)
	var title := _label("MODO INFIERNO", Vector2(30.0, 18.0), Vector2(264.0, 30.0), 12, Color("#F87171"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var subtitle := _label("AGUANTA Y BATE EL RECORD", Vector2(30.0, 50.0), Vector2(264.0, 20.0), 6, Color("#FDBA74"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(subtitle)
	var warning := _label("1 VIDA  -  SIN BOLAS  -  OLEADAS", Vector2(30.0, 80.0), Vector2(264.0, 20.0), 6, Color("#FCA5A5"))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(warning)
	_level_label = _label("NIVEL 01", Vector2(30.0, 122.0), Vector2(264.0, 36.0), 18, Color("#FDE68A"))
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_level_label)
	_level_slider = HSlider.new()
	_level_slider.position = Vector2(42.0, 176.0)
	_level_slider.size = Vector2(240.0, 28.0)
	_level_slider.min_value = 1.0
	_level_slider.max_value = float(HellRules.LEVEL_COUNT)
	_level_slider.step = 1.0
	_level_slider.value = _selected_level
	_level_slider.value_changed.connect(func(_value: float) -> void: refresh())
	panel.add_child(_level_slider)
	_best_label = _label("SIN RECORD", Vector2(30.0, 220.0), Vector2(264.0, 24.0), 8, Color("#6B7280"))
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_best_label)
	var info := _label(
		"Empiezas con 1 demonio.\nAparecen mas cada pocos segundos.\nMas tiempo, mas peligro.",
		Vector2(34.0, 270.0),
		Vector2(256.0, 54.0),
		6,
		Color("#CBD5E1"),
	)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(info)
	var play := _button("JUGAR", Vector2(42.0, 380.0), Vector2(114.0, 52.0))
	play.add_theme_stylebox_override("normal", _button_style(Color("#B91C1C")))
	play.pressed.connect(func() -> void: level_selected.emit(int(_level_slider.value)))
	panel.add_child(play)
	var back := _button("VOLVER", Vector2(168.0, 380.0), Vector2(114.0, 52.0))
	back.pressed.connect(func() -> void: closed.emit())
	panel.add_child(back)


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_stylebox_override("normal", _button_style(Color("#F97316")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#C8320A")))
	return button


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#FDE68A")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
