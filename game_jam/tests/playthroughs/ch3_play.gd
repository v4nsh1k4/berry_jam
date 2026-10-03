extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_play.gd
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

func _at(x: float) -> void:
	player.global_position = Vector2(48 + x, 32 + 466)
	await _wait(0.15)

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

func _select(id: String) -> void:
	for i in gs.inventory.size():
		if String(gs.inventory[i].id) == id:
			gs.select(i, false)

func _give(id: String, x: float) -> void:
	_select(id)
	await _at(x)
	Input.action_press("interact")
	await _wait(0.85)
	Input.action_release("interact")
	await _wait(0.4)
	_log("give " + id + " -> returned=" + str(gs.is_bubble_returned(StringName(id))) + " damage=" + str(gs.comic_damage))

func _walk_right() -> void:
	await _at(1000)
	Input.action_press("move_right")
	await _wait(0.7)
	Input.action_release("move_right")
	await _wait(1.1)

func _log(msg: String) -> void:
	print("[", fm.current_frame.data.id if fm.current_frame else "-", "] ", msg)

func _shadow():
	return get_first_node_in_group(&"crawler")

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")
	gs.reset()
	for w in ["arthur_open", "arthur_push", "arthur_help", "portrait_remember", "vane_hide", "vane_hush", "vane_wait"]:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	gs.set_flag(&"has_flashlight")
	# Chapter 2 -> 3 handover.
	main._start_chapter(load("res://data/chapters/ch2.tres"))
	await _wait(0.3)
	fm.go_to(&"ch2_end")
	await _wait(2.0)
	_log("ch3 intro pending=" + str(main._pending.id if main._pending else "none"))
	for i in 3:
		await _tap("ui_accept")
	await _wait(0.6)
	_log("chapter=" + str(gs.current_chapter.id) + " can_return=" + str(gs.can_return()) + " damage=" + str(gs.comic_damage) + " visual=" + str(gs.damage_visual()))
	await _at(300)
	await _shot("00_torn_page.png")
	# Wrong word first: nothing breaks.
	_select("vane_hush")
	await _at(280)
	Input.action_press("interact")
	await _wait(0.85)
	Input.action_release("interact")
	await _wait(0.3)
	_log("wrong word: vane_hush returned=" + str(gs.is_bubble_returned(&"vane_hush")) + " words=" + str(gs.inventory.size()))
	await _give("vane_hide", 280)
	await _shot("01_thank_you.png")
	await _give("vane_hush", 178)
	await _give("vane_wait", 670)
	await _wait(1.0)
	await _shot("02_vane_whole.png")
	await _walk_right()
	_log("arrived drawer whole flag=" + str(gs.has_flag(&"whole_drawer")))
	await _give("arthur_open", 365)
	await _give("arthur_push", 255)
	await _give("arthur_help", 865)
	await _at(560)
	await _wait(0.8)
	await _shot("03_arthur_whole.png")
	# Save / load keeps returns.
	var snap: Dictionary = gs.to_dict()
	gs.from_dict(JSON.parse_string(JSON.stringify(snap)))
	_log("after save/load: returned=" + str(gs.returned_bubble_ids.size()) + " words=" + str(gs.inventory.map(func(b): return b.text)))
	await _walk_right()
	await _wait(0.5)
	_log("gallery open before portrait word=" + str(gs.has_flag(&"gallery_open")))
	await _shot("04_gallery_one_dark.png")
	_select("portrait_remember")
	await _at(954)
	await _tap("interact")
	await _wait(0.8)
	_log("gallery open after giving REMEMBER at the painting=" + str(gs.has_flag(&"gallery_open")) + " damage=" + str(gs.comic_damage))
	await _shot("05_gallery_open.png")
	await _wait(1.0)
	await _walk_right()
	_log("arrived")
	await _wait(1.8)
	_log("shadow=" + STATES[_shadow().state])
	await _shot("06_shadow.png")
	await _at(385)
	await _tap("interact")
	_log("hiding=" + str(player.is_concealed()))
	await _wait(6.2)
	await _shot("07_scribble.png")
	await _wait(1.5)
	_log("after erase: concealed=" + str(player.is_concealed()) + " shadow=" + STATES[_shadow().state])
	await _at(1000)
	Input.action_press("move_right")
	await _wait(0.6)
	Input.action_release("move_right")
	await _wait(2.5)
	_log("end")
	await _shot("08_card.png")
	quit()
