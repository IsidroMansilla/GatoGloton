extends Node

signal cosmetic_unlocked(id: String)
signal unlocks_changed
signal cosmetics_changed(category: String, id: String)

var _definitions: Array[CosmeticDefinition] = []


func _ready() -> void:
	_definitions = CosmeticCatalog.get_all()
	SaveManager.stats_changed.connect(_on_stats_changed)
	SaveManager.high_score_changed.connect(_on_high_score_changed)
	SaveManager.highest_level_changed.connect(_on_highest_level_changed)
	SaveManager.progress_reset.connect(_on_progress_reset)
	AchievementManager.achievements_changed.connect(_on_achievements_changed)
	evaluate(false)
	ensure_selection_valid()


func evaluate(notify: bool = true) -> void:
	var completed := AchievementManager.get_completed_achievements()
	var newly_unlocked: Array[String] = []
	for definition in _definitions:
		if SaveManager.get_unlock_state(definition.id):
			continue
		if definition.requirement_met(SaveManager.get_stats(), SaveManager.high_score, SaveManager.highest_level, completed):
			SaveManager.set_unlock_state(definition.id, true, false)
			newly_unlocked.append(definition.id)
	if newly_unlocked.is_empty():
		return
	SaveManager.save_game()
	unlocks_changed.emit()
	if notify:
		for id in newly_unlocked:
			cosmetic_unlocked.emit(id)


func ensure_selection_valid() -> void:
	var changed_categories: Array[String] = []
	for category in CosmeticCatalog.get_categories():
		var selected := SaveManager.get_cosmetic(category)
		var definition := CosmeticCatalog.get_by_id(selected)
		var valid := definition != null and definition.category == category and is_unlocked(selected)
		if valid:
			continue
		var default_id := CosmeticCatalog.get_default_id(category)
		SaveManager.set_cosmetic(category, default_id, false)
		changed_categories.append(category)
	if changed_categories.is_empty():
		return
	SaveManager.save_game()
	for category in changed_categories:
		cosmetics_changed.emit(category, SaveManager.get_cosmetic(category))


func is_unlocked(id: String) -> bool:
	var definition := CosmeticCatalog.get_by_id(id)
	if definition == null:
		return false
	return definition.is_default() or SaveManager.get_unlock_state(id)


func get_selected(category: String) -> String:
	var selected := SaveManager.get_cosmetic(category)
	if is_unlocked(selected) and CosmeticCatalog.get_by_id(selected) != null:
		return selected
	return CosmeticCatalog.get_default_id(category)


func get_selected_definition(category: String) -> CosmeticDefinition:
	return CosmeticCatalog.get_by_id(get_selected(category))


func get_palette(category: String) -> Dictionary:
	var definition := get_selected_definition(category)
	if definition == null:
		return {}
	return definition.colors.duplicate(true)


func get_data(category: String) -> Dictionary:
	var definition := get_selected_definition(category)
	if definition == null:
		return {}
	return definition.data.duplicate(true)


func get_items(category: String) -> Array[CosmeticDefinition]:
	return CosmeticCatalog.get_category(category)


func get_unlocked_count(category: String) -> int:
	var total := 0
	for definition in get_items(category):
		if is_unlocked(definition.id):
			total += 1
	return total


func select_cosmetic(category: String, id: String) -> bool:
	var definition := CosmeticCatalog.get_by_id(id)
	if definition == null or definition.category != category or not is_unlocked(id):
		return false
	if SaveManager.get_cosmetic(category) == id:
		return true
	SaveManager.set_cosmetic(category, id)
	cosmetics_changed.emit(category, id)
	return true


func _on_stats_changed(_stats: Dictionary) -> void:
	evaluate()


func _on_high_score_changed(_value: int) -> void:
	evaluate()


func _on_highest_level_changed(_value: int) -> void:
	evaluate()


func _on_achievements_changed() -> void:
	evaluate()


func _on_progress_reset() -> void:
	evaluate(false)
	ensure_selection_valid()
