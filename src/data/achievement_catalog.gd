class_name AchievementCatalog
extends RefCounted

const VALID_STAT_KEYS: PackedStringArray = [
	"runs_started",
	"runs_finished",
	"runs_won",
	"levels_completed",
	"levels_completed_no_damage",
	"pellets_collected",
	"power_pellets_collected",
	"rivals_eaten",
	"lives_lost",
	"high_score",
	"highest_level",
]

const REQUIRED_STAT_KEYS: PackedStringArray = [
	"runs_started",
	"runs_finished",
	"runs_won",
	"levels_completed",
	"levels_completed_no_damage",
	"pellets_collected",
	"power_pellets_collected",
	"rivals_eaten",
	"high_score",
	"highest_level",
]

static var _achievements: Array[AchievementDefinition] = []


static func get_all() -> Array[AchievementDefinition]:
	if _achievements.is_empty():
		_build()
	return _achievements


static func get_by_id(id: String) -> AchievementDefinition:
	for achievement in get_all():
		if achievement.id == id:
			return achievement
	return null


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var covered: Dictionary = {}
	for achievement in get_all():
		if achievement == null:
			errors.append("El catalogo contiene un logro nulo")
			continue
		if not achievement.is_valid():
			errors.append("Logro invalido: %s" % achievement.id)
			continue
		if seen.has(achievement.id):
			errors.append("Logro duplicado: %s" % achievement.id)
		seen[achievement.id] = true
		if not VALID_STAT_KEYS.has(achievement.stat_key):
			errors.append("Logro %s usa estadistica desconocida: %s" % [achievement.id, achievement.stat_key])
		covered[achievement.stat_key] = true
		if achievement.description.is_empty():
			errors.append("Logro %s sin descripcion" % achievement.id)
	for key in REQUIRED_STAT_KEYS:
		if not covered.has(key):
			errors.append("Ningun logro usa la estadistica requerida: %s" % key)
	return errors


static func _build() -> void:
	_achievements = [
		_make("first_run", "PRIMER PASEO", "Inicia una partida progresiva.", "runs_started", 1),
		_make("runs_05", "HABITUAL", "Juega 5 partidas progresivas.", "runs_started", 5),
		_make("runs_20", "INCANSABLE", "Juega 20 partidas progresivas.", "runs_started", 20),
		_make("level_05", "EXPLORADOR", "Alcanza el nivel 5.", "highest_level", 5),
		_make("level_10", "CALLEJON", "Alcanza el nivel 10.", "highest_level", 10),
		_make("level_20", "VETERANO", "Alcanza el nivel 20.", "highest_level", 20),
		_make("level_30", "LEYENDA", "Alcanza el nivel 30.", "highest_level", 30),
		_make("runs_finished_03", "RESISTENTE", "Termina 3 partidas por game over.", "runs_finished", 3),
		_make("runs_won_01", "CAMPEON", "Supera los 30 niveles en una partida.", "runs_won", 1),
		_make("flawless_01", "IMPECABLE", "Completa un nivel sin perder vidas.", "levels_completed_no_damage", 1),
		_make("flawless_10", "PERFECCIONISTA", "Completa 10 niveles sin perder vidas.", "levels_completed_no_damage", 10),
		_make("levels_10", "SUPERACION", "Completa 10 niveles.", "levels_completed", 10),
		_make("score_1000", "BUEN BOTIN", "Alcanza 1000 puntos.", "high_score", 1000),
		_make("score_5000", "GRAN BOTIN", "Alcanza 5000 puntos.", "high_score", 5000),
		_make("power_10", "PODEROSO", "Recoge 10 power-ups.", "power_pellets_collected", 10),
		_make("pellets_100", "RECOLECTOR", "Recoge 100 bolas de pelo.", "pellets_collected", 100),
		_make("rivals_10", "CAZADOR", "Come 10 perros rivales.", "rivals_eaten", 10),
	]


static func _make(
	id: String,
	title: String,
	description: String,
	stat_key: String,
	target: int,
	reward_cosmetic_id: String = "",
) -> AchievementDefinition:
	var achievement := AchievementDefinition.new()
	achievement.id = id
	achievement.title = title
	achievement.description = description
	achievement.stat_key = stat_key
	achievement.target = target
	achievement.reward_cosmetic_id = reward_cosmetic_id
	return achievement
