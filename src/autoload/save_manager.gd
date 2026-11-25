extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2

signal high_score_changed(value: int)
signal highest_level_changed(value: int)

var high_score: int = 0
var highest_level: int = 1


func _ready() -> void:
	load_game()


func record_score(value: int) -> void:
	if value <= high_score:
		return
	high_score = value
	high_score_changed.emit(high_score)
	save_game()


func record_level(value: int) -> void:
	if value <= highest_level:
		return
	highest_level = value
	highest_level_changed.emit(highest_level)
	save_game()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir %s" % SAVE_PATH)
		return

	var raw := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save corrupto en %s; se ignora" % SAVE_PATH)
		return

	var data: Dictionary = parsed as Dictionary
	var version: int = int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("Save de version futura (%d); se ignora" % version)
		return

	high_score = int(data.get("high_score", 0))
	highest_level = maxi(1, int(data.get("highest_level", 1)))
	high_score_changed.emit(high_score)
	highest_level_changed.emit(highest_level)


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"high_score": high_score,
		"highest_level": highest_level,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo escribir %s" % SAVE_PATH)
		return

	file.store_string(JSON.stringify(data, "\t"))
