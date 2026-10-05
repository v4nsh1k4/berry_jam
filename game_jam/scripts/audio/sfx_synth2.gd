class_name SfxSynth2
extends RefCounted
## More code-built sounds (Stage 4C): cutscene and scare sounds. Same format
## as SfxSynth.

const RATE: int = SfxSynth.RATE


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	return SfxSynth._to_wav(samples)


## A pen nib scratching a short line: dry, bright, a few strokes.
static func nib() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(0.45)
	var prev: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		var n: float = randf_range(-1.0, 1.0)
		var hp: float = n - prev
		prev = n
		var strokes: float = pow(maxf(sin(TAU * 6.5 * t), 0.0), 0.5)
		out[i] = hp * strokes * minf(t * 40.0, 1.0) * (1.0 - t / 0.45) * 0.35
	return _wav(out)


## A breathy whisper: band-limited noise swelling and falling, two syllables.
static func whisper() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(1.1)
	var lp: float = 0.0
	var lp2: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		var n: float = randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.35)
		lp2 = lerpf(lp2, lp, 0.25)
		var band: float = lp - lp2
		var syll: float = pow(maxf(sin(PI * t / 0.5), 0.0), 2.0) if t < 0.5 else pow(maxf(sin(PI * (t - 0.55) / 0.55), 0.0), 2.0)
		out[i] = band * syll * 1.6
	return _wav(out)


## A horror sting: a detuned cluster stab with a scraping noise burst.
static func sting() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(1.6)
	var freqs: PackedFloat32Array = [146.8, 155.6, 207.7, 311.1, 329.6]
	for i in out.size():
		var t: float = float(i) / RATE
		var v: float = 0.0
		for f in freqs:
			var saw: float = fmod(t * f, 1.0) * 2.0 - 1.0
			v += saw * 0.18
		var env: float = minf(t * 200.0, 1.0) * exp(-t * 2.2)
		var scrape: float = randf_range(-1.0, 1.0) * exp(-t * 9.0) * 0.5
		out[i] = (v * env + scrape) * 0.7
	return _wav(out)


## A paper page turning: a soft noise sweep with a flap at the end.
static func swoosh() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(0.5)
	var lp: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		lp = lerpf(lp, randf_range(-1.0, 1.0), lerpf(0.05, 0.5, t / 0.5))
		var env: float = sin(PI * t / 0.5)
		var flap: float = randf_range(-1.0, 1.0) * exp(-absf(t - 0.42) * 60.0) * 0.6
		out[i] = (lp * env * 0.8 + flap) * 0.6
	return _wav(out)


## The jumpscare hit: a sub thump, a shrieking cluster and noise, all at once.
static func scare_hit() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(1.2)
	var phase: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		phase += TAU * lerpf(900.0, 1400.0, minf(t * 3.0, 1.0)) / RATE
		var shriek: float = (sin(phase) + sin(phase * 1.06) + sin(phase * 1.49)) * 0.22 * exp(-t * 3.0)
		var thump: float = sin(TAU * 42.0 * t) * exp(-t * 6.0)
		var noise: float = randf_range(-1.0, 1.0) * exp(-t * 5.0) * 0.5
		out[i] = (shriek + thump + noise) * 0.75
	return _wav(out)


## A wooden door creak (Stage 5): stick-slip pulses at a slowly gliding rate
## with an irregular wobble (and the odd catch), rung through two wood
## resonances, over soft filtered friction noise. Each seed is a different
## creak; AudioManager also jitters the pitch per play.
static func door_creak(seed_value: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var length: float = rng.randf_range(0.75, 0.95)
	var out: PackedFloat32Array = SfxSynth._buffer(length)
	var start_hz: float = rng.randf_range(52.0, 72.0)
	var top_hz: float = start_hz * rng.randf_range(1.6, 2.2)
	var c1: float = 2.0 * 0.985 * cos(TAU * rng.randf_range(360.0, 440.0) / RATE)
	var c2: float = 2.0 * 0.97 * cos(TAU * rng.randf_range(780.0, 960.0) / RATE)
	var a1: float = 0.0
	var b1: float = 0.0
	var a2: float = 0.0
	var b2: float = 0.0
	var phase: float = 0.0
	var wob: float = 0.0
	var wob_to: float = 0.0
	var hold: int = 0
	var peak: float = 0.0
	for i in out.size():
		var k: float = float(i) / out.size()
		hold -= 1
		if hold <= 0:
			hold = rng.randi_range(180, 900)
			wob_to = -0.65 if rng.randf() < 0.12 else rng.randf_range(-0.3, 0.3)
		wob = lerpf(wob, wob_to, 0.006)
		phase += lerpf(start_hz, top_hz, sin(PI * minf(k * 0.9, 0.5))) * (1.0 + wob) / RATE
		var x: float = 0.0
		if phase >= 1.0:
			phase -= 1.0
			x = rng.randf_range(0.5, 1.0)
		var y1: float = x + c1 * a1 - 0.970225 * b1
		b1 = a1
		a1 = y1
		var y2: float = x + c2 * a2 - 0.9409 * b2
		b2 = a2
		a2 = y2
		out[i] = y1 * 0.65 + y2 * 0.35
		peak = maxf(peak, absf(out[i]))
	var lp: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.06)
		var env: float = minf(t * 20.0, 1.0) * minf((length - t) * 5.0, 1.0) * (0.8 + 0.2 * sin(t * 9.0 + seed_value))
		out[i] = (out[i] / maxf(peak, 0.001) * 0.55 + lp * 0.35) * env
	return _wav(out)


## The cellar scare's hit: a sub drop, a growling low cluster and a burst of
## noise. Louder and lower than scare_hit.
static func scare_low() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(1.8)
	var phase: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		phase += TAU * lerpf(62.0, 28.0, minf(t / 1.2, 1.0)) / RATE
		var sub: float = sin(phase) * exp(-t * 1.6)
		var cluster: float = fmod(t * 73.4, 1.0) + fmod(t * 77.8, 1.0) + fmod(t * 110.0, 1.0) + fmod(t * 116.5, 1.0) - 2.0
		var noise: float = randf_range(-1.0, 1.0) * exp(-t * 7.0) * 0.45
		out[i] = tanh((sub * 0.9 + cluster * 0.24 * exp(-t * 1.2)) * 1.6 + noise) * 0.85
	return _wav(out)


## Fallback for the team's recorded cry if res://audio/baby_cry.wav is
## missing: a vowel-like wail (harmonics weighted by "aa" formants) whose
## pitch rises, breaks and falls, with vibrato.
static func wail() -> AudioStreamWAV:
	var out: PackedFloat32Array = SfxSynth._buffer(2.2)
	var phase: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		var hz: float = 420.0 + 160.0 * sin(PI * minf(t / 1.4, 1.0)) - 120.0 * maxf(t - 1.4, 0.0) + sin(TAU * 6.0 * t) * 14.0
		phase += hz / RATE
		var v: float = 0.0
		for h in range(1, 9):
			var f: float = hz * h
			v += sin(TAU * phase * h) * (exp(-pow((f - 850.0) / 300.0, 2.0)) + 0.6 * exp(-pow((f - 1250.0) / 350.0, 2.0)) + 0.08 / h)
		var env: float = minf(t * 6.0, 1.0) * minf((2.2 - t) * 3.0, 1.0) * (0.8 + 0.2 * sin(TAU * 2.3 * t))
		out[i] = v * env * 0.3
	return _wav(out)
