extends SceneTree
## Music test (dev, not exported): renders every track the way the game does
## (chunked across frames), reports render time, the slowest frame, peak
## level (clipping) and the loop seam jump; then checks track switching.
## Stage 5: the new sounds (door creaks, scare_low) and the cry's variants
## build without a long frame and don't clip.
## Stage 6: the team's bg_track.wav (length / channels / rate / size) plays
## under every Chapter 1-3 room without gaps or restarts, keeps running
## under a door creak (dipping ~3 dB), drops for cutscenes / scares / lunges
## / the reveal and is back within ~2 s, is off in the return phase, loops
## with a crossfade; ending.wav plays once at the epilogue, then the
## synthesized ending; Back to Menu stops everything; the menu's melancholy
## layer plays only on the menu, doesn't clip, and respects mute and focus;
## the tonal groan / growl replace the old creak / growl.
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

## Seconds until bg_track is back near its level (or -1).
func _bg_back(limit: float) -> float:
	var waited := 0.0
	while waited < limit:
		if mm._files.level > MusicFiles.BG_DB - 3.5:
			return waited
		await _wait(0.05)
		waited += 0.05
	return -1.0

## Seconds until bg_track has dropped below -60 dB (or -1).
func _bg_gone(limit: float) -> float:
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < limit * 1000.0:
		if mm._files.level < -60.0:
			return (Time.get_ticks_msec() - t0) / 1000.0
		await process_frame
	return -1.0

func _pos() -> float:
	return mm._files._bg[mm._files._cur].get_playback_position()

func _files_info() -> void:
	for path in [MusicFiles.BG_PATH, MusicFiles.ENDING_PATH]:
		var exists: bool = ResourceLoader.exists(path)
		_check("%s exists" % path, exists)
		if not exists:
			continue
		var u0: int = Time.get_ticks_usec()
		var w: AudioStreamWAV = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var load_ms: float = (Time.get_ticks_usec() - u0) / 1000.0
		var f := FileAccess.open(path, FileAccess.READ)
		var src: String = "%.2f MB source" % (f.get_length() / 1048576.0) if f != null else "source not in this pack"
		print("%s: %.2f s, %s, %d Hz, format %d, %.2f MB imported data, %s, load %.1f ms" % [path, w.get_length(),
			"stereo" if w.stereo else "mono", w.mix_rate, w.format, w.data.size() / 1048576.0, src, load_ms])
	_check("bg_track loaded at start-up (before the click)", mm._files.bg != null and mm._files.ending != null)

func _bg() -> void:
	var am = root.get_node("/root/AudioManager")
	var last_pos := -1.0
	var restarts := 0
	for frame in ["ch1_landing", "ch3_margin", "ch2_clock_room", "ch2_long_hallway", "ch3_gallery_words"]:
		var before: float = _pos() if mm._files.playing_bg() else -1.0
		await _go(frame)
		for c in get_nodes_in_group(&"crawler"):
			c.process_mode = Node.PROCESS_MODE_DISABLED
		var after: float = _pos()
		if before >= 0.0 and after < before:
			restarts += 1
		print("  %s: bg position %.2f -> %.2f s (loops %d)" % [frame, before, after, mm._files.loops])
		await _wait(2.0)
		var present := 0
		for i in 30:
			await _wait(0.1)
			present += 1 if mm._files.playing_bg() and mm._files.level > MusicFiles.BG_DB - 6.0 else 0
		_check("bg_track under %s (base %s silent: %.0f dB, bed %.0f dB), present %d%% of 3 s" % [frame, mm._playing,
			mm._players[mm._active].volume_db, mm._bed.volume_db, present * 100 / 30],
			present >= 29 and mm._players[mm._active].volume_db < -60.0 and mm._bed.volume_db < -60.0)
	_check("bg_track never restarted across room changes", restarts == 0)
	# A door creak plays OVER it: it keeps going and dips ~3 dB, then eases back.
	await _wait(1.0)
	var p0: float = _pos()
	am.play_door_creak()
	var low := 0.0
	var t1: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 700:
		await process_frame
		low = minf(low, mm._files.level - MusicFiles.BG_DB)
	var still: bool = mm._files.playing_bg() and _pos() > p0
	await _wait(1.0)
	print("door creak: bg dipped %.1f dB, still playing %s, after 1 s %.1f dB" % [low, still, mm._files.level])
	_check("bg_track keeps playing under a door creak, dipping ~3 dB", still and low < -2.0 and low > -4.5
		and absf(mm._files.level - MusicFiles.BG_DB) < 0.6)
	for big in ["cutscene", "lunge", "scare"]:
		p0 = _pos()
		match big:
			"cutscene": mm.duck(0.6, 999.0)
			"lunge": bus.crawler_telegraph.emit()
			"scare": bus.scare.emit(&"test", 1.0)
		var gone: float = await _bg_gone(1.0)
		if big == "cutscene":
			await _wait(1.0)
			mm.duck(0.0, 0.0)
		var back: float = await _bg_back(5.0)
		print("%s: bg out after %.2f s, back after %.2f s, playing through: %s" % [big, gone, back, _pos() > p0])
		_check("bg_track fades out (~0.3 s) for a %s and is back within ~2 s" % big, gone >= 0.0 and gone <= 0.45
			and back >= 0.0 and back <= (2.2 if big == "cutscene" else 2.7))
	# The loop point: a crossfade, never silence.
	var length: float = mm._files.bg.get_length()
	mm._files._bg[mm._files._cur].seek(length - MusicFiles.XFADE - 0.6)
	mm._files._time = length - MusicFiles.XFADE - 0.6
	var loops0: int = mm._files.loops
	var quiet := 0
	for i in 60:
		await _wait(0.05)
		if i % 6 == 0:
			print("    t=%.2f cur=%d x=%s pos=%.2f/%.2f playing=%s/%s vol=%.1f/%.1f" % [mm._files._time, mm._files._cur, mm._files._fading,
				mm._files._bg[0].get_playback_position(), mm._files._bg[1].get_playback_position(), mm._files._bg[0].playing,
				mm._files._bg[1].playing, mm._files._bg[0].volume_db, mm._files._bg[1].volume_db])
		var sum := 0.0
		for pl in mm._files._bg:
			sum += db_to_linear(pl.volume_db) if pl.playing else 0.0
		quiet += 1 if sum < db_to_linear(MusicFiles.BG_DB - 4.0) else 0
	print("loop: %d -> %d loops, position now %.2f s, %d quiet samples" % [loops0, mm._files.loops, _pos(), quiet])
	_check("bg_track loops with a crossfade (no gap)", mm._files.loops == loops0 + 1 and quiet == 0 and _pos() < 3.0)
	var gs = root.get_node("/root/GameState")
	bus.reveal_started.emit()
	var gone2: float = await _bg_gone(1.0)
	await _wait(2.0)
	_check("bg_track off for the reveal (out after %.2f s)" % gone2, gone2 >= 0.0 and gone2 < 0.45 and mm._files.level < -60.0)
	gs.twist_revealed = true
	await _go("ch3_returning_room")
	await _wait(4.0)
	_check("bg_track off and stopped in the return phase (%s)" % mm._playing, not mm._files.playing_bg() and mm._playing == &"return")

func _ending() -> void:
	var gs = root.get_node("/root/GameState")
	gs.set_flag(&"comic_repaired")
	await _go("ch3_escape")
	await _wait(2.0)
	var f = mm._files
	bus.frame_changed.emit(load("res://data/frames/ch3_outside.tres"))
	var states := []
	var started := -1.0
	var waited := 0.0
	var base_quiet := true
	while waited < 9.0:
		await _wait(0.1)
		waited += 0.1
		if states.is_empty() or states[-1] != f.end_state:
			states.append(f.end_state)
			if f.end_state == MusicFiles.End.PLAYING:
				started = waited
		if f.end_state == MusicFiles.End.PLAYING and waited > started + 0.3:
			base_quiet = base_quiet and mm._players[mm._active].volume_db < -60.0
	print("ending states %s, the sting started %.1f s after the epilogue began; synthesized ending now %s at %.1f dB" % [states,
		started, mm._playing, mm._players[mm._active].volume_db])
	_check("ending.wav plays once at the epilogue, the old track faded first", states == [1, 2, 3] and started >= 0.9 and base_quiet)
	await _wait(2.0)
	_check("then the synthesized ending carries on, quietly", mm._playing == &"ending" and mm._players[mm._active].volume_db > -30.0
		and mm._players[mm._active].volume_db < mm.BASE_DB - 4.0)
	bus.frame_changed.emit(load("res://data/frames/ch3_outside.tres"))
	await _wait(1.5)
	_check("the sting does not play twice", f.end_state == MusicFiles.End.DONE and not f._end.playing)
	gs.is_playing = false
	bus.returned_to_menu.emit()
	await _wait(0.3)
	_check("Back to Menu stops the files", not f._end.playing and not f.playing_bg() and f.end_state == MusicFiles.End.IDLE)
	await _wait(3.0)
	_check("menu: melancholy layer up (%.1f dB), menu track playing" % mm._sad.volume_db, mm._playing == &"menu"
		and mm._sad.playing and absf(mm._sad.volume_db - mm.SAD_DB) < 1.0)
	var index: int = AudioServer.get_bus_index(&"Music")
	mm.set_music_muted(true)
	var muted: bool = AudioServer.is_bus_mute(index)
	mm.set_music_muted(false)
	mm._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var focus: bool = AudioServer.is_bus_mute(index)
	mm._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_check("Music bus (menu layer, bg_track, ending) mutes for mute and focus loss", muted and focus and not AudioServer.is_bus_mute(index))
	# The menu track and its layer together at their levels never clip.
	var a := PackedFloat32Array()
	a.resize(MusicSynth.total_samples(&"menu_sad"))
	MusicSynth.render(&"menu_sad", a, 0, a.size())
	var m := PackedFloat32Array()
	m.resize(MusicSynth.total_samples(&"menu"))
	MusicSynth.render(&"menu", m, 0, m.size())
	var peak := 0.0
	var gaps := 0
	var run := 0
	for i in a.size():
		peak = maxf(peak, absf(m[i % m.size()] * db_to_linear(mm.BASE_DB) + a[i] * db_to_linear(mm.SAD_DB)))
		run = run + 1 if absf(a[i]) < 0.004 else 0
		gaps += 1 if run == int(2.0 * 22050) else 0
	print("menu + melancholy peak %.3f (at their volumes), silent gaps of 2 s+ in the layer: %d" % [peak, gaps])
	_check("menu + melancholy do not clip; the layer leaves gaps of silence", peak < 0.98 and gaps >= 2)

func _sfx() -> void:
	var am = root.get_node("/root/AudioManager")
	var groan_job = SfxSynth3.Groan.new(1)
	var builders := {"door_creak": SfxSynth2.door_creak.bind(5), "scare_low": SfxSynth2.scare_low, "wail": SfxSynth2.wail,
		"scare_hit (4C)": SfxSynth2.scare_hit, "sting (4C)": SfxSynth2.sting, "growl (6)": SfxSynth3.growl,
		"groan chunk (6)": groan_job.next}
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
	_check("new sounds built", am._streams.has(&"door_creak_2") and am._streams.has(&"scare_low") and am._streams.has(&"groan"))
	_check("the old creak is gone", not am._streams.has(&"creak"))
	_check("cry variants raw / low / thin", am._cry.streams.has(&"raw") and am._cry.streams.has(&"low") and am._cry.streams.has(&"thin"))
	_check("the real recording loaded", not am._cry.missing)
	for id in [&"door_creak_0", &"door_creak_1", &"door_creak_2", &"scare_low", &"groan", &"growl"]:
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
	var expected: int = MusicSynth.TRACKS.size() - (4 if MusicFiles.bg_exists() else 0)
	while mm._renderer.streams.size() < expected:
		var f0: int = Time.get_ticks_usec()
		await process_frame
		worst = maxi(worst, Time.get_ticks_usec() - f0)
		if first_menu < 0 and mm.is_ready(&"menu"):
			first_menu = Time.get_ticks_msec() - t0
		if Time.get_ticks_msec() - t0 > 120000:
			break
	print("menu ready after %d ms, all tracks after %d ms, slowest frame %.1f ms" % [first_menu, Time.get_ticks_msec() - t0, worst / 1000.0])
	_check("all tracks rendered (%d; ch1-3 + bed skipped: bg_track covers them)" % expected, mm._renderer.streams.size() == expected)
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
	await _files_info()
	await _sfx()
	await _bg()
	await _ending()
	print("MUSIC TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
