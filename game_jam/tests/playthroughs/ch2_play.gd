extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch2_play.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.

var gs
var fm
var bus
var main
var player
const STATES := ["DORMANT", "PATROL", "STALKING", "HUNTING", "TELEGRAPH", "LUNGE", "SEARCHING", "RETREATING"]

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

func _aim(panel: Vector2) -> void:
	root.warp_mouse(panel + Vector2(48, 32))

func _steal_under(x: float) -> void:
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

func _select_word(text: String) -> void:
	for i in gs.inventory.size():
		if gs.inventory[i].text == text and gs.inventory[i].stolen_from != &"arthur":
			gs.select(i, false)
			return
	for i in gs.inventory.size():
		if gs.inventory[i].text == text:
			gs.select(i, false)
			return

func _crawler():
	return get_first_node_in_group(&"crawler")

func _cstate() -> String:
	var c = _crawler()
	return STATES[c.state] if c else "none"

func _log(msg: String) -> void:
	print("[", fm.current_frame.data.id if fm.current_frame else "-", "] ", msg)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	bus.menu_new_game.emit()
	# New Game opens with the intro cinematic: skip it like a click would.
	current_scene.get_node("MenuLayer/IntroCinematic").call("_finish")
	main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	bus.intro_finished.emit()
	main.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.4)
	player = main.get_node("World/Player")
	# Carry over what Chapter 1 guarantees: OPEN, PUSH, REMEMBER and the torch.
	for w in ["arthur_open", "arthur_push", "portrait_remember"]:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	gs.set_flag(&"has_flashlight")
	# Chapter 1 -> 2 handover from the last Chapter 1 panel.
	fm.go_to(&"ch1_end")
	await _wait(2.0)
	_log("intro visible=" + str(main.get_node("MenuLayer/IntroSequence").visible))
	await _shot("00_ch2_intro.png")
	for i in 3:
		await _tap("ui_accept")
	await _wait(0.6)
	_log("chapter=" + str(gs.current_chapter.id) + " jitter=" + str(InkDraw.jitter_scale))
	# 1. Long hallway: reveal writing and latch.
	await _at(250)
	_aim(Vector2(560, 150))
	await _tap("toggle_light")
	await _wait(0.8)
	await _shot("01_writing.png")
	await _at(900)
	_aim(Vector2(980, 330))
	await _wait(0.8)
	_select_word("OPEN")
	await _wait(0.2)
	await _shot("02_latch.png")
	await _tap("interact")
	await _wait(0.4)
	_log("latch opened=" + str(gs.has_flag(&"hall_panel_open")))
	await _tap("toggle_light")
	await _at(1000)
	await _walk("move_right", 0.7)
	_log("arrived")
	# 2. Gallery: light near the sleeper wakes it.
	await _at(560)
	_aim(Vector2(1000, 450))
	await _tap("toggle_light")
	await _wait(1.6)
	_log("after 1.6s light: crawler=" + _cstate())
	await _wait(1.2)
	await _shot("03_gallery_stalking.png")
	await _tap("toggle_light")
	await _wait(9.0)
	_log("after 9s dark & still: crawler=" + _cstate() + " caught? frame=" + str(fm.current_frame.data.id))
	await _at(1000)
	await _walk("move_right", 0.7)
	_log("arrived")
	# 3. Passage: hide in the wardrobe.
	await _wait(2.3)
	await _at(390)
	await _tap("interact")
	_log("concealed=" + str(player.is_concealed()))
	await _wait(2.5)
	_log("crawler=" + _cstate())
	await _shot("04_hiding.png")
	await _wait(9.5)
	_log("crawler=" + _cstate() + " survived=" + str(gs.has_flag(&"survived_passage")))
	await _tap("interact")
	await _at(1000)
	await _walk("move_right", 0.7)
	_log("arrived")
	# 4. Pantry: steal Mrs. Vane's words.
	await _steal_under(370)
	await _wait(0.5)
	await _shot("05_fingers.png")
	await _steal_under(268)
	await _steal_under(760)
	_log("inventory=" + str(gs.inventory.map(func(b): return b.text)) + " damage=" + str(gs.comic_damage))
	await _at(560)
	await _wait(0.3)
	await _shot("06_vane_broken.png")
	await _at(1000)
	await _walk("move_right", 0.7)
	_log("arrived crawler=" + _cstate())
	# 5. Clock room: HUSH, then read the clock.
	await _at(420)
	_select_word("HUSH")
	await _tap("interact")
	_aim(Vector2(600, 140))
	await _tap("toggle_light")
	await _wait(1.5)
	await _shot("07_clock.png")
	await _tap("toggle_light")
	_log("clock_read=" + str(gs.has_flag(&"clock_read")) + " crawler=" + _cstate())
	await _wait(0.6)
	_select_word("WAIT")
	await _tap("interact")
	_log("WAIT froze crawler: frozen=" + str(_crawler()._frozen > 0.0))
	await _at(1000)
	await _walk("move_right", 0.7)
	_log("arrived")
	# 6. Cellar: REMEMBER, dials, OPEN, run.
	await _at(475)
	_select_word("REMEMBER")
	await _tap("interact")
	await _wait(0.8)
	await _shot("08_cellar_memory.png")
	await _at(860)
	await _tap("interact")
	await _wait(0.2)
	for a in ["move_down", "move_right", "move_down", "move_down"]:
		await _tap(a)
	await _wait(1.0)
	_log("dials set=" + str(gs.has_flag(&"cellar_dials_set")))
	await _at(1075)
	_select_word("OPEN")
	await _tap("interact")
	await _wait(1.25)
	await _shot("09_chase.png")
	_log("chase crawler=" + _cstate())
	await _wait(2.5)
	_log("end")
	await _wait(1.5)
	await _shot("10_end_card.png")
	print("damage_visual=", gs.damage_visual())
	quit()
