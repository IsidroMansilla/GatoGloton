class_name AchievementsScreen
extends Control

signal closed

const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")

var _summary: Label
var _list: VBoxContainer


func _ready() -> void:
	theme = ARCADE_THEME
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func open() -> void:
	refresh()
	visible = true


func refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var definitions := AchievementCatalog.get_all()
	for definition in definitions:
		_list.add_child(_build_card(definition))
	_summary.text = "%d / %d COMPLETADOS" % [AchievementManager.get_completed_count(), definitions.size()]


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color("#070817")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(18.0, 42.0)
	panel.size = Vector2(324.0, 550.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#11152F"), Color("#273B82")))
	add_child(panel)
	var title := _label("LOGROS", Vector2(30.0, 18.0), Vector2(264.0, 30.0), 12, Color("#FDE68A"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_summary = _label("", Vector2(30.0, 48.0), Vector2(264.0, 22.0), 7, Color("#60A5FA"))
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(22.0, 78.0)
	scroll.size = Vector2(280.0, 376.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	var back := _button("VOLVER", Vector2(90.0, 466.0), Vector2(144.0, 52.0))
	back.pressed.connect(func() -> void: closed.emit())
	panel.add_child(back)


func _build_card(definition: AchievementDefinition) -> PanelContainer:
	var progress := AchievementManager.get_progress(definition.id)
	var completed := progress >= definition.target
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("#11152F"), Color("#22C55E") if completed else Color("#273B82")),
	)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	box.add_child(header)
	var title := _label(definition.title, Vector2.ZERO, Vector2.ZERO, 8, Color("#FDE68A") if completed else Color("#E5E7EB"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var status := _label("COMPLETADO" if completed else "PENDIENTE", Vector2.ZERO, Vector2.ZERO, 6, Color("#22C55E") if completed else Color("#93C5FD"))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(status)
	var description := _label(definition.description, Vector2.ZERO, Vector2.ZERO, 6, Color("#CBD5E1"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0.0, 7.0)
	bar.min_value = 0.0
	bar.max_value = float(definition.target)
	bar.value = float(mini(progress, definition.target))
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bar_style(Color("#1F2937")))
	bar.add_theme_stylebox_override("fill", _bar_style(Color("#22C55E") if completed else Color("#F97316")))
	box.add_child(bar)
	var progress_label := _label(
		"COMPLETADO" if completed else "PROGRESO %d / %d" % [mini(progress, definition.target), definition.target],
		Vector2.ZERO,
		Vector2.ZERO,
		6,
		Color("#22C55E") if completed else Color("#93C5FD"),
	)
	box.add_child(progress_label)
	return card


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
	style.set_corner_radius_all(6)
	return style


func _bar_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(2)
	return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#FDE68A")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
