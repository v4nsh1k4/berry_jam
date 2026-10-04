extends SceneTree
## Music test (dev, not exported): renders every track the way the game does
## (chunked across frames), reports render time, the slowest frame, peak
## level (clipping) and the loop seam jump; then checks track switching.
##   godot --path . --script res://tests/playthroughs/music_check.gd

var mm
var bus
var ok := true

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _check(label: String, cond: bool) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	ok = ok and cond

func _run() -> void:
	mm = root.get_node("/root/MusicManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	var t0: int = Time.get_ticks_msec()
	bus.game_started.emit()
	var worst: int = 0
	var first_menu: int = -1
	while mm._renderer.streams.size() < MusicSynth.TRACKS.size():
		var f0: int = Time.get_ticks_usec()
		await process_frame
		worst = maxi(worst, Time.get_ticks_usec() - f0)
		if first_menu < 0 and mm.is_ready(&"menu"):
			first_menu = Time.get_ticks_msec() - t0
		if Time.get_ticks_msec() - t0 > 120000:
			break
	print("menu ready after %d ms, all tracks after %d ms, slowest frame %.1f ms" % [first_menu, Time.get_ticks_msec() - t0, worst / 1000.0])
	_check("all tracks rendered", mm._renderer.streams.size() == MusicSynth.TRACKS.size())
	for track in MusicSynth.TRACKS:
		var buf := PackedFloat32Array()
		buf.resize(MusicSynth.total_samples(track))
		MusicSynth.render(track, buf, 0, buf.size())
		buf = MusicSynth.fold_loop(track, buf)
		var peak := 0.0
		for v in buf:
			peak = maxf(peak, absf(v))
		var seam: float = absf(buf[0] - buf[buf.size() - 1]) if MusicSynth.loops(track) else 0.0
		print("%-16s %5.1fs peak %.2f seam %.3f" % [track, buf.size() / 22050.0, peak, seam])
		_check("%s does not clip" % track, peak < 0.98)
		_check("%s loops without a click" % track, seam < 0.08)
	_check("menu playing", mm._playing == &"menu")
	print("MUSIC TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
