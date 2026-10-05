extends SceneTree
## Music test (dev, not exported): renders every track the way the game does
## (chunked across frames), reports render time, the slowest frame, peak
## level (clipping) and the loop seam jump; then checks track switching.
## Stage 5: the bed is under every Chapter 1-3 room (no dead silence), drops
## for cutscenes / scares / lunges and is back within ~2 s, is off for the
## reveal and the return phase; the new sounds (door creaks, scare_low) and
## the cry's variants build without a long frame and don't clip.
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

func _go(frame: String) -> void:
	var gs = root.get_node("/root/GameState")
	var ch = load("res://scripts/systems/debug_jump.gd").prepare(frame)
	gs.current_chapter = ch
	gs.is_playing = true
	gs.chapter_start = gs.to_dict()
	root.get_node("/root/FrameManager").go_to(StringName(frame))
	await _wait(1.0)

## Seconds until the bed is back near its level (or -1).
func _bed_back(limit: float) -> float:
	var waited := 0.0
	while waited < limit:
		if mm._bed.volume_db > mm.BED_DB - 3.0:
			return waited
		await _wait(0.05)
		waited += 0.05
	return -1.0

func _bed() -> void:
	var am = root.get_node("/root/AudioManager")
	for frame in ["ch3_margin", "ch2_clock_room", "ch1_landing", "ch2_long_hallway", "ch3_gallery_words"]:
		await _go(frame)
		# A monster's lunges duck it on purpose (checked below): hold them still.
		for c in get_nodes_in_group(&"crawler"):
			c.process_mode = Node.PROCESS_MODE_DISABLED
		await _wait(2.0)
		var present := 0
		for i in 30:
			await _wait(0.1)
			present += 1 if mm._bed.playing and mm._bed.volume_db > mm.BED_DB - 9.0 else 0
		_check("bed under %s (%s, bed present %d%% of 3 s)" % [frame, mm._playing, present * 100 / 30], present >= 24)
	mm.duck(0.6, 999.0)
	await _wait(0.6)
	var ducked: float = mm._bed.volume_db
	mm.duck(0.0, 0.0)
	var back: float = await _bed_back(3.0)
	print("cutscene: bed ducked to %.1f dB, back after %.2f s" % [ducked, back])
	_check("bed back within ~2 s after a cutscene", back >= 0.0 and back <= 2.2)
	bus.crawler_telegraph.emit()
	await _wait(0.5)
	var lunge: float = mm._bed.volume_db
	back = await _bed_back(4.0)
	print("pre-lunge drop: bed %.1f dB, back after %.2f s" % [lunge, back])
	_check("bed drops before a lunge and is back within ~2.5 s", lunge < -40.0 and back >= 0.0 and back <= 2.5)
	bus.scare_building.emit(&"test", 3.0)
	await _wait(2.0)
	var build: float = mm._bed.volume_db
	var drone: float = am._drone.volume_db
	bus.scare.emit(&"test", 1.0)
	await _wait(1.0)
	var hit: float = mm._bed.volume_db
	back = await _bed_back(5.0)
	print("scare: build %.1f dB (drone %.1f), hit %.1f dB, back %.2f s after" % [build, drone, hit, back + 1.0])
	_check("scare build drops music and ambience near silence", build < -40.0 and drone <= -59.0)
	_check("bed back within ~2 s after the scare's silence", back >= 0.0 and back <= 2.6)
	var gs = root.get_node("/root/GameState")
	bus.reveal_started.emit()
	await _wait(2.5)
	_check("bed off for the reveal (%.1f dB)" % mm._bed.volume_db, mm._bed.volume_db < -60.0)
	gs.twist_revealed = true
	await _go("ch3_returning_room")
	await _wait(2.5)
	_check("bed off in the return phase (%s, %.1f dB)" % [mm._playing, mm._bed.volume_db], mm._bed.volume_db < -60.0)

func _sfx() -> void:
	var am = root.get_node("/root/AudioManager")
	var builders := {"door_creak": SfxSynth2.door_creak.bind(5), "scare_low": SfxSynth2.scare_low, "wail": SfxSynth2.wail,
		"scare_hit (4C)": SfxSynth2.scare_hit, "sting (4C)": SfxSynth2.sting}
	for id in builders:
		var u0: int = Time.get_ticks_usec()
		builders[id].call()
		print("build %-14s %.1f ms" % [id, (Time.get_ticks_usec() - u0) / 1000.0])
	var u1: int = Time.get_ticks_usec()
	am._cry._pos = 0
	am._cry.step()
	print("cry low-pass chunk %.1f ms" % ((Time.get_ticks_usec() - u1) / 1000.0))
	while am._cry._pos >= 0:
		am._cry.step()
	var worst: int = 0
	var waited := 0
	while (not am._pending.is_empty() or am._cry._pos >= 0) and waited < 600:
		var f0: int = Time.get_ticks_usec()
		await process_frame
		worst = maxi(worst, Time.get_ticks_usec() - f0)
		waited += 1
	print("(sounds are built one per frame during the track renders above; the slowest frame there includes them)")
	print("sfx + cry variants built over %d frames, slowest frame %.1f ms, cry file missing: %s" % [waited, worst / 1000.0, am._cry.missing])
	_check("new sounds built", am._streams.has(&"door_creak_2") and am._streams.has(&"scare_low"))
	_check("cry variants raw / low / thin", am._cry.streams.has(&"raw") and am._cry.streams.has(&"low") and am._cry.streams.has(&"thin"))
	_check("the real recording loaded", not am._cry.missing)
	for id in [&"door_creak_0", &"door_creak_1", &"door_creak_2", &"scare_low"]:
		var data: PackedByteArray = am._streams[id].data
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		var secs: float = data.size() / 2.0 / 22050.0
		print("%-14s %.2fs peak %.2f" % [id, secs, peak / 32767.0])
		_check("%s does not clip" % id, peak < 32700)
	var raw = am._cry.streams[&"raw"]
	var thin = am._cry.streams[&"thin"]
	print("cry raw %.2fs @ %d Hz, thin %.2fs" % [raw.data.size() / 2.0 / raw.mix_rate, raw.mix_rate, thin.data.size() / 2.0 / thin.mix_rate])
	am.play_door_creak()
	_check("door creak plays", String(am.last_played).begins_with("door_creak"))

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
	await _sfx()
	await _bed()
	print("MUSIC TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
