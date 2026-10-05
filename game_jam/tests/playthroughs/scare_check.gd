extends SceneTree
## Jumpscare test (dev, not exported): reads the clock to fire the major
## scare, screenshots it, checks the Crawler is hunting close by and that the
## scare never repeats (also not after Restart Chapter); then the Margin's
## minor scare. Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/scare_check.gd

var gs
var fm
var bus
var main
var player
var ok := true
var scares: Array = []

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

func _check(label: String, cond: bool) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	ok = ok and cond

func _go(frame: String) -> void:
	var ch = load("res://scripts/systems/debug_jump.gd").prepare(frame)
	gs.current_chapter = ch
	gs.is_playing = true
	gs.chapter_start = gs.to_dict()
	fm.go_to(StringName(frame))
	await _wait(1.2)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	bus.scare.connect(func(kind, _i): scares.append(kind))
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	bus.menu_new_game.emit()
	main.get_node("MenuLayer/ControlsCard").call("_accept")
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	main.get_node("MenuLayer/MainMenu").hide()
	bus.intro_finished.emit()
	main.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.4)
	player = main.get_node("World/Player")
	var ov = main.get_node("FXLayer/JumpscareOverlay")
	var rooms := {&"scare_hallway": ["ch2_long_hallway", &"hall_panel_open"], &"scare_gallery": ["ch2_gallery", &"gallery_lever"],
		&"scare_passage": ["ch2_servants_passage", &"survived_passage"], &"scare_clock": ["ch2_clock_room", &"clock_read"],
		&"scare_hand": ["ch3_gallery_words", &"spread_lens"]}
	for id in rooms:
		await _go(rooms[id][0])
		ov._since_last = 999.0
		player.global_position = Vector2(48 + 420, 32 + (200 if id == &"scare_hand" else 466))
		var before: int = scares.size()
		gs.set_flag(rooms[id][1])
		var waited := 0.0
		while scares.size() == before and waited < 6.0:
			await _wait(0.05)
			waited += 0.05
		await _wait(0.12)
		await _shot("sc_%s.png" % id)
		_check("%s fired after its trigger (%.1fs)" % [id, waited], scares.size() == before + 1 and scares[-1] == id)
		await _wait(0.6)
	# The clock's gameplay half: the Crawler appears and hunts.
	await _go("ch2_clock_room")
	ov.play(&"scare_clock")
	await _wait(0.5)
	var crawler = get_first_node_in_group(&"crawler")
	_check("clock scare: the Crawler is close and hunting", crawler.is_hunting() and absf(crawler.global_position.x - player.global_position.x) < 420.0)
	# Spacing, chases and replays.
	gs.seen.clear()
	await _go("ch2_gallery")
	var n: int = scares.size()
	ov._since_last = 10.0
	gs.set_flag(&"gallery_lever")
	await _wait(3.0)
	_check("a scare inside 60 s of the last one waits", scares.size() == n)
	ov._since_last = 999.0
	var shadow = get_first_node_in_group(&"crawler")
	shadow.wake_to(true, 3.0)
	await _wait(1.5)
	_check("...and still waits while the Crawler hunts", scares.size() == n)
	shadow._set_state(0)
	await _wait(1.0)
	_check("...then fires once it is fair", scares.size() == n + 1)
	bus.restart_chapter_requested.emit()
	await _wait(2.0)
	gs.set_flag(&"gallery_lever")
	await _wait(3.0)
	_check("never replayed after a restart", scares.size() == n + 1 and gs.seen.has(&"scare_gallery"))
	print("SCARE TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
