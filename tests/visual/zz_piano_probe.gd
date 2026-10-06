extends SceneTree
func _rms(buf: PackedFloat32Array) -> float:
	var s: float = 0.0
	for v in buf:
		s += v * v
	return sqrt(s / buf.size())

func _initialize() -> void:
	for track in [&"menu", &"piano_bed", &"piano_end", &"warm", &"return"]:
		var r = load("res://scripts/audio/music_renderer.gd").new()
		r.queue.append(track)
		var t0: int = Time.get_ticks_usec()
		var worst: int = 0
		var calls: int = 0
		while not r.streams.has(track):
			var u: int = Time.get_ticks_usec()
			r.step()
			worst = maxi(worst, Time.get_ticks_usec() - u)
			calls += 1
		var render_ms: int = (Time.get_ticks_usec() - t0) / 1000
		var wav: AudioStreamWAV = r.streams[track]
		var data: PackedByteArray = wav.data
		var n: int = data.size() / 2
		var buf: PackedFloat32Array = PackedFloat32Array()
		buf.resize(n)
		var peak: float = 0.0
		for i in n:
			buf[i] = data.decode_s16(i * 2) / 32767.0
			peak = maxf(peak, absf(buf[i]))
		var seam: float = absf(buf[0] - buf[n - 1])
		print("%-10s %5.1fs render %4d ms in %d frames (worst call %.1f ms) peak %.3f (%.1f dBFS) rms %.1f dBFS seam %.4f" % [track, n / 22050.0, render_ms, calls, worst / 1000.0, peak, linear_to_db(peak), linear_to_db(_rms(buf)), seam])
	if ResourceLoader.exists("res://audio/bg_track.wav"):
		var bg: AudioStreamWAV = load("res://audio/bg_track.wav")
		print("bg_track: format ", bg.format, " stereo ", bg.stereo, " rate ", bg.mix_rate)
	quit()
