extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch1_flows.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.
## Second pass: drawer reward, wrong word, quit + continue, restart, caught.

var gs
var fm
var player

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

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

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	var bus = root.get_node("/root/EventBus")
	# Cutscenes have their own test (cutscenes.gd): skip them here.
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	bus.game_started.emit()
	await _wait(0.2)
	bus.menu_new_game.emit()
	# New Game opens with the intro cinematic: skip it like a click would.
	current_scene.get_node("MenuLayer/ControlsCard").call("_accept")
	current_scene.get_node("MenuLayer/IntroCinematic").call("_finish")
	current_scene.get_node("MenuLayer/MainMenu").hide()
	await _wait(0.2)
	bus.intro_finished.emit()
	current_scene.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.3)
	player = current_scene.get_node("World/Player")
	# Give OPEN directly and open the drawer for HUSH.
	gs.add_bubble(load("res://data/bubbles/arthur_open.tres"))
	gs.add_bubble(load("res://data/bubbles/arthur_wait.tres"))
	fm.go_to(&"ch1_bedchamber")
	await _wait(0.4)
	await _at(370)
	gs.select(1)
	await _tap("interact")
	print("WAIT at drawer -> open=", gs.has_flag(&"drawer_open"))
	await _wait(0.1)
	await _shot("20_wrong_word.png")
	await _wait(0.6)
	gs.selected_index = -1
	gs.select(0)
	await _tap("interact")
	await _wait(0.3)
	await _shot("21_drawer_hush.png")
	print("drawer open=", gs.has_flag(&"drawer_open"), " inventory=", gs.inventory.map(func(b): return b.text))
	await _wait(1.5)
	# Quit to menu, then Continue.
	bus.quit_to_menu_requested.emit()
	await _wait(0.3)
	print("menu visible=", current_scene.get_node("MenuLayer/MainMenu").visible, " playing=", gs.is_playing)
	gs.reset()
	current_scene.get_node("MenuLayer/MainMenu").hide()
	bus.menu_continue.emit()
	await _wait(0.4)
	print("continued frame=", gs.current_frame_id, " inventory=", gs.inventory.map(func(b): return b.text), " drawer flag=", gs.has_flag(&"drawer_open"))
	# Restart chapter.
	bus.restart_chapter_requested.emit()
	await _wait(1.3)
	print("restarted frame=", gs.current_frame_id, " inventory=", gs.inventory.size(), " damage=", gs.comic_damage)
	quit()
