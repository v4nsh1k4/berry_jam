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
## Stage 7: the bed is soft piano (MusicSynth4 piano_bed) in bg_track's place
## (MusicFiles.USE_BG_TRACK false; the file stays in the repo, unloaded), with
## the same dip / ducks / drops / return; footsteps (now +4 dB) never dip it
## and running steps still raise the noticed meter; the menu and the End
## Card have their own piano pieces (no melancholy layer); every track's
## loudness (RMS at its level, through the Music bus) sits in the Stage 6b
## mix's range; tracks start rendering at boot (menu first).
##   godot --path . --script res://tests/playthroughs/music_check.gd

var mm
var bus
var ok := true
var skip_cs: Callable

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
		if mm._files.level > mm._files.bed_db() - 3.5:
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
	for path in [MusicFiles.ENDING_PATH]:
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
	_check("bg_track.wav removed and not used (USE_BG_TRACK false)", not MusicFiles.USE_BG_TRACK and not MusicFiles.bg_exists())
	_check("the piano bed is the bed; ending.wav loaded at start-up", mm._files.piano and mm._files.bg != null and mm._files.ending != null)

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
			present += 1 if mm._files.playing_bg() and mm._files.level > mm._files.bed_db() - 6.0 else 0
		if frame in ["ch1_landing", "ch2_long_hallway", "ch3_margin"]:
			_level(frame, &"piano_bed")
		_check("piano bed under %s (base %s silent: %.0f dB), present %d%% of 3 s" % [frame, mm._playing,
			mm._players[mm._active].volume_db, present * 100 / 30],
			present >= 29 and mm._players[mm._active].volume_db < -60.0)
	_check("piano bed never restarted across room changes", restarts == 0)
	# Stage 7: footsteps (+4 dB: walk -12, run -6) never dip the bed, and
	# running steps still feed the noticed meter.
	await _go("ch2_clock_room")
	var player = current_scene.get_node("World/Player")
	var crawler = get_first_node_in_group(&"crawler")
	player.global_position = crawler.global_position + Vector2(-200, 0)
	await _wait(2.5)
	var notice = current_scene.get_node("NoticeSystem")
	var n0: float = notice.notice
	var lowest := 0.0
	var steps: Array = []
	var heard: Callable = func(sound: StringName, db: float) -> void:
		if sound == &"step":
			steps.append(db)
	bus.sfx_played.connect(heard)
	for i in 6:
		bus.footstep.emit(i % 2 == 0)
		await _wait(0.1)
		lowest = minf(lowest, mm._files.level - mm._files.bed_db())
	bus.sfx_played.disconnect(heard)
	print("footsteps played at %s dB (walk / run); bed moved %.2f dB; notice %.2f -> %.2f" % [str(steps), lowest, n0, notice.notice])
	_check("footsteps at -12 dB walking / -6 dB running (+4 dB, were -16 / -10)", steps.has(-12.0) and steps.has(-6.0))
	_check("footsteps never dip the bed (6 steps, 3 of them running at -6 dB)", lowest > -0.3 and mm._files._dip == 0.0)
	_check("running steps still raise the noticed meter (+0.07 each)", notice.notice >= n0 + 0.2)
	await _go("ch1_landing")
	# A door creak plays OVER it: it keeps going and dips ~3 dB, then eases back.
	await _wait(1.0)
	var p0: float = _pos()
	am.play_door_creak()
	var low := 0.0
	var t1: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 700:
		await process_frame
		low = minf(low, mm._files.level - mm._files.bed_db())
	var still: bool = mm._files.playing_bg() and _pos() > p0
	await _wait(1.0)
	print("door creak: bed dipped %.1f dB, still playing %s, after 1 s %.1f dB" % [low, still, mm._files.level])
	_check("the bed keeps playing under a door creak, dipping ~3 dB", still and low < -2.0 and low > -4.5
		and absf(mm._files.level - mm._files.bed_db()) < 0.6)
	# Stage 6b: big moments only duck it (-6 dB at most) and it recovers
	# within ~1 s; it never stops or restarts.
	for big in ["cutscene", "lunge", "scare"]:
		p0 = _pos()
		var dip := 0.0
		match big:
			"cutscene":
				bus.cutscene_started.disconnect(skip_cs)
				bus.cutscene_started.emit(&"test")
				bus.cutscene_started.connect(skip_cs)
			"lunge": bus.crawler_telegraph.emit()
			"scare": bus.scare.emit(&"test", 1.0)
		var d0: int = Time.get_ticks_msec()
		var hold: int = 1000 if big == "cutscene" else 0
		while Time.get_ticks_msec() - d0 < hold + 900:
			await process_frame
			dip = minf(dip, mm._files.level - mm._files.bed_db())
		if big == "cutscene":
			bus.cutscene_finished.emit(&"test")
		var d1: int = Time.get_ticks_msec()
		while Time.get_ticks_msec() - d1 < 1500 and mm._files.level < mm._files.bed_db() - 1.0:
			await process_frame
		var back: float = (Time.get_ticks_msec() - d1) / 1000.0
		print("%s: bg dipped %.1f dB, back within 1 dB %.2f s after the duck ends, playing through: %s" % [big, dip, back, _pos() > p0])
		_check("the bed ducks at most ~6 dB for a %s and recovers within ~1 s" % big, dip >= -6.6 and dip < -3.0
			and back <= (1.1 if big == "cutscene" else 0.4) and _pos() > p0)
	# The loop point: the piano bed loops by itself (its seam is folded when
	# rendered): it wraps to the start and never goes quiet.
	var length: float = mm._files.bg.get_length()
	mm._files._bg[mm._files._cur].seek(length - 1.0)
	var loops0: int = mm._files.loops
	var quiet := 0
	for i in 40:
		await _wait(0.05)
		quiet += 0 if mm._files.playing_bg() and mm._files._bg[mm._files._cur].volume_db > mm._files.bed_db() - 4.0 else 1
	print("loop: %d -> %d loops, position now %.2f s of %.1f, %d quiet samples" % [loops0, mm._files.loops, _pos(), length, quiet])
	_check("the piano bed loops seamlessly (wraps, never quiet)", mm._files.loops == loops0 + 1 and quiet == 0 and _pos() < 1.5)
	var gs = root.get_node("/root/GameState")
	bus.reveal_started.emit()
	var gone2: float = await _bg_gone(1.0)
	await _wait(2.0)
	_check("the bed is off for the reveal (out after %.2f s)" % gone2, gone2 >= 0.0 and gone2 < 0.45 and mm._files.level < -60.0)
	gs.twist_revealed = true
	await _go("ch3_returning_room")
	await _wait(4.0)
	_check("the bed is off and stopped in the return phase (%s)" % mm._playing, not mm._files.playing_bg() and mm._playing == &"return")
	_level("return phase", &"return")

## Stage 6b: peak of the music (bg_track's 0 dBFS peak at its level, or the
## menu track's real samples), a running footstep, the steal sound and a scare
## sting all at once, at their real gains, with BOTH sliders at maximum
## (Master 1.0, Music 1.0): worst case, every peak lined up.
func _clip() -> void:
	var am = root.get_node("/root/AudioManager")
	var sfx := {&"step": -6.0, &"steal": -7.0, &"scare_hit": 0.0, &"shriek": 0.0}
	var sum := 0.0
	var parts: Array = []
	for id in sfx:
		var data: PackedByteArray = am._streams[id].data
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		var p: float = peak / 32767.0 * db_to_linear(sfx[id])
		parts.append("%s %.2f" % [id, p])
		sum += p
	var scare_duck: float = db_to_linear(-6.0)
	var bed_peak: float = _peak(&"piano_bed")
	var bg: float = bed_peak * db_to_linear(mm._files.bed_db()) * scare_duck
	var bg_free: float = bed_peak * db_to_linear(mm._files.bed_db())
	print("peaks at max sliders: %s; piano bed %.2f (ducked for the scare) / %.2f (not)" % [", ".join(parts), bg, bg_free])
	print("worst-case sum (all peaks aligned): %.2f with the scare duck (%.1f dBFS), %.2f without (%.1f dBFS)" % [sum + bg,
		linear_to_db(sum + bg), sum + bg_free, linear_to_db(sum + bg_free)])
	# The real mix: the samples summed as they play (all starting together),
	# with one sting (a scare plays one), at max sliders and at the defaults.
	for sting in [&"scare_hit", &"shriek"]:
		var bufs: Array = []
		for id in [&"step", &"steal", sting]:
			var raw: PackedByteArray = am._streams[id].data
			var f := PackedFloat32Array()
			f.resize(raw.size() / 2)
			for i in f.size():
				f[i] = raw.decode_s16(i * 2) / 32767.0 * db_to_linear(sfx[id])
			bufs.append(f)
		var mix_peak := 0.0
		for i in (bufs[2] as PackedFloat32Array).size():
			var v: float = 0.0
			for f in bufs:
				v += (f as PackedFloat32Array)[i] if i < (f as PackedFloat32Array).size() else 0.0
			mix_peak = maxf(mix_peak, absf(v) + bg)
		var master_default: float = 0.7
		print("real mix with %s: peak %.2f (%.1f dBFS) at max sliders; %.2f (%.1f dBFS) at the default Master (0.7) and Music (0.85)" % [sting,
			mix_peak, linear_to_db(mix_peak), mix_peak * master_default, linear_to_db(mix_peak * master_default)])
		_check("music + footstep + steal + %s under 0 dBFS at the default sliders" % sting, mix_peak * master_default < 1.0)
	print("music's share of the worst case: %.2f of %.2f (the stings alone reach %.2f)" % [bg, sum + bg, sum])
	# Each piano piece at its level, full sliders, real samples.
	for track in [&"menu", &"piano_end"]:
		var p2: float = _peak(track) * db_to_linear(mm.BASE_DB)
		print("%s at max sliders: peak %.2f (%.1f dBFS)" % [track, p2, linear_to_db(p2)])
		_check("the loudest music slider still leaves headroom (%s)" % track, p2 < 0.9)


## A rendered track's peak / RMS (the renderer's own result, 16-bit).
func _samples(track: StringName) -> PackedFloat32Array:
	var data: PackedByteArray = (mm._renderer.streams[track] as AudioStreamWAV).data
	var f := PackedFloat32Array()
	f.resize(data.size() / 2)
	for i in f.size():
		f[i] = data.decode_s16(i * 2) / 32767.0
	return f

func _peak(track: StringName) -> float:
	var p := 0.0
	for v in _samples(track):
		p = maxf(p, absf(v))
	return p

func _rms_db(track: StringName) -> float:
	var f: PackedFloat32Array = _samples(track)
	var sum := 0.0
	for v in f:
		sum += v * v
	return linear_to_db(sqrt(sum / f.size()))


## Stage 7: the music's loudness where it plays: the track's RMS at its
## player level through the Music bus. Stage 6b's bed (bg_track, RMS ~-15
## dBFS at -11 dB, bus -1.4 dB) sat at ~-27.4 dBFS: every track should land
## within a few dB of that.
const MIX_DB: float = -27.4

func _level(where: String, track: StringName) -> void:
	var bus_db: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))
	var player_db: float = mm._files.level if mm._files.playing_bg() else mm._players[mm._active].volume_db
	var now: float = player_db + bus_db + _rms_db(track)
	print("loudness %-16s %-10s %6.1f dBFS RMS (player %.1f, bus %.1f, track RMS %.1f); Stage 6b bed %.1f" % [where, track, now,
		player_db, bus_db, _rms_db(track), MIX_DB])
	_check("%s (%s) in line with the mix (within 4.5 dB of the 6b bed)" % [where, track], absf(now - MIX_DB) <= 4.5)


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
	# The epilogue ends: the End Card's piano piece crossfades in.
	bus.epilogue_finished.emit()
	await _wait(3.0)
	_check("End Card: piano_end playing (%s at %.1f dB)" % [mm._playing, mm._players[mm._active].volume_db], mm._playing == &"piano_end"
		and absf(mm._players[mm._active].volume_db - mm.BASE_DB) < 1.0 and mm._players[1 - mm._active].volume_db < -40.0)
	_level("end card", &"piano_end")
	gs.is_playing = false
	bus.returned_to_menu.emit()
	await _wait(0.3)
	_check("Back to Menu stops the files", not f._end.playing and not f.playing_bg() and f.end_state == MusicFiles.End.IDLE)
	await _wait(3.0)
	_check("Back to Menu: the menu's piano crossfades back (%s)" % mm._playing, mm._playing == &"menu"
		and absf(mm._players[mm._active].volume_db - mm.BASE_DB) < 1.0 and not mm.has_node("menu_sad"))
	var index: int = AudioServer.get_bus_index(&"Music")
	mm.set_music_muted(true)
	var muted: bool = AudioServer.is_bus_mute(index)
	mm.set_music_muted(false)
	mm._settings._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var focus: bool = AudioServer.is_bus_mute(index)
	mm._settings._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_check("Music bus (menu, bed, ending, End Card) mutes for mute and focus loss", muted and focus and not AudioServer.is_bus_mute(index))
	# The menu piece leaves space: gaps of near silence between phrases.
	var m: PackedFloat32Array = _samples(&"menu")
	var gaps := 0
	var run := 0
	for i in m.size():
		run = run + 1 if absf(m[i]) < 0.01 else 0
		gaps += 1 if run == int(0.5 * 22050) else 0
	print("menu piano: quiet stretches of 0.5 s+: %d" % gaps)

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
	skip_cs = func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish")
	bus.cutscene_started.connect(skip_cs)
	await _wait(0.3)
	var t0: int = Time.get_ticks_msec()
	var menu_at_click: bool = mm.is_ready(&"menu")
	bus.game_started.emit()
	var worst: int = 0
	var first_menu: int = 0 if menu_at_click else -1
	var expected: int = mm.PRIORITY.size() - (1 if MusicFiles.bg_exists() else 0)
	while mm._renderer.streams.size() < expected:
		var f0: int = Time.get_ticks_usec()
		await process_frame
		worst = maxi(worst, Time.get_ticks_usec() - f0)
		if first_menu < 0 and mm.is_ready(&"menu"):
			first_menu = Time.get_ticks_msec() - t0
		if Time.get_ticks_msec() - t0 > 120000:
			break
	print("menu ready after %d ms, all tracks after %d ms, slowest frame %.1f ms" % [first_menu, Time.get_ticks_msec() - t0, worst / 1000.0])
	_check("all tracks rendered (%d: the render list; ch1-3 / old bed / menu_sad never)" % expected, mm._renderer.streams.size() == expected)
	print("menu ready at the click (rendering starts at boot): %s" % menu_at_click)
	for track in mm.PRIORITY:
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
	_check("old settings were moved up to the new default once", is_equal_approx(mm.music_volume, 0.85) or mm.music_volume > 0.85)
	await _wait(2.0)
	_level("menu", &"menu")
	await _files_info()
	_clip()
	await _sfx()
	await _bg()
	await _ending()
	print("MUSIC TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
