class_name CustomizationScreen
extends Control

signal closed

const ARCADE_THEME: Theme = preload("res://assets/fonts/arcade_theme.tres")

var _category: String = "player"
var _summary: Label
var _list: VBoxContainer
var _tab_buttons: Dictionary = {}


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
	var items := UnlockManager.get_items(_category)
	for item in items:
		_list.add_child(_build_card(item))
	_summary.text = "%d / %d DESBLOQUEADOS" % [UnlockManager.get_unlocked_count(_category), items.size()]
	_refresh_tabs()


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
	var title := _label("PERSONALIZAR", Vector2(30.0, 18.0), Vector2(264.0, 30.0), 12, Color("#FDE68A"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_summary = _label("", Vector2(30.0, 46.0), Vector2(264.0, 20.0), 6, Color("#60A5FA"))
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_summary)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(24.0, 70.0)
	tabs.size = Vector2(276.0, 32.0)
	tabs.add_theme_constant_override("separation", 6)
	panel.add_child(tabs)
	for category in CosmeticCatalog.get_categories():
		var key := category
		var button := _tab_button(CosmeticCatalog.get_category_label(category))
		button.pressed.connect(func() -> void:
			_category = key
			refresh()
		)
		_tab_buttons[category] = button
		tabs.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(22.0, 108.0)
	scroll.size = Vector2(280.0, 344.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	var back := _button("VOLVER", Vector2(90.0, 466.0), Vector2(144.0, 52.0))
	back.pressed.connect(func() -> void: closed.emit())
	panel.add_child(back)


func _refresh_tabs() -> void:
	for category in _tab_buttons.keys():
		var button: Button = _tab_buttons[category]
		var selected: bool = String(category) == _category
		button.add_theme_stylebox_override("normal", _tab_style(selected))
		button.add_theme_stylebox_override("pressed", _tab_style(selected))
		button.add_theme_stylebox_override("hover", _tab_style(selected))


func _build_card(definition: CosmeticDefinition) -> PanelContainer:
	var unlocked := UnlockManager.is_unlocked(definition.id)
	var selected := UnlockManager.get_selected(_category) == definition.id
	var border := Color("#22C55E") if selected else (Color("#273B82") if unlocked else Color("#7F1D1D"))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("#11152F"), border))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var swatches := VBoxContainer.new()
	swatches.add_theme_constant_override("separation", 2)
	row.add_child(swatches)
	var primary_key := "wall" if _category == "maze" else "primary"
	var secondary_key := "edge" if _category == "maze" else "secondary"
	swatches.add_child(_swatch(definition.colors.get(primary_key, Color("#1F2937"))))
	swatches.add_child(_swatch(definition.colors.get(secondary_key, Color("#1F2937"))))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	info.add_child(_label(definition.title, Vector2.ZERO, Vector2.ZERO, 8, Color("#E5E7EB")))
	var description := _label(definition.description, Vector2.ZERO, Vector2.ZERO, 6, Color("#CBD5E1"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(description)
	var status_text := "EN USO" if selected else ("DISPONIBLE" if unlocked else "BLOQUEADO: " + definition.requirement_text)
	var status_color := Color("#22C55E") if selected else (Color("#93C5FD") if unlocked else Color("#F87171"))
	var status := _label(status_text, Vector2.ZERO, Vector2.ZERO, 6, status_color)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(status)
	var action := _button("EQUIPADO" if selected else ("USAR" if unlocked else "BLOQ."), Vector2.ZERO, Vector2(64.0, 32.0))
	action.custom_minimum_size = Vector2(64.0, 32.0)
	action.add_theme_font_size_override("font_size", 6)
	action.disabled = selected or not unlocked
	if not action.disabled:
		var item_id := definition.id
		action.pressed.connect(func() -> void:
			if UnlockManager.select_cosmetic(_category, item_id):
				refresh()
		)
	row.add_child(action)
	return card


func _swatch(color: Variant) -> ColorRect:
	var rect := ColorRect.new()
	rect.custom_minimum_size = Vector2(18.0, 18.0)
	rect.color = color if color is Color else Color("#1F2937")
	return rect


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _tab_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 7)
	button.add_theme_stylebox_override("normal", _tab_style(false))
	button.add_theme_stylebox_override("pressed", _tab_style(false))
	button.add_theme_stylebox_override("hover", _tab_style(false))
	return button


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


func _tab_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#F97316") if selected else Color("#11152F")
	style.border_color = Color("#FDE68A") if selected else Color("#273B82")
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
