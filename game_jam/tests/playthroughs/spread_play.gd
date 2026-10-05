extends SceneTree
## Page spread playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/spread_play.gd

var gs
var fm
var bus
var main
var player
var ok := true

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

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(0.06)
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _wait(0.12)

func _at(p: Vector2) -> void:
	player.global_position = Vector2(48, 32) + p
	await _wait(0.15)

func _aim(p: Vector2) -> void:
	root.warp_mouse(p + Vector2(48, 32))

func _hold(action: String, sec: float) -> void:
	Input.action_press(action)
	await _wait(sec)
	Input.action_release(action)
	await _wait(0.6)

func _select(text: String) -> void:
	for i in gs.inventory.size():
		if gs.inventory[i].text == text:
			gs.select(i, false)
			return

func _spread():
	return fm.current_frame.get_node("Props").get_child(0)

func _panel() -> String:
	return String(_spread().current.id)

func _check(label: String, cond: bool) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	ok = ok and cond

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
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
	var ch = load("res://scripts/systems/debug_jump.gd").prepare("ch3_gallery_words")
	gs.current_chapter = ch
	gs.is_playing = true
	fm.go_to(&"ch3_gallery_words")
	await _wait(1.5)
	await _shot("sp_00_page.png")
	_check("starts in A", _panel() == "A")
	# A: jump over the tear, walk off the right edge into B.
	await _at(Vector2(270, 200))
	Input.action_press("move_right")
	await _wait(0.05)
	await _tap("jump")
	await _wait(1.6)
	Input.action_release("move_right")
	await _wait(0.8)
	_check("jumped the tear and hopped to B (now %s)" % _panel(), _panel() == "B")
	# B: light the lens (it shows the lever in C), then the pool.
	await _at(Vector2(700, 206))
	_aim(Vector2(725, 69))
	await _tap("toggle_light")
	await _wait(1.6)
	_check("lens lit", gs.has_flag(&"spread_lens"))
	await _shot("sp_01_lens.png")
	_aim(Vector2(1045, 197))
	await _wait(2.0)
	await _tap("toggle_light")
	_check("pool cleared", gs.has_flag(&"spread_pool"))
	await _wait(0.5)
	await _hold("move_right", 1.6)
	await _wait(0.8)
	_check("dropped through the pool to D (now %s)" % _panel(), _panel() == "D")
	await _at(Vector2(700, 458))
	await _hold("move_left", 0.8)
	await _wait(0.6)
	_check("D left edge -> C (now %s)" % _panel(), _panel() == "C")
	# C: the gutter tear is a fall without a bridge.
	var spread = _spread()
	await _hold("move_left", 0.7)
	await _wait(1.2)
	var x_after: float = player.global_position.x - 48
	_check("fell into the gutter and came back at the entry (x=%d)" % x_after, x_after > 480)
	await _shot("sp_02_after_fall.png")
	# The lever (shown by the lens).
	await _at(Vector2(495, 456))
	await _tap("interact")
	await _wait(0.3)
	_check("lever pulled", gs.has_flag(&"spread_lever"))
	# A: PUSH the crate down into C's tear.
	await _at(Vector2(110, 456))
	await _tap("jump")
	await _wait(1.0)
	_check("jumped up C -> A (now %s)" % _panel(), _panel() == "A")
	await _at(Vector2(470, 200))
	_select("PUSH")
	await _tap("interact")
	await _wait(0.8)
	_check("crate pushed", gs.has_flag(&"spread_crate"))
	await _at(Vector2(330, 200))
	await _wait(1.0)
	_check("walked into A's tear -> C (now %s)" % _panel(), _panel() == "C")
	await _at(Vector2(240, 456))
	await _hold("move_right", 1.2)
	_check("crossed C on the crate (now %s)" % _panel(), _panel() == "C" or _panel() == "D")
	await _shot("sp_03_crate_bridge.png")
	await _hold("move_right", 1.4)
	await _wait(0.6)
	_check("into D (now %s)" % _panel(), _panel() == "D")
	# Gutter fingers: torch on too long.
	await _at(Vector2(800, 458))
	_aim(Vector2(1000, 370))
	await _tap("toggle_light")
	await _wait(4.4)
	await _shot("sp_04_fingers.png")
	await _wait(0.8)
	await _tap("toggle_light")
	var fx: float = player.global_position.x - 48
	_check("fingers knocked the player back (x=%d)" % fx, absf(fx - 640) < 30)
	await _at(Vector2(1000, 458))
	_select("OPEN")
	await _tap("interact")
	await _wait(0.5)
	_check("door opened", gs.has_flag(&"spread_door"))
	await _hold("move_right", 1.0)
	await _wait(2.0)
	_check("left for the Margin (frame %s)" % gs.current_frame_id, gs.current_frame_id == &"ch3_margin")
	print("SPREAD TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
