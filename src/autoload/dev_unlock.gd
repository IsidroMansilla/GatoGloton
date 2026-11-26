extends Node

func _ready() -> void:
	if not OS.is_debug_build():
		return
	if OS.has_feature("android"):
		return
	if DisplayServer.get_name() == "headless":
		return
	_unlock_all()


func _unlock_all() -> void:
	SaveManager.record_level(30)
	if int(SaveManager.stats.get("runs_won", 0)) < 1:
		SaveManager.stats["runs_won"] = 1
	for definition in AchievementCatalog.get_all():
		SaveManager.set_achievement_progress(definition.id, definition.target, false)
	for definition in CosmeticCatalog.get_all():
		SaveManager.set_unlock_state(definition.id, true, false)
	SaveManager.save_game()
	AchievementManager.evaluate(false)
	UnlockManager.evaluate(false)
	UnlockManager.ensure_selection_valid()
	print("[Dev] Desbloqueo total aplicado: logros, cosmeticos, niveles e infierno")
