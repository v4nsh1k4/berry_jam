extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/save_check.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.
## Step 0 save/load review across chapters.
var gs
var fm
var bus
var main

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _texts() -> Array:
	return gs.inventory.map(func(b): return b.text)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	gs.reset()
	gs.add_bubble(load("res://data/bubbles/arthur_open.tres"))
	gs.set_flag(&"has_flashlight")
	main._start_chapter(load("res://data/chapters/ch2.tres"))
	await _wait(0.4)
	fm.go_to(&"ch2_pantry")
	await _wait(0.3)
	var player = main.get_node("World/Player")
	player.global_position = Vector2(48 + 370, 32 + 466)
	await _wait(0.2)
	Input.action_press("interact")
	await _wait(0.7)
	Input.action_release("interact")
	await _wait(0.4)
	print("1 stole: ", _texts())
	bus.quit_to_menu_requested.emit()
	await _wait(0.3)
	gs.reset()
	gs.current_chapter = null
	main.get_node("MenuLayer/MainMenu").hide()
	bus.menu_continue.emit()
	await _wait(0.5)
	var vane = null
	for n in fm.current_frame.get_node("Props").get_children():
		if "data" in n and n.data is Resource and n.data.get("visual_style") == &"housekeeper":
			vane = n
	var broken := 0
	for b in vane.get_children():
		if b.get("stolen") == true:
			broken += 1
	print("2 continue: frame=", gs.current_frame_id, " chapter=", gs.current_chapter.id if gs.current_chapter else "none", " words=", _texts(), " vane broken bubbles=", broken, " jitter=", InkDraw.jitter_scale)
	bus.restart_chapter_requested.emit()
	await _wait(1.3)
	print("3 restart: frame=", gs.current_frame_id, " words=", _texts(), " vane_hide stolen=", gs.is_bubble_stolen(&"vane_hide"))
	# A save that points at a missing word file must not strand that word.
	var snap: Dictionary = gs.to_dict()
	snap["inventory"] = ["res://data/bubbles/arthur_open.tres", "res://data/bubbles/renamed_word.tres"]
	snap["stolen_ids"] = ["arthur_open", "vane_hide"]
	gs.from_dict(snap)
	print("4 missing file: words=", _texts(), " vane_hide still marked stolen=", gs.is_bubble_stolen(&"vane_hide"))
	# Continue from the last Chapter 1 panel hands off to Chapter 2.
	gs.reset()
	gs.current_chapter = load("res://data/chapters/ch1.tres")
	gs.current_frame_id = &"ch1_end"
	gs.is_playing = true
	gs.checkpoint()
	bus.quit_to_menu_requested.emit()
	await _wait(0.3)
	main.get_node("MenuLayer/MainMenu").hide()
	bus.menu_continue.emit()
	await _wait(2.2)
	print("5 ch1_end continue: intro visible=", main.get_node("MenuLayer/IntroSequence").visible, " pending=", main._pending.id if main._pending else "none")
	SaveSystem.clear()
	quit()
