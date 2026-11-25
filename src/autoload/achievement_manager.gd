extends Node

signal achievement_unlocked(id: String)
signal achievements_changed

var _definitions: Array[AchievementDefinition] = []


func _ready() -> void:
	_definitions = AchievementCatalog.get_all()
	SaveManager.stats_changed.connect(_on_stats_changed)
	SaveManager.high_score_changed.connect(_on_high_score_changed)
	SaveManager.highest_level_changed.connect(_on_highest_level_changed)
	evaluate(false)


func evaluate(notify: bool = true) -> void:
	var newly_completed: Array[String] = []
	for definition in _definitions:
		var current := mini(
			definition.current_value(SaveManager.get_stats(), SaveManager.high_score, SaveManager.highest_level),
			definition.target,
		)
		var previous := SaveManager.get_achievement_progress(definition.id)
		var best := maxi(previous, current)
		if best != previous:
			SaveManager.set_achievement_progress(definition.id, best, false)
		if best >= definition.target and previous < definition.target:
			newly_completed.append(definition.id)
	if not newly_completed.is_empty():
		SaveManager.save_game()
		if notify:
			for id in newly_completed:
				achievement_unlocked.emit(id)
		achievements_changed.emit()


func get_definitions() -> Array[AchievementDefinition]:
	return _definitions


func get_progress(id: String) -> int:
	return SaveManager.get_achievement_progress(id)


func get_target(id: String) -> int:
	var definition := AchievementCatalog.get_by_id(id)
	return definition.target if definition != null else 0


func is_completed(id: String) -> bool:
	var definition := AchievementCatalog.get_by_id(id)
	return definition != null and SaveManager.get_achievement_progress(id) >= definition.target


func get_completed_count() -> int:
	var total := 0
	for definition in _definitions:
		if SaveManager.get_achievement_progress(definition.id) >= definition.target:
			total += 1
	return total


func get_completed_achievements() -> Dictionary:
	var completed := {}
	for definition in _definitions:
		if SaveManager.get_achievement_progress(definition.id) >= definition.target:
			completed[definition.id] = true
	return completed


func _on_stats_changed(_stats: Dictionary) -> void:
	evaluate()


func _on_high_score_changed(_value: int) -> void:
	evaluate()


func _on_highest_level_changed(_value: int) -> void:
	evaluate()
