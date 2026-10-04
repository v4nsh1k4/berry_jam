extends SceneTree
## Cutscene test (dev, not exported). Plays every cutscene, screenshots each
## beat, then checks the triggers, skipping, "seen" saving and that Restart
## Chapter never replays one. Run from game_jam/:
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

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_shot_dir() + "/" + name)

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _start() -> void:
	bus.game_started.emit()
	bus.menu_new_game.emit()
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
	# 1. Every cutscene, every beat, screenshotted mid-beat.
	for id in ["c1_first_steal", "c2_torch", "c3_flashback", "c4_descent", "c5_before_final", "c6_repair"]:
		cs.play_id(StringName(id))
		await _wait(0.1)
		var data = cs._current
		for b in data.beats.size():
			await _wait(data.beats[b].duration * 0.75)
			await _shot("cs_%s_%d.png" % [id, b])
			await _wait(data.beats[b].duration * 0.25)
		await _wait(0.3)
		print(id, " finished playing=", cs.is_playing, " paused=", paused)
		ok = ok and not cs.is_playing and not paused
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
