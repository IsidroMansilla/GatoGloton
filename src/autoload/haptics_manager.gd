extends Node


func pulse(kind: String) -> void:
	if not _enabled():
		return
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return
	var duration := 12
	var amplitude := 0.35
	match kind:
		"power":
			duration = 30
			amplitude = 0.6
		"eat":
			duration = 20
			amplitude = 0.5
		"hit":
			duration = 70
			amplitude = 0.9
		"complete":
			duration = 45
			amplitude = 0.7
		"record":
			duration = 60
			amplitude = 0.8
	Input.vibrate_handheld(duration, amplitude)


func _enabled() -> bool:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return true
	return bool(manager.call("get_setting", "vibration", true))
