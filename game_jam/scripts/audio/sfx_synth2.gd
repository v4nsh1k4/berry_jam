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
