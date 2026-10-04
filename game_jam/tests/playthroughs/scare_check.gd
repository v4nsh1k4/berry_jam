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
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	main.get_node("MenuLayer/MainMenu").hide()
	bus.intro_finished.emit()
	main.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.4)
	player = main.get_node("World/Player")
	await _go("ch2_clock_room")
	player.global_position = Vector2(48 + 600, 32 + 466)
	root.warp_mouse(Vector2(48 + 600, 32 + 140))
	root.get_node("/root/LightingSystem").set_light(true)
	while scares.is_empty():
		await process_frame
	await _wait(0.1)
	await _shot("sc_face.png")
	root.get_node("/root/LightingSystem").set_light(false)
	await _wait(0.6)
	await _shot("sc_after.png")
	var crawler = get_first_node_in_group(&"crawler")
	var gap: float = absf(crawler.global_position.x - player.global_position.x)
	_check("major scare fired once (%s)" % [scares], scares == [&"scare_clock"])
	_check("crawler close and hunting (gap=%d, state=%d)" % [gap, crawler.state], gap < 420.0 and crawler.is_hunting())
	_check("clock read and door unbolted", gs.has_flag(&"clock_read"))
	bus.restart_chapter_requested.emit()
	await _wait(2.0)
	_check("seen kept after restart", gs.seen.has(&"scare_clock"))
	# Margin: the minor scare.
	await _go("ch3_margin")
	await _wait(0.75)
	await _shot("sc_hand.png")
	await _wait(1.0)
	_check("minor scare fired (%s)" % [scares], scares.has(&"scare_margin"))
	print("SCARE TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
