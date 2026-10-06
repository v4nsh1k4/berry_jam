class_name MusicSynth4
extends RefCounted
## Soft, sparse piano (Stage 7), same conventions as MusicSynth (22050 Hz,
## rendered a chunk per frame by MusicRenderer, seamless loops):
##   piano_bed  under Chapters 1-3 rooms (in bg_track.wav's place, see
##              MusicFiles.USE_BG_TRACK): A minor / Aeolian, a low held note
##              under each phrase, 3-5 slow notes above it, long rests.
##   menu       the main menu: D Dorian, calm and inviting, a flat sixth (B-flat)
##              against an E for a little unease, the last note unresolved.
##   piano_end  the End Card: C major through A minor and F, bittersweet, the
##              last phrase resolving on C.
## The voice: 3-6 slightly inharmonic partials (stiff strings), a soft hammer
## (raised-cosine attack), a two-stage decay (a quick drop, then a long ring;
## upper partials die faster), a slow string beat on the fundamental,
## velocity shaping loudness and brightness, and a damper when a note is let
## go. A small room (two damped feedback echoes) is applied as each chunk is
## rendered. Every note whose ring passes the loop's end is also rendered one
## loop earlier, so tails wrap round the seam. No percussion, no swells.
## Envelopes are stepped by multiplying (no exp() per sample): it is cheap
## enough to render in the background (menu first) without a long frame.

const RATE: int = MusicSynth.RATE
## Stiff-string inharmonicity: partial k sits at k * f * sqrt(1 + B k^2).
const B: float = 0.00035
const ATTACK: float = 0.006
const DAMPER: float = 0.28
const ROOM: Array[float] = [0.113, 0.27, 0.173, 0.17]
## Loop lengths (seconds).
const LENGTHS: Dictionary = {&"piano_bed": 60.0, &"menu": 28.0, &"piano_end": 40.0}
const GAIN: Dictionary = {&"piano_bed": 0.62, &"menu": 0.62, &"piano_end": 0.6}


## [start s, midi, velocity 0..1, hold s (0 = let it ring)] per piece.
## (Runtime-built: nested constant arrays read back empty in web exports.)
static func score(track: StringName) -> Array:
	match track:
		&"piano_bed":
			return [
				[0.5, 45, 0.42, 7.0], [1.3, 64, 0.32, 0.0], [3.8, 72, 0.28, 0.0], [6.1, 71, 0.26, 0.0],
				[9.0, 55, 0.24, 4.0], [9.4, 64, 0.26, 0.0], [12.0, 69, 0.25, 3.5],
				[16.0, 41, 0.4, 7.0], [16.8, 60, 0.28, 0.0], [19.2, 69, 0.28, 0.0], [21.5, 67, 0.25, 0.0],
				[24.0, 64, 0.26, 4.0], [27.0, 62, 0.2, 0.0],
				[31.0, 50, 0.38, 7.0], [31.8, 65, 0.28, 0.0], [34.2, 69, 0.28, 0.0], [36.6, 72, 0.25, 0.0],
				[39.0, 71, 0.22, 3.0], [41.6, 68, 0.2, 0.0], [43.5, 52, 0.34, 5.0],
				[48.5, 57, 0.28, 0.0], [50.2, 64, 0.24, 0.0], [52.8, 60, 0.22, 5.0],
			]
		&"menu":
			return [
				[0.6, 50, 0.34, 5.5], [1.1, 69, 0.28, 0.0], [2.8, 65, 0.25, 0.0], [4.5, 64, 0.24, 2.5],
				[8.6, 46, 0.32, 5.5], [9.1, 74, 0.24, 0.0], [10.9, 69, 0.23, 0.0], [12.6, 67, 0.21, 2.5],
				[16.6, 43, 0.3, 5.0], [17.1, 70, 0.22, 0.0], [18.9, 69, 0.21, 0.0], [20.7, 65, 0.2, 0.0],
				[22.6, 64, 0.19, 3.5],
			]
		&"piano_end":
			return [
				[0.5, 48, 0.36, 6.0], [1.0, 64, 0.28, 0.0], [2.4, 67, 0.26, 0.0], [3.8, 72, 0.28, 3.0],
				[7.0, 45, 0.34, 6.0], [7.5, 60, 0.24, 0.0], [8.9, 64, 0.24, 0.0], [10.3, 69, 0.26, 3.0],
				[13.5, 41, 0.32, 6.0], [14.0, 57, 0.22, 0.0], [15.4, 60, 0.22, 0.0], [16.8, 65, 0.24, 0.0],
				[18.4, 64, 0.22, 2.0], [20.5, 43, 0.32, 5.0], [21.0, 59, 0.22, 0.0], [22.4, 62, 0.22, 0.0],
				[23.8, 67, 0.24, 3.0], [27.0, 48, 0.34, 7.0], [27.5, 55, 0.24, 0.0], [28.6, 64, 0.24, 0.0],
				[30.0, 72, 0.22, 6.0],
			]
	return []


static func render(track: StringName, buf: PackedFloat32Array, from: int, to: int) -> void:
	var length: float = LENGTHS[track]
	var gain: float = GAIN[track]
	for n in score(track):
		var ring: float = _ring(MusicSynth.hz(n[1]))
		var hold: float = float(n[3])
		var dur: float = minf(hold + DAMPER * 3.0, ring) if hold > 0.0 else ring
		for wrap in [0.0, -length]:
			if wrap < 0.0 and float(n[0]) + dur <= length:
				continue
			_note(buf, from, to, float(n[0]) + wrap, int(n[1]), float(n[2]) * gain, hold, dur)
	_room(buf, from, to)


## How long a note at `f` Hz rings (low strings ring longer).
static func _ring(f: float) -> float:
	return clampf(5.5 * pow(220.0 / f, 0.4), 2.5, 8.0)


static func _note(buf: PackedFloat32Array, from: int, to: int, start: float, midi: int, vel: float, hold: float, dur: float) -> void:
	var s0: int = int(start * RATE)
	var a: int = maxi(from, s0)
	var b: int = mini(to, s0 + int(dur * RATE))
	if a >= b:
		return
	var f0: float = MusicSynth.hz(midi)
	var tau: float = _ring(f0) * 0.42
	var partials: int = 6 if midi < 55 else (5 if midi < 67 else 4)
	var held: int = int(hold * RATE) if hold > 0.0 else 1 << 30
	for k in range(1, partials + 1):
		var fk: float = k * f0 * sqrt(1.0 + B * k * k)
		if fk > 8000.0:
			break
		# Softer and darker when played gently: upper partials need velocity.
		var amp: float = vel * pow(k, -1.3) * (0.3 + 0.7 * pow(vel * 2.4, 0.6 * (k - 1)))
		var tk: float = tau / (1.0 + 0.6 * (k - 1))
		# Each partial stops once its own ring is ~-50 dB (upper ones early).
		var bk: int = mini(b, s0 + int(tk * 5.8 * RATE))
		_partial(buf, a, bk, s0, held, TAU * fk / RATE, k * 1.7, amp, tk)
		if k == 1:
			# The second string, a hair sharp: a slow beat on the fundamental.
			_partial(buf, a, bk, s0, held, TAU * fk * 1.0016 / RATE, 0.4, amp * 0.35, tk)


## One partial over [a, b): attack, ring, then (after `held`) the damper,
## each a tight loop. Its envelope is a quick drop plus a long ring.
static func _partial(buf: PackedFloat32Array, a: int, b: int, s0: int, held: int, w: float, phase: float, amp: float, tk: float) -> void:
	if a >= b:
		return
	var r_long: float = exp(-1.0 / (tk * RATE))
	var r_short: float = exp(-1.0 / (tk * 0.12 * RATE))
	var damp: float = exp(-1.0 / (DAMPER * RATE))
	var t0: int = a - s0
	var e_long: float = 0.6 * amp * pow(r_long, t0)
	var e_short: float = 0.4 * amp * pow(r_short, t0)
	if t0 > held:
		var d: float = pow(damp, t0 - held)
		e_long *= d
		e_short *= d
	var attack: int = int(ATTACK * RATE)
	var i: int = a
	# The hammer: a soft raised-cosine onset.
	var stop: int = mini(b, s0 + attack)
	while i < stop:
		var t: int = i - s0
		buf[i] += sin(w * t + phase) * (e_long + e_short) * (0.5 - 0.5 * cos(PI * t / attack))
		e_long *= r_long
		e_short *= r_short
		i += 1
	# The ring.
	stop = mini(b, s0 + held)
	while i < stop:
		buf[i] += sin(w * (i - s0) + phase) * (e_long + e_short)
		e_long *= r_long
		e_short *= r_short
		i += 1
	# The damper down.
	var rl: float = r_long * damp
	var rs: float = r_short * damp
	while i < b:
		buf[i] += sin(w * (i - s0) + phase) * (e_long + e_short)
		e_long *= rl
		e_short *= rs
		i += 1


## Two damped feedback echoes, in place, for [from, to). Chunks render in
## order, so the samples they feed from are already final.
static func _room(buf: PackedFloat32Array, from: int, to: int) -> void:
	var d1: int = int(ROOM[0] * RATE)
	var d2: int = int(ROOM[2] * RATE)
	for i in range(maxi(from, d2 + 1), to):
		buf[i] += (buf[i - d1] + buf[i - d1 - 1]) * 0.5 * ROOM[1] + (buf[i - d2] + buf[i - d2 - 1]) * 0.5 * ROOM[3]
