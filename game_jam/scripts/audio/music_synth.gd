class_name MusicSynth
extends RefCounted
## The music, synthesized in code (22050 Hz mono 16-bit). Every track is a
## sum of passes over a sample range so MusicManager can render it a chunk
## at a time across frames. Loops are made seamless by rendering FADE extra
## seconds and folding that tail back over the start.
##   menu     music box (detuned) over a beating drone; the game's motif
##   ch1      quiet drone with a minor-second rub and sparse low plucks
##   ch2      low pulse over a Shepard tone that rises for ever
##   ch3      distorted, stuttering drone with a wavering whine
##   reveal   a swelling dread cluster, then silence (no loop)
##   warm     the motif in A major over a soft pad (return phase, repair)
##   ending   the motif slower, one note left unresolved
##   layer_intensity / layer_hunt   dynamic layers (MusicManager fades them)

const RATE: int = 22050
const FADE: float = 0.5
const TRACKS: Dictionary = {
	&"menu": 16.0, &"ch1": 12.0, &"ch2": 12.0, &"ch3": 12.0, &"reveal": 24.0,
	&"warm": 16.0, &"ending": 16.0, &"layer_intensity": 8.0, &"layer_hunt": 8.0,
}
const MOTIF: PackedInt32Array = [76, 72, 69, 71, 72, 69, 64, 65, 76, 72, 69, 71, 69, 68, 64, -1]
const MOTIF_MAJOR: PackedInt32Array = [76, 73, 69, 71, 73, 69, 64, 66, 76, 73, 69, 71, 69, 68, 64, -1]


static func loops(track: StringName) -> bool:
	return track != &"reveal"


## Samples to render (loop length plus the fold-back tail).
static func total_samples(track: StringName) -> int:
	return int((TRACKS[track] + (FADE if loops(track) else 0.0)) * RATE)


static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Adds the track's samples [from, to) into buf.
static func render(track: StringName, buf: PackedFloat32Array, from: int, to: int) -> void:
	match track:
		&"menu":
			_drone(buf, from, to, 55.0, 55.35, 0.10)
			_melody(buf, from, to, MOTIF, 1.0, 0.16, 2.4, 0.18)
		&"ch1":
			_drone(buf, from, to, 73.42, 77.78, 0.08 * 1.0)
			for n in [[0.0, 50], [4.5, 44], [8.0, 48]]:
				_pluck(buf, from, to, n[0], hz(n[1]), 0.22, 3.0)
		&"ch2":
			_shepard(buf, from, to, 32.7, 12.0, 0.11)
			for i in 16:
				_kick(buf, from, to, i * 0.75, 0.30)
		&"ch3":
			_stutter(buf, from, to)
		&"reveal":
			_swell(buf, from, to)
		&"warm":
			_pad(buf, from, to, [57, 61, 64], 0.06)
			_melody(buf, from, to, MOTIF_MAJOR, 1.0, 0.14, 2.6, 0.0)
		&"ending":
			_pad(buf, from, to, [57, 64], 0.05)
			var slow: PackedInt32Array = MOTIF_MAJOR.duplicate()
			slow[14] = 67
			_melody(buf, from, to, slow, 1.0, 0.12, 3.0, 0.08)
		&"layer_intensity":
			_tremolo(buf, from, to)
		&"layer_hunt":
			for i in 20:
				_kick(buf, from, to, i * 0.4, 0.24, 90.0)


## Makes a rendered loop seamless: the tail fades over the start.
static func fold_loop(track: StringName, buf: PackedFloat32Array) -> PackedFloat32Array:
	if not loops(track):
		return buf
	var length: int = int(TRACKS[track] * RATE)
	var fade: int = buf.size() - length
	for i in fade:
		var k: float = float(i) / fade
		buf[i] = buf[i] * k + buf[length + i] * (1.0 - k)
	buf.resize(length)
	return buf


static func _drone(buf: PackedFloat32Array, from: int, to: int, f1: float, f2: float, amp: float) -> void:
	var w1: float = TAU * f1 / RATE
	var w2: float = TAU * f2 / RATE
	var w3: float = TAU * f1 * 1.5 / RATE
	for i in range(from, to):
		buf[i] += (sin(w1 * i) + sin(w2 * i) * 0.8 + sin(w3 * i) * 0.25) * amp * (0.75 + 0.25 * sin(i * 0.00004))


## One note per beat (`beat` seconds): a music box tine (fundamental plus a
## bright partial, fast decay), each note a little out of tune.
static func _melody(buf: PackedFloat32Array, from: int, to: int, notes: PackedInt32Array, beat: float, amp: float, decay: float,
		detune: float) -> void:
	for n in notes.size():
		if notes[n] < 0:
			continue
		var cents: float = sin(n * 12.9898) * detune
		_pluck(buf, from, to, n * beat, hz(notes[n] + cents), amp, decay, true)


static func _pluck(buf: PackedFloat32Array, from: int, to: int, start: float, f: float, amp: float, decay: float,
		tine: bool = false) -> void:
	var s0: int = int(start * RATE)
	var s1: int = mini(s0 + int(decay * 1.6 * RATE), buf.size())
	var a: int = maxi(from, s0)
	var b: int = mini(to, s1)
	var w: float = TAU * f / RATE
	var k: float = 1.0 / (decay * RATE * 0.35)
	for i in range(a, b):
		var t: int = i - s0
		var env: float = exp(-t * k) * minf(t / 60.0, 1.0)
		var v: float = sin(w * t)
		if tine:
			v += sin(w * 2.0 * t) * 0.35 * exp(-t * k * 2.0) + sin(w * 4.07 * t) * 0.12 * exp(-t * k * 4.0)
		buf[i] += v * env * amp


static func _kick(buf: PackedFloat32Array, from: int, to: int, start: float, amp: float, top: float = 58.0) -> void:
	var s0: int = int(start * RATE)
	var a: int = maxi(from, s0)
	var b: int = mini(to, mini(s0 + int(0.35 * RATE), buf.size()))
	var phase: float = 0.0
	for i in range(s0, b):
		var t: float = float(i - s0) / RATE
		phase += TAU * lerpf(top, 34.0, minf(t / 0.2, 1.0)) / RATE
		if i >= a:
			buf[i] += sin(phase) * exp(-t * 11.0) * amp


## A tone that seems to rise for ever (octave-spaced partials under a fixed
## bell curve), repeating exactly every `period` seconds.
static func _shepard(buf: PackedFloat32Array, from: int, to: int, base: float, period: float, amp: float) -> void:
	var scale: float = base * period / log(2.0) * TAU
	for i in range(from, to):
		var x: float = float(i) / RATE / period
		var v: float = 0.0
		for k in 7:
			var oct: float = k + x
			var g: float = exp(-pow(oct - 3.0, 2.0) * 0.5)
			v += sin(scale * pow(2.0, k + x)) * g
		buf[i] += v * amp


static func _stutter(buf: PackedFloat32Array, from: int, to: int) -> void:
	var w: float = TAU * 55.0 / RATE
	var whine: float = TAU * 1046.5 / RATE
	var step: int = int(RATE / 8.0)
	for i in range(from, to):
		var slot: int = int(float(i) / step)
		var gate: float = 1.0 if fmod(sin(slot * 78.233) * 43758.5, 1.0) > -0.35 else 0.0
		var sq: float = tanh(sin(w * i) * 4.0 + sin(w * 1.02 * i) * 2.0)
		var wob: float = sin(whine * i + sin(i * 0.0007) * 6.0) * 0.04
		buf[i] += sq * 0.09 * gate + wob


static func _swell(buf: PackedFloat32Array, from: int, to: int) -> void:
	var notes: Array[float] = [45.0, 46.0, 52.0, 57.0, 58.0]
	var cut: int = int(22.0 * RATE)
	for i in range(from, mini(to, cut)):
		var t: float = float(i) / RATE
		var rise: float = pow(t / 22.0, 2.2)
		var v: float = 0.0
		for n in notes:
			var f: float = hz(n + rise)
			v += (fmod(t * f, 1.0) * 2.0 - 1.0)
		buf[i] += v * 0.05 * rise


static func _pad(buf: PackedFloat32Array, from: int, to: int, notes: Array, amp: float) -> void:
	var ws: Array[float] = []
	for n in notes:
		ws.append(TAU * hz(n) / RATE)
	for i in range(from, to):
		var v: float = 0.0
		for w in ws:
			v += sin(w * i) + sin(w * 1.003 * i) * 0.5
		buf[i] += v * amp * (0.8 + 0.2 * sin(i * 0.00006))


static func _tremolo(buf: PackedFloat32Array, from: int, to: int) -> void:
	var w1: float = TAU * 587.3 / RATE
	var w2: float = TAU * 622.3 / RATE
	var trem: float = TAU * 7.0 / RATE
	for i in range(from, to):
		buf[i] += (sin(w1 * i) + sin(w2 * i)) * (0.5 + 0.5 * sin(trem * i)) * 0.05
