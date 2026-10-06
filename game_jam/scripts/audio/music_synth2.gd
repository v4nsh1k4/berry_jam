class_name MusicSynth2
extends RefCounted
## More synthesized music (Stage 4D), same conventions as MusicSynth:
##   return       the return phase: sad and uneasy, never cheerful. A slow,
##                detuned music box in a minor key over a low drone with a
##                minor-second rub, long tails, a distant nib scratch now and then
##   erase        the last room before the repair: heartbeat pulse, eraser
##                scraping in strokes, a slowly rising dissonant cluster
##   layer_pulse  the first build-up layer: a low throb (the Crawler is up)
##   bed          (Stage 5) the ominous bed under every Chapter 1-3 track: a
##                low drone whose detuned partials beat slowly, and now and
##                then a faint, distant glassy tone with an echo

const RATE: int = MusicSynth.RATE
## A minor, slow, with gaps (-1 = rest): two notes per bar at most.
const RETURN_MELODY: PackedInt32Array = [69, -1, 72, 71, -1, 64, -1, -1, 69, -1, 68, 64, -1, 65, -1, -1]


static func render(track: StringName, buf: PackedFloat32Array, from: int, to: int) -> void:
	match track:
		&"return":
			_drone(buf, from, to, 55.0, 58.27, 0.07)
			for n in RETURN_MELODY.size():
				if RETURN_MELODY[n] >= 0:
					var cents: float = sin(n * 7.31) * 0.28
					MusicSynth._pluck(buf, from, to, n * 1.25, MusicSynth.hz(RETURN_MELODY[n] + cents), 0.10, 4.5, true)
			for at in [4.6, 13.1]:
				_scratch(buf, from, to, at, 0.6, 0.05)
		&"erase":
			for i in 14:
				# Heartbeat: lub-dub at ~70 bpm.
				MusicSynth._kick(buf, from, to, i * 0.857, 0.34, 64.0)
				MusicSynth._kick(buf, from, to, i * 0.857 + 0.18, 0.2, 52.0)
			for i in 6:
				_scratch(buf, from, to, 0.4 + i * 2.0, 1.1, 0.09)
			_cluster(buf, from, to, 0.05)
		&"layer_pulse":
			for i in 16:
				MusicSynth._kick(buf, from, to, i * 0.5, 0.22 if i % 2 == 0 else 0.12, 46.0)
		&"bed":
			_bed(buf, from, to)
			for n in [[2.5, 88], [10.2, 87], [17.6, 91]]:
				for echo in 3:
					_glass(buf, from, to, n[0] + echo * 0.37, MusicSynth.hz(n[1]), 0.045 * pow(0.45, echo))


static func _drone(buf: PackedFloat32Array, from: int, to: int, f1: float, f2: float, amp: float) -> void:
	var w1: float = TAU * f1 / RATE
	var w2: float = TAU * f2 / RATE
	for i in range(from, to):
		var swell: float = 0.7 + 0.3 * sin(i * 0.000035)
		buf[i] += (sin(w1 * i) + sin(w2 * i) * 0.45 + sin(w1 * 0.5 * i) * 0.6) * amp * swell


## Pairs of close partials (whole cycles per 24 s loop) beat every 4-6 s; a
## tritone breathes in and out over the loop.
static func _bed(buf: PackedFloat32Array, from: int, to: int) -> void:
	var parts: Array = [[55.0, 0.5], [55.1667, 0.4], [110.0, 0.35], [110.25, 0.3], [164.875, 0.12], [233.0833, 0.06]]
	for i in range(from, to):
		var t: float = float(i) / RATE
		var v: float = 0.0
		for p in parts:
			v += sin(TAU * p[0] * t) * p[1] * (1.0 if p[0] < 200.0 else 0.5 + 0.5 * sin(TAU * t / 24.0))
		buf[i] += v * 0.12 * (0.85 + 0.15 * sin(TAU * t / 12.0))


## A far-off glass tone: slow swell, long tail, a slight shimmer.
static func _glass(buf: PackedFloat32Array, from: int, to: int, start: float, f: float, amp: float) -> void:
	var s0: int = int(start * RATE)
	var a: int = maxi(from, s0)
	var b: int = mini(to, mini(s0 + int(3.6 * RATE), buf.size()))
	for i in range(a, b):
		var t: float = float(i - s0) / RATE
		var env: float = minf(t / 0.7, 1.0) * exp(-maxf(t - 0.7, 0.0) * 1.3)
		buf[i] += (sin(TAU * f * t) + sin(TAU * f * 1.004 * t) * 0.6) * env * amp


## A pen nib (or an eraser) dragged across paper: bright noise in strokes.
static func _scratch(buf: PackedFloat32Array, from: int, to: int, start: float, length: float, amp: float) -> void:
	var s0: int = int(start * RATE)
	var a: int = maxi(from, s0)
	var b: int = mini(to, mini(s0 + int(length * RATE), buf.size()))
	for i in range(a, b):
		var t: float = float(i - s0) / RATE
		var n: float = fmod(sin(i * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
		var strokes: float = pow(maxf(sin(TAU * 7.0 * t), 0.0), 0.6)
		buf[i] += n * strokes * sin(PI * t / length) * amp


## A cluster of close notes that rises a semitone over the loop.
static func _cluster(buf: PackedFloat32Array, from: int, to: int, amp: float) -> void:
	var notes: Array[float] = [45.0, 46.0, 51.0, 52.0]
	var length: float = MusicSynth.TRACKS[&"erase"]
	for i in range(from, to):
		var t: float = float(i) / RATE
		var rise: float = fmod(t, length) / length
		var v: float = 0.0
		for n in notes:
			v += sin(TAU * MusicSynth.hz(n + rise) * t)
		buf[i] += v * amp * (0.4 + 0.6 * rise)


## A short music-box stinger, rendered at once: [[start s, midi note], ...].
static func short_stinger(notes: Array, amp: float) -> AudioStreamWAV:
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(1.6 * RATE))
	for n in notes:
		MusicSynth._pluck(buf, 0, buf.size(), n[0], MusicSynth.hz(n[1]), amp, 0.8, true)
	return SfxSynth._to_wav(buf)


## [music volume, muted] from the shared settings file.
## Stinger builders for MusicManager (one per frame).
static func stinger_jobs() -> Dictionary:
	return {
		&"soft": short_stinger.bind([[0.0, 45], [0.0, 88]], 0.16),
		&"discover": short_stinger.bind([[0.0, 81], [0.18, 76]], 0.10),
		&"relief": short_stinger.bind([[0.0, 69], [0.06, 73], [0.12, 76]], 0.12),
		&"danger": SfxSynth2.sting,
	}


## Stage 6b moved the music up: a settings.cfg saved before then (no
## `music_level` 2) gets the new default volume once, mute kept, and is
## re-saved so later changes by the player stick.
static func load_setting(path: String, volume: float, muted: bool) -> Array:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return [volume, muted]
	var saved_muted: bool = bool(config.get_value("audio", "music_muted", muted))
	if int(config.get_value("audio", "music_level", 1)) < 2:
		config.set_value("audio", "music_level", 2)
		config.set_value("audio", "music_volume", volume)
		config.save(path)
		return [volume, saved_muted]
	return [float(config.get_value("audio", "music_volume", volume)), saved_muted]


## Music volume / mute into the shared settings file (loads it first so the
## other systems' keys survive).
static func save_setting(path: String, volume: float, muted: bool) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(path)
	config.set_value("audio", "music_volume", volume)
	config.set_value("audio", "music_muted", muted)
	config.set_value("audio", "music_level", 2)
	config.save(path)
