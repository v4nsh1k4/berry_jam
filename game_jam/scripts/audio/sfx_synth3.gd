class_name SfxSynth3
extends RefCounted
## Tonal replacements (Stage 6) for two sounds that read as flatulence: the
## old `creak` (a 95 Hz wobbling sawtooth + noise) and `growl` (a 68 Hz
## sawtooth with a 37 Hz flutter + noise). Nothing here is low noise, nothing
## falls in pitch, and nothing sits under ~150 Hz.
##   groan  C4's stair (the segue into Chapter 3): a strained wooden-metal
##          groan, detuned partials bending slowly UP with a growing vibrato,
##          a high ghostly harmonic fading in on top, a reversed swell (it
##          grows, then cuts into a short echo tail) and a breathy whisper
##          sweep (high-passed noise) under it. ~1.9 s.
##   moan   the mirror ghoul (Stage 6): a soft, sad, breathy "oo" sighing
##          from 262 Hz down to 233 Hz with a slow vibrato, a whisper of
##          high breath on top; quiet, tonal, never a jump. 1.7 s at 11025 Hz.
##   growl  the danger telegraph (Crawler lunge, the hand's aim, the Heart's
##          listen, the reveal's start): a hoarse rising snarl, detuned
##          partials from 160 Hz with fast vibrato, rasp from high-passed
##          noise, a hard attack and a held end. 0.75 s.
## Partials are read from one-cycle wavetables (cheap enough to build one
## per frame through AudioManager._pending).

const RATE: int = SfxSynth.RATE
const TABLE: int = 1024


## One cycle of a sum of partials: [[harmonic, amplitude], ...].
static func _table(partials: Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(TABLE)
	for i in TABLE:
		var v: float = 0.0
		for p in partials:
			v += sin(TAU * float(p[0]) * i / TABLE) * float(p[1])
		out[i] = v
	return out


## The groan, built CHUNK samples per call (AudioManager calls `next()` once
## a frame until it returns the stream; ~18 ms in one go was too much).
class Groan:
	extends RefCounted
	const CHUNK: int = 12000
	const LENGTH: float = 1.9
	var out: PackedFloat32Array = SfxSynth._buffer(LENGTH)
	var body: PackedFloat32Array = SfxSynth3._table([[1, 0.55], [2, 0.32], [3, 0.2], [4, 0.1], [5, 0.07]])
	var ghost: PackedFloat32Array = SfxSynth3._table([[1, 1.0]])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var i: int = 0
	var pa: float = 0.0
	var pb: float = 0.0
	var pg: float = 0.0
	var hp: float = 0.0
	var prev: float = 0.0

	func _init(seed_value: int) -> void:
		rng.seed = seed_value

	func next() -> AudioStreamWAV:
		var table: int = SfxSynth3.TABLE
		var end: int = mini(i + CHUNK, out.size())
		while i < end:
			var t: float = float(i) / RATE
			var k: float = t / LENGTH
			# 180 -> 245 Hz, rising (strain), with a vibrato that widens.
			var vib: float = 1.0 + sin(TAU * 5.3 * t) * lerpf(0.002, 0.018, k)
			var f: float = lerpf(180.0, 245.0, k * k) * vib * (1.0 + (rng.randf() - 0.5) * 0.004)
			pa = fposmod(pa + f / RATE, 1.0)
			pb = fposmod(pb + f * 1.0071 / RATE, 1.0)
			pg = fposmod(pg + f * 7.02 / RATE, 1.0)
			var tone: float = body[int(pa * table)] + body[int(pb * table)] * 0.8
			var high: float = ghost[int(pg * table)] * smoothstep(0.35, 0.8, k) * (0.6 + 0.4 * sin(TAU * 0.9 * t))
			var x: float = rng.randf_range(-1.0, 1.0)
			hp = 0.92 * (hp + x - prev)
			prev = x
			var breath: float = hp * (0.1 + 0.25 * k) * (0.5 + 0.5 * sin(TAU * 0.7 * t + 1.0))
			# Reversed swell: grows to ~82%, then a quick fall.
			var env: float = pow(minf(k / 0.82, 1.0), 2.2) * (1.0 if k < 0.82 else exp(-(t - 0.82 * LENGTH) * 14.0))
			out[i] = (tone * 0.5 + high * 0.22 + breath) * env
			i += 1
		if i < out.size():
			return null
		SfxSynth3._echo(out, 0.21, 0.35)
		SfxSynth3._normalize(out, 0.75)
		return SfxSynth._to_wav(out)


static func groan(seed_value: int = 3) -> AudioStreamWAV:
	var job: Groan = Groan.new(seed_value)
	var w: AudioStreamWAV = null
	while w == null:
		w = job.next()
	return w


static func growl() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 68
	var length: float = 0.75
	var out: PackedFloat32Array = SfxSynth._buffer(length)
	var body: PackedFloat32Array = _table([[1, 0.5], [2, 0.4], [3, 0.3], [5, 0.15], [7, 0.08]])
	var pa: float = 0.0
	var pb: float = 0.0
	var pc: float = 0.0
	var hp: float = 0.0
	var prev: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		var k: float = t / length
		var f: float = lerpf(160.0, 196.0, smoothstep(0.0, 0.6, k)) * (1.0 + sin(TAU * 7.5 * t) * 0.012)
		pa = fposmod(pa + f / RATE, 1.0)
		pb = fposmod(pb + f * 1.012 / RATE, 1.0)
		pc = fposmod(pc + f * 1.414 / RATE, 1.0)
		var tone: float = body[int(pa * TABLE)] + body[int(pb * TABLE)] * 0.7 + body[int(pc * TABLE)] * 0.35
		var x: float = rng.randf_range(-1.0, 1.0)
		hp = 0.85 * (hp + x - prev)
		prev = x
		var env: float = minf(t * 25.0, 1.0) * (1.0 if k < 0.8 else 1.0 - (k - 0.8) / 0.2)
		out[i] = (tone * 0.45 + hp * 0.22) * env
	# Peak 0.5 (-6 dBFS): about the old growl's loudness (RMS ~ -19 dBFS).
	_normalize(out, 0.5)
	return SfxSynth._to_wav(out)


static func moan() -> AudioStreamWAV:
	var rate: int = 11025
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9
	var length: float = 1.7
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(int(length * rate))
	var voice: PackedFloat32Array = _table([[1, 1.0], [2, 0.3], [3, 0.12]])
	var pa: float = 0.0
	var pb: float = 0.0
	var hp: float = 0.0
	var prev: float = 0.0
	for i in out.size():
		var t: float = float(i) / rate
		var k: float = t / length
		var f: float = lerpf(262.0, 233.0, smoothstep(0.2, 0.9, k)) * (1.0 + sin(TAU * 4.2 * t) * 0.01)
		pa = fposmod(pa + f / rate, 1.0)
		pb = fposmod(pb + f * 1.006 / rate, 1.0)
		var x: float = rng.randf_range(-1.0, 1.0)
		hp = 0.8 * (hp + x - prev)
		prev = x
		var env: float = sin(PI * minf(k * 1.15, 1.0)) * (1.0 - k * 0.3)
		out[i] = (voice[int(pa * TABLE)] + voice[int(pb * TABLE)] * 0.7 + hp * 0.12) * env
	_normalize(out, 0.45)
	var wav: AudioStreamWAV = SfxSynth._to_wav(out)
	wav.mix_rate = rate
	return wav


## A short feedback echo (a stairwell), in place.
static func _echo(out: PackedFloat32Array, delay: float, feedback: float) -> void:
	var d: int = int(delay * RATE)
	for i in range(d, out.size()):
		out[i] += out[i - d] * feedback


static func _normalize(out: PackedFloat32Array, peak: float) -> void:
	var m: float = 0.0001
	for v in out:
		m = maxf(m, absf(v))
	for i in out.size():
		out[i] = out[i] / m * peak
