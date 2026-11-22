extends Node

var muted: bool = false
var music_volume_db: float = -6.0
var sfx_volume_db: float = -3.0


func set_muted(value: bool) -> void:
	muted = value
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, muted)


func toggle_muted() -> void:
	set_muted(not muted)
