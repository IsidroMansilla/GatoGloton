extends Node

var muted: bool = false
var music_volume_db: float = -6.0
var sfx_volume_db: float = -3.0
var _sfx_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback


func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.5
	_sfx_player.stream = generator
	_sfx_player.volume_db = sfx_volume_db
	add_child(_sfx_player)
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _exit_tree() -> void:
	if _sfx_player != null:
		_sfx_player.stop()
		_sfx_player.stream = null
		_sfx_player.free()
		_sfx_player = null
		_sfx_playback = null


func play_sfx(effect: String) -> void:
	if muted or _sfx_playback == null:
		return
	var frequency := 440.0
	var duration := 0.08
	var volume := 0.18
	match effect:
		"start":
			frequency = 520.0
			duration = 0.16
			volume = 0.2
		"pellet":
			frequency = 760.0
			duration = 0.045
		"power":
			frequency = 260.0
			duration = 0.22
			volume = 0.22
		"hit":
			frequency = 120.0
			duration = 0.2
			volume = 0.25
		"eat":
			frequency = 980.0
			duration = 0.14
			volume = 0.2
		"pause":
			frequency = 300.0
		"resume":
			frequency = 600.0
		"complete":
			frequency = 660.0
			duration = 0.3
			volume = 0.22

	var sample_count := int(22050.0 * duration)
	var samples := PackedVector2Array()
	samples.resize(sample_count)
	for index in sample_count:
		var time := float(index) / 22050.0
		var envelope := minf(1.0, time * 80.0) * minf(1.0, (duration - time) * 40.0)
		var sample := sin(TAU * frequency * time) * volume * envelope
		samples[index] = Vector2(sample, sample)
	_sfx_playback.push_buffer(samples)


func set_muted(value: bool) -> void:
	muted = value
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, muted)


func toggle_muted() -> void:
	set_muted(not muted)
