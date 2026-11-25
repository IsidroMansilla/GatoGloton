class_name AchievementDefinition
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var stat_key: String = ""
@export var target: int = 1
@export var reward_cosmetic_id: String = ""


func is_valid() -> bool:
	return not id.is_empty() and not title.is_empty() and not stat_key.is_empty() and target > 0


func current_value(stats: Dictionary, high_score: int, highest_level: int) -> int:
	match stat_key:
		"high_score":
			return high_score
		"highest_level":
			return highest_level
		_:
			return int(stats.get(stat_key, 0))
