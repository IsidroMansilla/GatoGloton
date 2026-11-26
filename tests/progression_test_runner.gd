extends SceneTree

var passed: int = 0
var failed: int = 0
var _uses_quit_after: bool = false
var _achievement_manager: Variant
var _unlock_manager: Variant
var _interstitial_seen: bool = false


func _initialize() -> void:
	_uses_quit_after = _detect_quit_after()
	await process_frame
	_achievement_manager = root.get_node_or_null("AchievementManager")
	_unlock_manager = root.get_node_or_null("UnlockManager")
	_test_achievement_catalog()
	_test_achievement_progress()
	_test_cosmetic_catalog()
	_test_cosmetic_rules()
	_test_contrast()
	_test_manager_api()
	_test_audio_styles()
	_test_ads_interstitial()
	await process_frame
	print("Progression test: %d passed, %d failed" % [passed, failed])
	if failed > 0 or not _uses_quit_after:
		call_deferred("quit", 1 if failed > 0 else 0)


func _test_achievement_catalog() -> void:
	var errors := AchievementCatalog.validate()
	_check(errors.is_empty(), "catalogo de logros valido: %s" % ", ".join(errors))
	var definitions := AchievementCatalog.get_all()
	_check(definitions.size() >= 15, "catalogo de logros amplio")
	_check(AchievementCatalog.get_by_id("level_30") != null, "existe logro de nivel 30")
	_check(AchievementCatalog.get_by_id("runs_won_01") != null, "existe logro de partida ganada")
	_check(AchievementCatalog.get_by_id("flawless_01") != null, "existe logro de nivel sin dano")
	_check(AchievementCatalog.get_by_id("score_1000") != null, "existe logro de puntuacion")
	_check(AchievementCatalog.get_by_id("power_10") != null, "existe logro de power-ups")
	var ids: Dictionary = {}
	for definition in definitions:
		ids[definition.id] = true
	_check(ids.size() == definitions.size(), "ids de logros unicos")


func _test_achievement_progress() -> void:
	var level := AchievementCatalog.get_by_id("level_10")
	_check(level.current_value({}, 0, 7) == 7, "logro de nivel lee highest_level")
	_check(level.current_value({}, 0, 12) == 12, "logro de nivel supera objetivo")
	var score := AchievementCatalog.get_by_id("score_1000")
	_check(score.current_value({}, 1500, 1) == 1500, "logro de puntuacion lee high_score")
	var runs := AchievementCatalog.get_by_id("runs_05")
	_check(runs.current_value({"runs_started": 3}, 0, 1) == 3, "logro de partidas lee estadisticas")
	_check(level.target == 10, "objetivo de nivel correcto")
	_check(level.is_valid(), "definicion de logro valida")


func _test_cosmetic_catalog() -> void:
	var errors := CosmeticCatalog.validate()
	_check(errors.is_empty(), "catalogo de cosmeticos valido: %s" % ", ".join(errors))
	_check(CosmeticCatalog.get_categories().size() == 7, "hay siete categorias de cosmeticos")
	for category in CosmeticCatalog.get_categories():
		var items := CosmeticCatalog.get_category(category)
		_check(not items.is_empty(), "categoria %s tiene cosmeticos" % category)
		_check(not CosmeticCatalog.get_default_id(category).is_empty(), "categoria %s tiene cosmetico por defecto" % category)
		var defaults := 0
		for item in items:
			if item.is_default():
				defaults += 1
		_check(defaults == 1, "categoria %s tiene un solo cosmetico por defecto" % category)
	_check(CosmeticCatalog.get_by_id("player_mint") != null, "existe cosmetico de jugador")
	_check(CosmeticCatalog.get_by_id("rival_frost") != null, "existe cosmetico de rival")
	_check(CosmeticCatalog.get_by_id("maze_neon") != null, "existe cosmetico de mapa")
	_check(CosmeticCatalog.get_by_id("pellets_candy") != null, "existe estilo de bolas")
	_check(CosmeticCatalog.get_by_id("effects_spark") != null, "existe efecto visual")
	_check(CosmeticCatalog.get_by_id("sfx_deep") != null, "existe estilo de sonido")
	_check(CosmeticCatalog.get_by_id("music_arcade") != null, "existe pista de musica")


func _test_cosmetic_rules() -> void:
	var always := CosmeticCatalog.get_by_id("player_ember")
	_check(always.requirement_met({}, 0, 1, {}), "cosmetico por defecto siempre disponible")
	var level_item := CosmeticCatalog.get_by_id("player_mint")
	_check(not level_item.requirement_met({}, 0, 4, {}), "cosmetico de nivel bloqueado")
	_check(level_item.requirement_met({}, 0, 5, {}), "cosmetico de nivel desbloqueado")
	var runs_item := CosmeticCatalog.get_by_id("rival_frost")
	_check(not runs_item.requirement_met({"runs_finished": 1}, 0, 1, {}), "cosmetico de partidas bloqueado")
	_check(runs_item.requirement_met({"runs_finished": 2}, 0, 1, {}), "cosmetico de partidas desbloqueado")
	var achievement_item := CosmeticCatalog.get_by_id("maze_neon")
	_check(not achievement_item.requirement_met({}, 0, 1, {}), "cosmetico por logro bloqueado")
	_check(achievement_item.requirement_met({}, 0, 1, {"score_1000": true}), "cosmetico por logro desbloqueado")
	var forest := CosmeticCatalog.get_by_id("maze_forest")
	_check(not forest.requirement_met({"levels_completed": 9}, 0, 1, {}), "cosmetico de niveles bloqueado")
	_check(forest.requirement_met({"levels_completed": 10}, 0, 1, {}), "cosmetico de niveles desbloqueado")
	var candy := CosmeticCatalog.get_by_id("pellets_candy")
	_check(not candy.requirement_met({}, 0, 1, {}), "estilo de bolas por logro bloqueado")
	_check(candy.requirement_met({}, 0, 1, {"pellets_100": true}), "estilo de bolas por logro desbloqueado")
	_check(bool(candy.data.get("power_ring", false)), "estilo de bolas define aro de power-up")
	var spark := CosmeticCatalog.get_by_id("effects_spark")
	_check(bool(spark.data.get("burst", false)), "efecto spark activa estallido")
	_check(bool(spark.data.get("particles", false)), "efecto spark activa particulas")
	var deep_sfx := CosmeticCatalog.get_by_id("sfx_deep")
	_check(not deep_sfx.requirement_met({"runs_finished": 2}, 0, 1, {}), "estilo de sonido bloqueado")
	_check(deep_sfx.requirement_met({"runs_finished": 3}, 0, 1, {}), "estilo de sonido desbloqueado")
	_check(String(deep_sfx.data.get("style", "")) == "deep", "estilo de sonido declara su variante")
	var arcade_music := CosmeticCatalog.get_by_id("music_arcade")
	_check(not arcade_music.requirement_met({}, 0, 4, {}), "musica bloqueada por nivel")
	_check(arcade_music.requirement_met({}, 0, 5, {}), "musica desbloqueada por nivel")
	_check(String(arcade_music.data.get("track", "")) == "arcade", "musica declara su pista")
	_check(CosmeticCatalog.get_by_id("music_off").data.get("track", "x") == "", "musica por defecto silenciada")


func _test_contrast() -> void:
	var errors := CosmeticCatalog.validate_contrast()
	_check(errors.is_empty(), "contraste valido: %s" % ", ".join(errors))
	_check(CosmeticCatalog.contrast_ratio(Color.WHITE, Color.BLACK) > 20.0, "contraste blanco/negro alto")
	_check(CosmeticCatalog.contrast_ratio(Color.WHITE, Color.WHITE) < 1.01, "contraste igual es bajo")
	_check(CosmeticCatalog.contrast_ratio(Color("#FDE68A"), Color("#0B1220")) > 4.0, "bolas destacan sobre el suelo")
	_check(CosmeticCatalog.contrast_ratio(Color("#F59E0B"), Color("#0B1220")) > 3.0, "jugador destaca sobre el suelo")


func _test_audio_styles() -> void:
	var audio := root.get_node_or_null("AudioManager")
	_check(audio != null, "autoload AudioManager disponible")
	if audio == null:
		return
	audio.set_sfx_style("deep")
	_check(String(audio.get("_sfx_style")) == "deep", "aplica estilo de sonido grave")
	audio.set_sfx_style("invalido")
	_check(String(audio.get("_sfx_style")) == "classic", "estilo de sonido invalido usa clasico")
	var stream: AudioStreamWAV = audio.call("_build_music_stream", "arcade")
	_check(stream != null and stream.data.size() > 0, "genera pista de musica arcade")
	_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "pista arcade reproduce en bucle")
	var night: AudioStreamWAV = audio.call("_build_music_stream", "night")
	_check(night != null and night.data.size() > 0, "genera pista de musica nocturna")
	var invalid: AudioStreamWAV = audio.call("_build_music_stream", "invalida")
	_check(invalid == null, "pista de musica invalida no se genera")


func _test_ads_interstitial() -> void:
	var ads := root.get_node_or_null("AdsManager")
	_check(ads != null, "autoload AdsManager disponible")
	if ads == null:
		return
	_check(ads.is_interstitial_ready(), "mock interstitial listo")
	_interstitial_seen = false
	ads.connect("interstitial_dismissed", Callable(self, "_on_interstitial_seen"))
	ads.show_interstitial()
	_check(_interstitial_seen, "mock interstitial emite dismissed")
	ads.disconnect("interstitial_dismissed", Callable(self, "_on_interstitial_seen"))


func _on_interstitial_seen() -> void:
	_interstitial_seen = true


func _test_manager_api() -> void:
	_check(_achievement_manager != null, "autoload AchievementManager disponible")
	_check(_unlock_manager != null, "autoload UnlockManager disponible")
	if _achievement_manager == null or _unlock_manager == null:
		return
	_check(_achievement_manager.get_target("level_30") == 30, "manager expone objetivo de logro")
	_check(_achievement_manager.get_target("no_existe") == 0, "manager maneja logro inexistente")
	_check(_unlock_manager.is_unlocked("player_ember"), "manager considera desbloqueado el cosmetico por defecto")
	_check(not _unlock_manager.is_unlocked("no_existe"), "manager rechaza cosmetico inexistente")
	_check(_unlock_manager.get_palette("player").has("primary"), "manager expone paleta de jugador")
	_check(_unlock_manager.get_palette("maze").has("wall"), "manager expone paleta de mapa")


func _detect_quit_after() -> bool:
	for argument in OS.get_cmdline_args():
		if argument == "--quit-after" or argument.begins_with("--quit-after="):
			return true
	return false


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: %s" % label)
