class_name CryBank
extends RefCounted
## The team's recorded cry, res://audio/baby_cry.wav: the ONE audio file in
## the game (a deliberate exception to "all sound is generated"). Variants,
## built after the first click, a chunk per frame (no stall):
##   raw   as recorded
##   low   low-passed in the samples (AudioManager plays it at pitch 0.6). The
##         filter is baked rather than an AudioEffectLowPassFilter on a bus,
##         because the web build's sample playback skips bus effects.
##   thin  cut off two-thirds through (the reveal: rubbed out mid-cry)
## If the file is missing it falls back to SfxSynth2.wail() (`missing`).

const PATH: String = "res://audio/baby_cry.wav"
const CHUNK: int = 12000
const THIN_PART: float = 0.62
const LOWPASS_HZ: float = 900.0
const LOW_GAIN: float = 1.5

var streams: Dictionary = {}
var missing: bool = false

var _player: AudioStreamPlayer
var _src: AudioStreamWAV
var _low: PackedByteArray
var _pos: int = -1
var _a: float = 0.0
var _lp: float = 0.0
var _lp2: float = 0.0


func start(player: AudioStreamPlayer) -> void:
	_player = player
	if ResourceLoader.exists(PATH):
		_src = load(PATH) as AudioStreamWAV
	if _src == null:
		missing = true
		push_warning("CryBank: %s is missing; using the synthesized wail." % PATH)
		_src = SfxSynth2.wail()
	streams[&"raw"] = _src
	if _src.format != AudioStreamWAV.FORMAT_16_BITS or _src.stereo:
		# Not plain 16-bit mono PCM (re-imported compressed?): no processing.
		streams[&"low"] = _src
		streams[&"thin"] = _src
		return
	streams[&"thin"] = _thin()
	_low = _src.data.duplicate()
	_a = 1.0 - exp(-TAU * LOWPASS_HZ / _src.mix_rate)
	_pos = 0


## Plays `variant` (fading in over `fade_in` s). With `once_id`, only if
## that id isn't in GameState.seen yet (then it is added). False if not played.
func play(variant: StringName, volume_db: float, fade_in: float, once_id: StringName) -> bool:
	if _player == null or not streams.has(variant) or (once_id != &"" and GameState.seen.has(once_id)):
		return false
	if once_id != &"":
		GameState.seen.append(once_id)
	_player.stream = streams[variant]
	_player.pitch_scale = 0.6 if variant == &"low" else 1.0
	_player.volume_db = -40.0 if fade_in > 0.0 else volume_db
	_player.play()
	if fade_in > 0.0:
		_player.create_tween().tween_property(_player, "volume_db", volume_db, fade_in)
	return true


func stop() -> void:
	if _player != null:
		_player.stop()


## Low-passes the next chunk of the "low" copy; finishes it on the last one.
func step() -> void:
	if _pos < 0:
		return
	var count: int = _low.size() / 2
	var last: int = mini(_pos + CHUNK, count)
	for i in range(_pos, last):
		var x: float = _low.decode_s16(i * 2) / 32768.0
		_lp += (x - _lp) * _a
		_lp2 += (_lp - _lp2) * _a
		_low.encode_s16(i * 2, int(clampf(_lp2 * LOW_GAIN, -1.0, 1.0) * 32767.0))
	_pos = last
	if _pos >= count:
		_pos = -1
		streams[&"low"] = _copy(_low)


func _thin() -> AudioStreamWAV:
	var count: int = int(_src.data.size() / 2 * THIN_PART)
	var bytes: PackedByteArray = _src.data.slice(0, count * 2)
	# A few milliseconds of fade so the cut doesn't click.
	var fade: int = mini(int(_src.mix_rate * 0.008), count)
	for j in fade:
		var i: int = count - fade + j
		bytes.encode_s16(i * 2, int(bytes.decode_s16(i * 2) * (1.0 - float(j) / fade)))
	return _copy(bytes)


func _copy(bytes: PackedByteArray) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = _src.mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav
