class_name TutorialScreen
extends Control

signal closed

const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")

const TIPS: Array[String] = [
	"DESLIZA EL DEDO\nPARA MOVERTE",
	"COME TODAS LAS BOLAS\nPARA PASAR DE NIVEL",
	"EL POWER-UP ASUSTA\nA LOS PERROS",
]


func _ready() -> void:
	theme = ARCADE_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func open() -> void:
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
	panel.add_theme_stylebox_override("panel", _panel_style())
	page.add_child(panel)
	var title := _label("COMO JUGAR", Vector2(30.0, 18.0), Vector2(264.0, 30.0), 12, Color("#FDE68A"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var subtitle := _label("TRES REGLAS BASICAS", Vector2(30.0, 52.0), Vector2(264.0, 20.0), 6, Color("#60A5FA"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(subtitle)
	var y := 104.0
	for tip in TIPS:
		var step := _label(tip, Vector2(42.0, y), Vector2(240.0, 62.0), 8, Color("#E5E7EB"))
		step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(step)
		y += 100.0
	var play := _button("ENTENDIDO", Vector2(90.0, 466.0), Vector2(144.0, 52.0), 10)
	play.pressed.connect(func() -> void: closed.emit())
	panel.add_child(play)


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#11152F")
	style.border_color = Color("#273B82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#FDE68A")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
