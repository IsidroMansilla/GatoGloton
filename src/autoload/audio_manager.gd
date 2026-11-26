extends Node

const MUSIC_MIX_RATE: int = 22050
const MUSIC_DURATION: float = 4.0

var muted: bool = false
var music_volume_db: float = -6.0
var sfx_volume_db: float = -3.0
var _sfx_style: String = "classic"
var _music_track: String = ""
var _sfx_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback
var _music_player: AudioStreamPlayer
var _music_cache: Dictionary = {}


func _ready() -> void:
	_apply_settings()
	if DisplayServer.get_name() == "headless":
		return
	_sfx_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.5
	_sfx_player.stream = generator
	_sfx_player.volume_db = sfx_volume_db
	add_child(_sfx_player)
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = music_volume_db
	add_child(_music_player)
	var manager := get_node_or_null("/root/UnlockManager")
	if manager != null:
		manager.connect("cosmetics_changed", _on_cosmetics_changed)
		_apply_selected_sfx()
		_apply_selected_music()


func _exit_tree() -> void:
	if _sfx_player != null:
		_sfx_player.stop()
		_sfx_player.stream = null
		_sfx_player = null
		_sfx_playback = null
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
		_music_player = null
	_music_cache.clear()


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

	if _sfx_style == "chip":
		frequency *= 1.12
	elif _sfx_style == "deep":
		frequency *= 0.72
	var sample_count := int(22050.0 * duration)
	var samples := PackedVector2Array()
	samples.resize(sample_count)
	for index in sample_count:
		var time := float(index) / 22050.0
		var envelope := minf(1.0, time * 80.0) * minf(1.0, (duration - time) * 40.0)
		var wave := sin(TAU * frequency * time)
		if _sfx_style == "chip":
			wave = 1.0 if wave >= 0.0 else -1.0
		elif _sfx_style == "deep":
			wave = wave * 0.75 + sin(TAU * frequency * 0.5 * time) * 0.25
		var sample := wave * volume * envelope
		samples[index] = Vector2(sample, sample)
	_sfx_playback.push_buffer(samples)


func set_muted(value: bool, persist: bool = true) -> void:
	muted = value
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, muted)
	if persist:
		SaveManager.set_setting("muted", muted)


func toggle_muted() -> void:
	set_muted(not muted)


func set_music_volume_db(value: float, persist: bool = true) -> void:
	music_volume_db = clampf(value, -40.0, 0.0)
	if _music_player != null:
		_music_player.volume_db = music_volume_db
	if persist:
		SaveManager.set_setting("music_volume_db", music_volume_db)


func set_sfx_volume_db(value: float, persist: bool = true) -> void:
	sfx_volume_db = clampf(value, -40.0, 0.0)
	if _sfx_player != null:
		_sfx_player.volume_db = sfx_volume_db
	if persist:
		SaveManager.set_setting("sfx_volume_db", sfx_volume_db)


func _apply_settings() -> void:
	var data := SaveManager.get_settings()
	muted = bool(data.get("muted", muted))
	music_volume_db = clampf(float(data.get("music_volume_db", music_volume_db)), -40.0, 0.0)
	sfx_volume_db = clampf(float(data.get("sfx_volume_db", sfx_volume_db)), -40.0, 0.0)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, muted)


func set_sfx_style(style: String) -> void:
	_sfx_style = style if ["classic", "chip", "deep"].has(style) else "classic"


func set_music_track(track: String) -> void:
	if track == _music_track and (_music_player == null or _music_player.playing or track.is_empty()):
		return
	_music_track = track
	if _music_player == null:
		return
	if track.is_empty():
		_music_player.stop()
		_music_player.stream = null
		return
	var stream: AudioStreamWAV = _music_cache.get(track, null)
	if stream == null:
		stream = _build_music_stream(track)
		if stream == null:
			_music_track = ""
			return
		_music_cache[track] = stream
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()
	print("[Audio] musica %s" % track)


func _apply_selected_sfx() -> void:
	var definition := CosmeticCatalog.get_by_id(SaveManager.get_cosmetic("sfx"))
	if definition != null:
		set_sfx_style(String(definition.data.get("style", "classic")))


func _apply_selected_music() -> void:
	var definition := CosmeticCatalog.get_by_id(SaveManager.get_cosmetic("music"))
	if definition != null:
		set_music_track(String(definition.data.get("track", "")))


func _on_cosmetics_changed(category: String, id: String) -> void:
	var definition := CosmeticCatalog.get_by_id(id)
	if definition == null:
		return
	if category == "sfx":
		set_sfx_style(String(definition.data.get("style", "classic")))
	elif category == "music":
		set_music_track(String(definition.data.get("track", "")))


func _build_music_stream(track: String) -> AudioStreamWAV:
	var notes: Array[float] = []
	var square := true
	var amplitude := 0.11
	match track:
		"arcade":
			notes = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 349.23]
		"night":
			notes = [220.0, 261.63, 329.63, 293.66, 220.0, 196.0, 246.94, 293.66]
			square = false
			amplitude = 0.08
		_:
			return null
	var frame_count := int(MUSIC_MIX_RATE * MUSIC_DURATION)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var note_duration := MUSIC_DURATION / float(notes.size())
	for index in frame_count:
		var time := float(index) / float(MUSIC_MIX_RATE)
		var note_index := mini(int(time / note_duration), notes.size() - 1)
		var frequency: float = notes[note_index]
		var phase := fmod(time, note_duration) / note_duration
		var envelope := minf(1.0, phase * 12.0) * minf(1.0, (1.0 - phase) * 8.0)
		var wave := sin(TAU * frequency * time)
		if square:
			wave = 1.0 if wave >= 0.0 else -1.0
		else:
			wave = wave * 0.7 + sin(TAU * frequency * 2.0 * time) * 0.3
		data.encode_s16(index * 2, int(clampf(wave * envelope * amplitude, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream
