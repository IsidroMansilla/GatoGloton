class_name CosmeticDefinition
extends Resource

@export var id: String = ""
@export var category: String = ""
@export var title: String = ""
@export var description: String = ""
@export var rule_type: String = "always"
@export var rule_value: int = 0
@export var rule_id: String = ""
@export var requirement_text: String = ""
@export var colors: Dictionary = {}


func is_default() -> bool:
	return rule_type == "always"


func is_valid() -> bool:
	if id.is_empty() or category.is_empty() or title.is_empty():
		return false
	if rule_type == "always":
		return true
	if rule_type == "achievement":
		return not rule_id.is_empty()
	return rule_value > 0


func requirement_met(
	stats: Dictionary,
	high_score: int,
	highest_level: int,
	completed_achievements: Dictionary,
) -> bool:
	if rule_type == "always":
		return true
	if rule_type == "achievement":
		return bool(completed_achievements.get(rule_id, false))
	var value := 0
	match rule_type:
		"high_score":
			value = high_score
		"highest_level":
			value = highest_level
		_:
			value = int(stats.get(rule_type, 0))
	return value >= rule_value
