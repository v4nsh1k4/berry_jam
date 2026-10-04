extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/exit_grace.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.
var gs
var fm
func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()
func _wait(sec: float) -> void:
	await create_timer(sec).timeout
func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	var bus = root.get_node("/root/EventBus")
	# Cutscenes have their own test (cutscenes.gd): skip them here.
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	bus.game_started.emit()
	bus.menu_new_game.emit()
	# New Game opens with the intro cinematic: skip it like a click would.
	current_scene.get_node("MenuLayer/IntroCinematic").call("_finish")
	bus.intro_finished.emit()
	current_scene.get_node("MenuLayer/IntroSequence").hide()
	current_scene.get_node("MenuLayer/MainMenu").hide()
	await _wait(0.3)
	gs.add_bubble(load("res://data/bubbles/arthur_open.tres"))
	fm.go_to(&"ch1_landing")
	await _wait(0.3)
	var player = current_scene.get_node("World/Player")
	player.global_position = Vector2(48 + 1075, 32 + 466)
	await _wait(0.4)
	var zone = null
	for z in fm.current_frame.get_node("Exits").get_children():
		if z.exit_data.required_flag == &"study_door_open":
			zone = z
	print("inside=", zone._player_inside, " was_locked=", not zone._unlocked_last)
	gs.select(0, false)
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(0.06)
	var up := InputEventAction.new()
	up.action = "interact"
	Input.parse_input_event(up)
	for i in 10:
		await _wait(0.25)
		print("t=", (i + 1) * 0.25, " frame=", fm.current_frame.data.id, " grace=", zone._grace_left if is_instance_valid(zone) else -1.0, " open=", gs.has_flag(&"study_door_open"), " locked=", (not zone._unlocked_last) if is_instance_valid(zone) else false)
	quit()
