extends SceneTree
## Cutscene test (dev, not exported). Plays every cutscene, screenshots each
## beat, then checks the triggers, skipping, "seen" saving and that Restart
## Chapter never replays one. Run from the repo root:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/cutscenes.gd

var gs
var fm
var bus
var cs
var main

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

## A hidden window (another Space, a full-screen app) is never drawn, so
## frame_post_draw never comes: then force a draw for the shot.
func _shot(name: String) -> void:
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func() -> void: drawn[0] = true, CONNECT_ONE_SHOT)
	for i in 20:
		if drawn[0]:
			break
		await process_frame
	if not drawn[0]:
		RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(_shot_dir() + "/" + name)

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _start() -> void:
	bus.game_started.emit()
	bus.menu_new_game.emit()
	main.get_node("MenuLayer/ControlsCard").call("_accept")
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	main.get_node("MenuLayer/MainMenu").hide()
	bus.intro_finished.emit()
	main.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.5)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	cs = root.get_node("/root/CutsceneSystem")
	await _wait(0.3)
	main = current_scene
	await _start()
	var ok := true
	print("cutscenes loaded: ", cs.ids())
	ok = ok and cs.ids().size() == 6
	# 1. Every cutscene, every beat, screenshotted mid-beat (the first-person
	# ones three times per beat). Lengths vs. Stage 4D (Step 0 of Stage 5),
	# and the slowest frame while they play.
	var before := {"c1_first_steal": [2, 4.76], "c2_torch": [2, 4.93], "c3_flashback": [2, 5.27], "c4_descent": [2, 5.27],
		"c5_before_final": [2, 5.27], "c6_repair": [3, 7.14]}
	var total := 0.0
	var only: String = OS.get_environment("ONLY")
	for id in ["c1_first_steal", "c2_torch", "c3_flashback", "c4_descent", "c5_before_final", "c6_repair"]:
		if only != "" and not only.split(",").has(id):
			continue
		cs.play_id(StringName(id))
		await process_frame
		var data = cs._current
		var secs := 0.0
		for b in data.beats:
			secs += b.duration
		total += secs
		print("%-16s beats %d (was %d)  %.2f s (was %.2f)" % [id, data.beats.size(), before[id][0], secs, before[id][1]])
		# Stage 6b: same beats, each long enough to read its caption (0.3 s
		# start, 0.06 s a character / 2.5 s at least, a 0.6 s hold, +0.5 s turn).
		ok = ok and data.beats.size() == before[id][0] and secs >= before[id][1] - 0.001
		for b in data.beats:
			var need: float = 0.3 + maxf(2.5, String(b.caption).length() * 0.06) + 0.6 + (0.5 if b.page_turn else 0.0)
			if b.duration + 0.011 < need:
				print("   FAIL beat \"%s\" %.2f s < reading time %.2f s" % [b.caption, b.duration, need])
				ok = false
		var pov: bool = String(data.beats[0].draws[0]).begins_with("pov_") or id == "c1_first_steal"
		var worst := 0
		var times: Array = []
		for b in data.beats.size():
			while cs._beat >= 0 and cs._beat < b:
				await process_frame
			var marks: Array = [0.25, 0.6, 0.92] if pov else [0.75]
			for m in marks.size():
				while cs._beat == b and cs._beat_t < data.beats[b].duration * marks[m]:
					var f0: int = Time.get_ticks_usec()
					await process_frame
					worst = maxi(worst, Time.get_ticks_usec() - f0)
					times.append(Time.get_ticks_usec() - f0)
				await _shot("cs_%s_%d%s.png" % [id, b, "abc"[m] if pov else ""])
		while cs.is_playing:
			await process_frame
		times.sort()
		print("   slowest frame %.1f ms, 95th percentile %.1f ms, median %.1f ms (%d frames)" % [worst / 1000.0,
			times[int(times.size() * 0.95)] / 1000.0, times[times.size() / 2] / 1000.0, times.size()])
		await _wait(0.3)
		print(id, " finished playing=", cs.is_playing, " paused=", paused)
		ok = ok and not cs.is_playing and not paused
	print("all cutscenes: %.2f s (Stage 4D-6: 32.64 s)" % total)
	# 2. Trigger: the first steal plays C1 once (after a short beat).
	gs.reset()
	gs.is_playing = true
	gs.add_bubble(load("res://data/bubbles/arthur_open.tres"))
	await _wait(1.2)
	print("first steal -> playing=", cs.is_playing, " id=", cs._current.id if cs._current else "-", " paused=", paused)
	ok = ok and cs.is_playing and paused
	# Skip is ignored in the grace window, then works.
	cs._try_skip()
	await _wait(0.7)
	cs._try_skip()
	await _wait(0.1)
	print("after skip playing=", cs.is_playing, " seen=", gs.seen)
	ok = ok and not cs.is_playing and gs.seen.has(&"c1_first_steal")
	gs.add_bubble(load("res://data/bubbles/arthur_push.tres"))
	await _wait(1.2)
	print("second steal -> playing=", cs.is_playing)
	ok = ok and not cs.is_playing
	# 3. Frame trigger, then save/load and Restart Chapter keep "seen".
	fm.go_to(&"ch2_pantry")
	await _wait(2.5)
	print("pantry -> playing=", cs.is_playing, " id=", cs._current.id if cs._current else "-")
	ok = ok and cs.is_playing
	cs._finish()
	await _wait(0.2)
	var snap: Dictionary = gs.to_dict()
	gs.seen.clear()
	gs.from_dict(snap)
	print("after save/load seen=", gs.seen)
	ok = ok and gs.seen.has(&"c3_flashback") and gs.seen.has(&"c1_first_steal")
	bus.restart_chapter_requested.emit()
	await _wait(2.5)
	print("after restart seen=", gs.seen, " playing=", cs.is_playing)
	ok = ok and gs.seen.has(&"c3_flashback")
	print("CUTSCENE TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
