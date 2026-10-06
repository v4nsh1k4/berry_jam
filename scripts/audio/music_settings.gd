class_name MusicSettings
extends Node
## The Music bus's volume and mute (user://settings.cfg [audio]) and the mute
## on focus loss. Split out of MusicManager in Stage 7 (behaviour unchanged);
## MusicManager keeps its public music_volume / music_muted / set_music_*.

const SETTINGS_PATH: String = "user://settings.cfg"

## Default 0.85 (-1.4 dB; 0.6 before Stage 6b). Old saves are moved up once.
var volume: float = 0.85
var muted: bool = false

var _bus: StringName


func setup(bus: StringName) -> void:
	_bus = bus
	var loaded: Array = MusicSynth2.load_setting(SETTINGS_PATH, volume, muted)
	volume = loaded[0]
	muted = loaded[1]
	apply()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	apply()
	MusicSynth2.save_setting(SETTINGS_PATH, volume, muted)


func set_muted(value: bool) -> void:
	muted = value
	apply()
	MusicSynth2.save_setting(SETTINGS_PATH, volume, muted)


func apply(focus_lost: bool = false) -> void:
	var index: int = AudioServer.get_bus_index(_bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, muted or focus_lost)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		apply(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		apply(false)
