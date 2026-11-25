class_name CosmeticCatalog
extends RefCounted

const CATEGORIES: PackedStringArray = ["player", "rival", "maze", "pellets", "effects", "sfx", "music"]
const CATEGORY_LABELS: Dictionary = {
	"player": "GATO",
	"rival": "PERROS",
	"maze": "MAPA",
	"pellets": "BOLAS",
	"effects": "EFECTOS",
	"sfx": "SONIDO",
	"music": "MUSICA",
}
const REQUIRED_COLOR_KEYS: Dictionary = {
	"player": ["primary", "secondary"],
	"rival": ["primary", "secondary", "frightened"],
	"maze": ["wall", "edge", "floor", "dot"],
	"pellets": ["pellet", "power"],
	"effects": ["burst", "ring"],
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
		if cosmetic.category == "sfx" and not ["classic", "chip", "deep"].has(String(cosmetic.data.get("style", ""))):
			errors.append("Cosmetico %s define un estilo de sonido invalido" % cosmetic.id)
		if cosmetic.category == "music" and not ["", "arcade", "night"].has(String(cosmetic.data.get("track", ""))):
			errors.append("Cosmetico %s define una pista de musica invalida" % cosmetic.id)
		if cosmetic.category == "effects" and not (cosmetic.data.get("burst", false) is bool):
			errors.append("Cosmetico %s define burst invalido" % cosmetic.id)
		if cosmetic.category == "pellets" and not (cosmetic.data.get("power_ring", false) is bool):
			errors.append("Cosmetico %s define power_ring invalido" % cosmetic.id)
		if cosmetic.description.is_empty():
			errors.append("Cosmetico %s sin descripcion" % cosmetic.id)
	for category in CATEGORIES:
		if not defaults.has(category):
			errors.append("Categoria %s no tiene cosmetico por defecto" % category)
	return errors


static func validate_contrast() -> PackedStringArray:
	var errors := PackedStringArray()
	var floors: Array[Color] = []
	for maze in get_category("maze"):
		var floor: Color = maze.colors.get("floor", Color.BLACK)
		var wall: Color = maze.colors.get("wall", Color.BLACK)
		var edge: Color = maze.colors.get("edge", Color.BLACK)
		floors.append(floor)
		_check_contrast(errors, maze.id, "pared/suelo", wall, floor, 2.0)
		_check_contrast(errors, maze.id, "borde/pared", edge, wall, 1.4)
	for item in get_category("player"):
		for floor in floors:
			_check_contrast(errors, item.id, "gato/suelo", item.colors.get("primary", Color.BLACK), floor, 3.0)
	for item in get_category("rival"):
		for floor in floors:
			var primary: Color = item.colors.get("primary", Color.BLACK)
			var outline: Color = item.colors.get("secondary", primary)
			var visible_contrast := maxf(contrast_ratio(primary, floor), contrast_ratio(outline, floor))
			if visible_contrast < 3.0:
				errors.append("%s: contraste perro/suelo %.2f < 3.0" % [item.id, visible_contrast])
			_check_contrast(errors, item.id, "perro asustado/suelo", item.colors.get("frightened", Color.BLACK), floor, 2.5)
	for item in get_category("pellets"):
		for floor in floors:
			_check_contrast(errors, item.id, "bola/suelo", item.colors.get("pellet", Color.BLACK), floor, 4.0)
			_check_contrast(errors, item.id, "power-up/suelo", item.colors.get("power", Color.BLACK), floor, 4.0)
	for item in get_category("effects"):
		for floor in floors:
			_check_contrast(errors, item.id, "efecto/suelo", item.colors.get("burst", Color.BLACK), floor, 3.0)
	return errors


static func contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	var lighter := maxf(first_luminance, second_luminance)
	var darker := minf(first_luminance, second_luminance)
	return (lighter + 0.05) / (darker + 0.05)


static func _check_contrast(errors: PackedStringArray, id: String, label: String, first: Color, second: Color, minimum: float) -> void:
	var ratio := contrast_ratio(first, second)
	if ratio < minimum:
		errors.append("%s: contraste %s %.2f < %.1f" % [id, label, ratio, minimum])


static func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)


static func _linear_channel(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return pow((value + 0.055) / 1.055, 2.4)


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
			"rival_rose", "rival", "DOBERMAN", "Negro con bordes marron, como un doberman.",
			"always", 0, "", "Disponible desde el inicio",
			{
				"primary": Color("#111827"),
				"secondary": Color("#B45309"),
				"frightened": Color("#60A5FA"),
			},
		),
		_make(
			"rival_frost", "rival", "PERRO GELIDO", "Perros frios como el hielo.",
			"runs_finished", 2, "", "Termina 2 partidas",
			{
				"primary": Color("#38BDF8"),
				"secondary": Color("#0EA5E9"),
				"frightened": Color("#93C5FD"),
			},
		),
		_make(
			"rival_shadow", "rival", "PERRO SOMBRA", "Sombras dificiles de leer.",
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
		_make(
			"pellets_classic", "pellets", "BOLAS CLASICAS", "Bolas doradas y power-ups amarillos.",
			"always", 0, "", "Disponible desde el inicio",
			{"pellet": Color("#FDE68A"), "power": Color("#FACC15")},
			{"power_ring": false},
		),
		_make(
			"pellets_candy", "pellets", "BOLAS DE CARAMELO", "Rosa y violeta con aro en los power-ups.",
			"achievement", 0, "pellets_100", "Consigue el logro RECOLECTOR",
			{"pellet": Color("#F472B6"), "power": Color("#A78BFA")},
			{"power_ring": true},
		),
		_make(
			"pellets_mint", "pellets", "BOLAS DE MENTA", "Verdes frescas y power-ups esmeralda.",
			"highest_level", 10, "", "Alcanza el nivel 10",
			{"pellet": Color("#6EE7B7"), "power": Color("#34D399")},
			{"power_ring": false},
		),
		_make(
			"effects_classic", "effects", "EFECTOS CLASICOS", "Sin estelas: solo el laberinto.",
			"always", 0, "", "Disponible desde el inicio",
			{"burst": Color("#FDE68A"), "ring": Color("#F59E0B")},
			{"burst": false, "particles": false},
		),
		_make(
			"effects_spark", "effects", "CHISPAS", "Aros y particulas al recoger bolas.",
			"achievement", 0, "power_10", "Consigue el logro PODEROSO",
			{"burst": Color("#F472B6"), "ring": Color("#A78BFA")},
			{"burst": true, "particles": true},
		),
		_make(
			"effects_minimal", "effects", "PULSO MINIMAL", "Un aro limpio al recoger bolas.",
			"achievement", 0, "flawless_01", "Consigue el logro IMPECABLE",
			{"burst": Color("#93C5FD"), "ring": Color("#60A5FA")},
			{"burst": true, "particles": false},
		),
		_make(
			"sfx_classic", "sfx", "SONIDO CLASICO", "Ondas seno limpias y reconocibles.",
			"always", 0, "", "Disponible desde el inicio",
			{},
			{"style": "classic"},
		),
		_make(
			"sfx_chip", "sfx", "SONIDO CHIP", "Ondas cuadradas de consola antigua.",
			"achievement", 0, "pellets_100", "Consigue el logro RECOLECTOR",
			{},
			{"style": "chip"},
		),
		_make(
			"sfx_deep", "sfx", "SONIDO GRAVE", "Tono mas bajo con suboctava.",
			"runs_finished", 3, "", "Termina 3 partidas",
			{},
			{"style": "deep"},
		),
		_make(
			"music_off", "music", "SIN MUSICA", "Solo efectos de sonido.",
			"always", 0, "", "Disponible desde el inicio",
			{},
			{"track": ""},
		),
		_make(
			"music_arcade", "music", "MUSICA ARCADE", "Melodia cuadrada alegre en bucle.",
			"highest_level", 5, "", "Alcanza el nivel 5",
			{},
			{"track": "arcade"},
		),
		_make(
			"music_night", "music", "MUSICA NOCTURNA", "Melodia lenta y misteriosa.",
			"runs_started", 5, "", "Juega 5 partidas",
			{},
			{"track": "night"},
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
	data: Dictionary = {},
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
	cosmetic.data = data
	return cosmetic
