class_name MusicSynth3
extends RefCounted
## The menu's melancholy layer (Stage 6), same conventions as MusicSynth
## (rendered a chunk per frame by MusicRenderer, a seamless loop):
##   menu_sad  a lone, slightly detuned music-box voice in A minor, three
##             short phrases (3-4 notes, 1.6-2.2 s apart) with ~3-4 s of
##             silence between them, long tails and a soft echo; a sine pad
##             swells under each phrase's last note and dies away. Every note
##             is also rendered one loop earlier, so tails that run past the
##             loop's end come back in at its start (no seam, no cut tails).
## Played quietly over the menu bed only (MusicManager.SAD_DB).

const RATE: int = MusicSynth.RATE
const LENGTH: float = 40.0
## Each note's decay (MusicSynth._pluck): audible ~4 s, gone by ~5.5 s.
const DECAY: float = 3.5
## [start s, midi]: A minor, the harmonic minor's G# once, a falling end.
## Silence between phrases: ~2.7 s, ~2.7 s and ~4 s (with the loop).
## (Runtime-built: nested constant arrays read back empty in web exports.)
static func notes() -> Array:
	return [
	[1.0, 76], [2.8, 72], [4.6, 69],
	[12.5, 74], [14.2, 72], [15.9, 71], [18.1, 68],
	[26.0, 76], [27.6, 77], [29.4, 76], [31.6, 69],
	]
## Pads under the phrase ends: [start s, midi, length s].
static func pads() -> Array:
	return [[4.4, 57, 4.5], [17.8, 52, 4.5], [31.2, 57, 5.0]]


static func render(_track: StringName, buf: PackedFloat32Array, from: int, to: int) -> void:
	var notes: Array = notes()
	for wrap in [0.0, -LENGTH]:
		for n in notes.size():
			var at: float = float(notes[n][0]) + wrap
			var cents: float = sin(n * 3.7) * 0.22
			var f: float = MusicSynth.hz(float(notes[n][1]) + cents)
			# The voice, a ghost of it detuned a few cents, and two echoes.
			MusicSynth._pluck(buf, from, to, at, f, 0.11, DECAY, true)
			MusicSynth._pluck(buf, from, to, at + 0.012, f * 1.004, 0.035, DECAY * 0.8, true)
			for e in 2:
				MusicSynth._pluck(buf, from, to, at + 0.42 * (e + 1), f, 0.11 * pow(0.32, e + 1), DECAY * 0.8, true)
		for pad in pads():
			_pad(buf, from, to, float(pad[0]) + wrap, MusicSynth.hz(float(pad[1])), float(pad[2]), 0.035)


## A soft sine pad note (with its fifth, quietly): slow swell, slow fade.
static func _pad(buf: PackedFloat32Array, from: int, to: int, start: float, f: float, length: float, amp: float) -> void:
	var s0: int = int(start * RATE)
	var a: int = maxi(from, s0)
	var b: int = mini(to, s0 + int(length * RATE))
	var w: float = TAU * f / RATE
	for i in range(a, b):
		var t: float = float(i - s0) / RATE
		var env: float = sin(PI * t / length)
		env *= env
		buf[i] += (sin(w * (i - s0)) + sin(w * 1.5 * (i - s0)) * 0.25) * env * amp
