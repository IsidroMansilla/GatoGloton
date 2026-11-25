extends Node

signal score_changed(value: int)
signal lives_changed(value: int)
signal level_changed(value: int)

var score: int = 0
var lives: int = 3
var level: int = 1
var is_custom_game: bool = false


func reset_run() -> void:
	score = 0
	lives = 3
	level = 1
	is_custom_game = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	level_changed.emit(level)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
	if not is_custom_game:
		SaveManager.record_score(score)


func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	return lives <= 0


func next_level() -> void:
	level += 1
	level_changed.emit(level)
