class_name CosmeticCatalog
extends RefCounted

const CATEGORIES: PackedStringArray = ["player", "rival", "maze"]
const CATEGORY_LABELS: Dictionary = {
	"player": "GATO",
	"rival": "RIVALES",
	"maze": "MAPA",
}
const REQUIRED_COLOR_KEYS: Dictionary = {
	"player": ["primary", "secondary"],
	"rival": ["primary", "secondary", "frightened"],
	"maze": ["wall", "edge", "floor", "dot"],
}
const VALID_RULE_TYPES: PackedStringArray = [
	"always",
	"achievement",
	"high_score",
	"highest_level",
	"runs_started",
	"runs_finished",
	"runs_won",
	"levels_completed",
	"levels_completed_no_damage",
	"pellets_collected",
	"power_pellets_collected",
	"rivals_eaten",
]

static var _cosmetics: Array[CosmeticDefinition] = []


static func get_all() -> Array[CosmeticDefinition]:
	if _cosmetics.is_empty():
		_build()
	return _cosmetics


static func get_by_id(id: String) -> CosmeticDefinition:
	for cosmetic in get_all():
		if cosmetic.id == id:
			return cosmetic
	return null


static func get_category(category: String) -> Array[CosmeticDefinition]:
	var result: Array[CosmeticDefinition] = []
	for cosmetic in get_all():
		if cosmetic.category == category:
			result.append(cosmetic)
	return result


static func get_default_id(category: String) -> String:
	for cosmetic in get_category(category):
		if cosmetic.is_default():
			return cosmetic.id
	return ""


static func get_categories() -> PackedStringArray:
	return CATEGORIES


static func get_category_label(category: String) -> String:
	return String(CATEGORY_LABELS.get(category, category))


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var defaults: Dictionary = {}
	for cosmetic in get_all():
		if cosmetic == null:
			errors.append("El catalogo contiene un cosmetico nulo")
			continue
		if not cosmetic.is_valid():
			errors.append("Cosmetico invalido: %s" % cosmetic.id)
			continue
		if seen.has(cosmetic.id):
			errors.append("Cosmetico duplicado: %s" % cosmetic.id)
		seen[cosmetic.id] = true
		if not CATEGORIES.has(cosmetic.category):
			errors.append("Cosmetico %s usa categoria desconocida: %s" % [cosmetic.id, cosmetic.category])
			continue
		if not VALID_RULE_TYPES.has(cosmetic.rule_type):
			errors.append("Cosmetico %s usa regla desconocida: %s" % [cosmetic.id, cosmetic.rule_type])
		if cosmetic.is_default():
			if defaults.has(cosmetic.category):
				errors.append("Categoria %s tiene mas de un cosmetico por defecto" % cosmetic.category)
			defaults[cosmetic.category] = true
		if cosmetic.rule_type == "achievement" and AchievementCatalog.get_by_id(cosmetic.rule_id) == null:
			errors.append("Cosmetico %s referencia un logro inexistente: %s" % [cosmetic.id, cosmetic.rule_id])
		for key in REQUIRED_COLOR_KEYS.get(cosmetic.category, []):
			if not cosmetic.colors.has(key) or not (cosmetic.colors[key] is Color):
				errors.append("Cosmetico %s no define el color %s" % [cosmetic.id, key])
		if cosmetic.description.is_empty():
			errors.append("Cosmetico %s sin descripcion" % cosmetic.id)
	for category in CATEGORIES:
		if not defaults.has(category):
			errors.append("Categoria %s no tiene cosmetico por defecto" % category)
	return errors


static func _build() -> void:
	_cosmetics = [
		_make(
			"player_ember", "player", "GATO ASCUAS", "El clasico naranja de siempre.",
			"always", 0, "", "Disponible desde el inicio",
			{"primary": Color("#F59E0B"), "secondary": Color("#FBBF24")},
		),
		_make(
			"player_mint", "player", "GATO MENTA", "Pelaje verde para exploradores.",
			"highest_level", 5, "", "Alcanza el nivel 5",
			{"primary": Color("#10B981"), "secondary": Color("#6EE7B7")},
		),
		_make(
			"player_violet", "player", "GATO VIOLETA", "Un pelaje reservado a veteranos.",
			"achievement", 0, "level_10", "Consigue el logro CALLEJON",
			{"primary": Color("#A855F7"), "secondary": Color("#E9D5FF")},
		),
		_make(
			"rival_rose", "rival", "RIVAL ROSA", "El color original de los perseguidores.",
			"always", 0, "", "Disponible desde el inicio",
			{
				"primary": Color("#EC4899"),
				"secondary": Color("#BE185D"),
				"frightened": Color("#60A5FA"),
			},
		),
		_make(
			"rival_frost", "rival", "RIVAL GELIDO", "Rivales frios como el hielo.",
			"runs_finished", 2, "", "Termina 2 partidas",
			{
				"primary": Color("#38BDF8"),
				"secondary": Color("#0EA5E9"),
				"frightened": Color("#93C5FD"),
			},
		),
		_make(
			"rival_shadow", "rival", "RIVAL SOMBRA", "Sombras dificiles de leer.",
			"runs_started", 5, "", "Juega 5 partidas",
			{
				"primary": Color("#64748B"),
				"secondary": Color("#334155"),
				"frightened": Color("#94A3B8"),
			},
		),
		_make(
			"maze_classic", "maze", "MAPA CLASICO", "Azul arcade de toda la vida.",
			"always", 0, "", "Disponible desde el inicio",
			{
				"wall": Color("#2563EB"),
				"edge": Color("#60A5FA"),
				"floor": Color("#0B1220"),
				"dot": Color("#FDE68A"),
			},
		),
		_make(
			"maze_neon", "maze", "MAPA NEON", "Paredes violetas y bordes rosas.",
			"achievement", 0, "score_1000", "Consigue el logro BUEN BOTIN",
			{
				"wall": Color("#7C3AED"),
				"edge": Color("#F472B6"),
				"floor": Color("#120A2E"),
				"dot": Color("#FDE68A"),
			},
		),
		_make(
			"maze_forest", "maze", "MAPA BOSQUE", "Verdes profundos y puntos dorados.",
			"levels_completed", 10, "", "Completa 10 niveles",
			{
				"wall": Color("#15803D"),
				"edge": Color("#86EFAC"),
				"floor": Color("#06140C"),
				"dot": Color("#FDE68A"),
			},
		),
	]


static func _make(
	id: String,
	category: String,
	title: String,
	description: String,
	rule_type: String,
	rule_value: int,
	rule_id: String,
	requirement_text: String,
	colors: Dictionary,
) -> CosmeticDefinition:
	var cosmetic := CosmeticDefinition.new()
	cosmetic.id = id
	cosmetic.category = category
	cosmetic.title = title
	cosmetic.description = description
	cosmetic.rule_type = rule_type
	cosmetic.rule_value = rule_value
	cosmetic.rule_id = rule_id
	cosmetic.requirement_text = requirement_text
	cosmetic.colors = colors
	return cosmetic
