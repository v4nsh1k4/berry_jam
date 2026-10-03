class_name SfxSynth
extends RefCounted
## Builds every sound in code as 16-bit AudioStreamWAV clips. Pre-rendering
## (instead of AudioStreamGenerator) is reliable in single-threaded web builds.

const RATE: int = 22050


static func _to_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav


static func _buffer(seconds: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


## Soft scuff: low-passed noise with a fast decay.
static func footstep() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.09)
	var smooth: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		smooth = lerpf(smooth, randf_range(-1.0, 1.0), 0.18)
		out[i] = smooth * exp(-t * 45.0) * 0.9
	return _to_wav(out)


## Rising "fwip" as a word is torn away.
static func steal() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.32)
	var phase: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		phase += TAU * lerpf(220.0, 1100.0, pow(t / 0.32, 0.6)) / RATE
		var env: float = minf(t * 60.0, 1.0) * exp(-t * 7.0)
		out[i] = (sin(phase) * 0.6 + randf_range(-0.2, 0.2)) * env * 0.5
	return _to_wav(out)


## Door creak: a slow, wobbling sawtooth with grit.
static func creak() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.7)
	var phase: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		phase += (95.0 + 40.0 * sin(t * 9.0) + 20.0 * sin(t * 31.0)) / RATE
		var saw: float = fmod(phase, 1.0) * 2.0 - 1.0
		var env: float = minf(t * 12.0, 1.0) * (1.0 - t / 0.7)
		out[i] = (saw * 0.45 + randf_range(-0.12, 0.12)) * env * 0.5
	return _to_wav(out)


## Wrong-word thud: a low sine knock.
static func thud() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.28)
	for i in out.size():
		var t: float = float(i) / RATE
		var freq: float = lerpf(110.0, 55.0, t / 0.28)
		out[i] = (sin(TAU * freq * t) + randf_range(-0.15, 0.15) * exp(-t * 60.0)) * exp(-t * 14.0) * 0.8
	return _to_wav(out)


## Little bell when a word works.
static func chime() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.5)
	for i in out.size():
		var t: float = float(i) / RATE
		out[i] = (sin(TAU * 660.0 * t) * 0.6 + sin(TAU * 990.0 * t) * 0.3) * exp(-t * 7.0) * 0.4
	return _to_wav(out)


static func click() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.04)
	for i in out.size():
		var t: float = float(i) / RATE
		out[i] = randf_range(-1.0, 1.0) * exp(-t * 160.0) * 0.6
	return _to_wav(out)


## Splat when the Crawler catches you.
static func splat() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.45)
	var smooth: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		smooth = lerpf(smooth, randf_range(-1.0, 1.0), 0.08)
		out[i] = (smooth * 2.0 + sin(TAU * 70.0 * t) * 0.5) * exp(-t * 8.0) * 0.6
	return _to_wav(out)


## Ambient drone: two detuned low tones and a slow swell. Every partial
## completes whole cycles in the loop, so it loops without a click.
static func drone() -> AudioStreamWAV:
	var seconds: float = 8.0
	var out: PackedFloat32Array = _buffer(seconds)
	for i in out.size():
		var t: float = float(i) / RATE
		var swell: float = 0.75 + 0.25 * sin(TAU * t / seconds)
		var tone: float = sin(TAU * 55.0 * t) * 0.5 + sin(TAU * 55.625 * t) * 0.4 + sin(TAU * 82.5 * t) * 0.18
		out[i] = tone * swell * 0.35
	return _to_wav(out, true)


## Heartbeat: "lub-dub", two low thumps.
static func heartbeat() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.42)
	for i in out.size():
		var t: float = float(i) / RATE
		var lub: float = sin(TAU * 52.0 * t) * exp(-t * 28.0)
		var t2: float = maxf(0.0, t - 0.17)
		var dub: float = sin(TAU * 46.0 * t2) * exp(-t2 * 34.0) * 0.75 if t > 0.17 else 0.0
		out[i] = (lub + dub) * 0.9
	return _to_wav(out)


## Sub-bass rumble loop under a moving Crawler. Whole cycles only, so it
## loops cleanly; a 4 Hz wobble makes it feel wet.
static func rumble() -> AudioStreamWAV:
	var seconds: float = 2.0
	var out: PackedFloat32Array = _buffer(seconds)
	for i in out.size():
		var t: float = float(i) / RATE
		var wobble: float = 0.7 + 0.3 * sin(TAU * 4.0 * t)
		out[i] = (sin(TAU * 32.0 * t) * 0.6 + sin(TAU * 38.5 * t) * 0.4) * wobble * 0.7
	return _to_wav(out, true)


## Wet skitter: a few clicky, damp noise ticks.
static func skitter() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.22)
	var smooth: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		smooth = lerpf(smooth, randf_range(-1.0, 1.0), 0.35)
		var ticks: float = 0.0
		for k in 4:
			var tk: float = t - k * 0.05
			if tk >= 0.0:
				ticks += exp(-tk * 90.0)
		out[i] = smooth * ticks * 0.7
	return _to_wav(out)


## Low growl: the fair warning before a lunge.
static func growl() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.75)
	var phase: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		phase += (68.0 + 9.0 * sin(t * 37.0)) / RATE
		var saw: float = fmod(phase, 1.0) * 2.0 - 1.0
		var env: float = minf(t * 8.0, 1.0) * (1.0 - t / 0.75)
		out[i] = (saw * 0.55 + randf_range(-0.2, 0.2)) * env * 0.7
	return _to_wav(out)


## A pen scratching something out hard: the Ink Shadow erasing a hiding spot.
static func scribble() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.8)
	var smooth: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		smooth = lerpf(smooth, randf_range(-1.0, 1.0), 0.6)
		var strokes: float = 0.5 + 0.5 * sin(TAU * 9.0 * t)
		out[i] = smooth * strokes * (1.0 - t / 0.8) * 0.6
	return _to_wav(out)


## Rubber dragged hard across paper: the Artist's eraser coming down.
static func rub() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.6)
	var smooth: float = 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		smooth = lerpf(smooth, randf_range(-1.0, 1.0), 0.18)
		var strokes: float = 0.55 + 0.45 * sin(TAU * 13.0 * t)
		out[i] = smooth * strokes * minf(t * 20.0, 1.0) * (1.0 - t / 0.6) * 1.4
	return _to_wav(out)


## A book slammed shut: a deep thump with a papery slap on top.
static func slam() -> AudioStreamWAV:
	var out: PackedFloat32Array = _buffer(0.7)
	for i in out.size():
		var t: float = float(i) / RATE
		var thump: float = sin(TAU * 55.0 * t) * exp(-t * 9.0)
		var slap: float = randf_range(-1.0, 1.0) * exp(-t * 45.0)
		out[i] = (thump * 0.9 + slap * 0.5) * 0.8
	return _to_wav(out)
