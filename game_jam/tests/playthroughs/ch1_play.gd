extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch1_play.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.

var gs
var player
var fm

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

func _at(x: float) -> void:
	player.global_position = Vector2(48 + x, 32 + 466)
	await _wait(0.15)

func _steal(x: float) -> void:
	await _at(x)
	Input.action_press("interact")
	await _wait(0.7)
	Input.action_release("interact")
	await _wait(0.4)

func _walk(dir: String, sec: float) -> void:
	Input.action_press(dir)
	await _wait(sec)
	Input.action_release(dir)
	await _wait(1.1)

func _say(slot: int) -> void:
	gs.selected_index = -1
	gs.select(slot)
	await _tap("interact")
	await _wait(0.3)

func _log(msg: String) -> void:
	print("[", fm.current_frame.data.id if fm.current_frame else "-", "] ", msg)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	await _wait(0.3)
	root.get_node("/root/EventBus").cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	root.get_node("/root/EventBus").game_started.emit()
	await _wait(0.3)
	await _shot("00_menu.png")
	root.get_node("/root/EventBus").menu_new_game.emit()
	# New Game opens with the intro cinematic: skip it like a click would.
	current_scene.get_node("MenuLayer/IntroCinematic").call("_finish")
	current_scene.get_node("MenuLayer/MainMenu").hide()
	await _wait(0.8)
	await _shot("01_intro.png")
	for i in 3:
		await _tap("ui_accept")
	await _wait(0.5)
	player = current_scene.get_node("World/Player")
	await _shot("02_awakening.png")
	await _at(640)
	await _tap("interact")
	await _wait(0.2)
	await _shot("03_mirror.png")
	await _at(1000)
	await _walk("move_right", 0.6)
	_log("arrived")
	await _at(560)
	await _wait(1.2)
	await _shot("04_bedchamber_window.png")
	await _at(370)
	await _tap("interact")
	_log("drawer without word: open=" + str(gs.has_flag(&"drawer_open")))
	await _at(1000)
	await _walk("move_right", 0.6)
	_log("arrived")
	await _at(560)
	await _shot("05_arthur.png")
	await _steal(365.0)
	await _steal(255.0)
	await _steal(865.0)
	_log("inventory=" + str(gs.inventory.map(func(b): return b.text)))
	await _at(200)
	await _at(560)
	await _wait(0.3)
	await _shot("06_arthur_broken.png")
	await _at(200)
	await _say(2)
	await _wait(0.3)
	await _shot("07_help_hint.png")
	await _at(1075)
	await _say(1)
	_log("door with PUSH: " + str(gs.has_flag(&"study_door_open")))
	await _say(0)
	_log("door with OPEN: " + str(gs.has_flag(&"study_door_open")))
	await _wait(0.5)
	await _walk("move_right", 0.6)
	_log("arrived")
	await _at(420)
	await _walk("move_right", 0.35)
	await _shot("08_ink_hand.png")
	await _wait(2.0)
	await _steal(830.0)
	_log("inventory=" + str(gs.inventory.map(func(b): return b.text)) + " damage=" + str(gs.comic_damage))
	await _shot("09_portrait.png")
	await _at(1000)
	await _walk("move_right", 0.6)
	_log("arrived")
	await _at(450)
	await _say(3)
	_log("remember before push: cabinet_pushed=" + str(gs.has_flag(&"cabinet_pushed")))
	await _at(780)
	await _say(1)
	await _wait(0.6)
	_log("push: cabinet_pushed=" + str(gs.has_flag(&"cabinet_pushed")))
	await _say(3)
	await _wait(0.8)
	await _shot("10_memory.png")
	await _at(1075)
	await _tap("interact")
	await _wait(0.2)
	# Dials start on "house" (5 of 7 symbols): eye = up 3, moon = up 2, key = up 4 (the last one below).
	for a in ["move_up", "move_up", "move_up", "move_right", "move_up", "move_up", "move_right", "move_up", "move_up", "move_up"]:
		await _tap(a)
	await _shot("11_lock.png")
	await _tap("move_up")
	await _wait(1.2)
	_log("lock open=" + str(gs.has_flag(&"study_lock_open")) + " modal=" + str(gs.modal_open))
	await _shot("12_lock_open.png")
	await _walk("move_right", 0.6)
	_log("arrived")
	await _at(1000)
	await _walk("move_right", 0.6)
	_log("exit blocked without torch? frame=" + str(fm.current_frame.data.id))
	await _at(595)
	await _tap("interact")
	_log("flashlight=" + str(gs.has_flag(&"has_flashlight")))
	root.warp_mouse(Vector2(900, 300))
	await _tap("toggle_light")
	await _wait(0.6)
	await _shot("13_flashlight.png")
	await _tap("pause")
	await _wait(0.2)
	await _shot("14_pause.png")
	await _tap("pause")
	await _at(1000)
	await _walk("move_right", 0.6)
	await _wait(2.0)
	_log("end")
	await _shot("15_end_card.png")
	print("save=", root.get_node("/root/GameState").to_dict())
	quit()
