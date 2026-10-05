extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_margin.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.
var gs
var fm
var player
const STATES := ["DORMANT", "PATROL", "STALKING", "HUNTING", "TELEGRAPH", "LUNGE", "SEARCHING", "RETREATING"]
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
func _st() -> String:
	var s = get_first_node_in_group(&"crawler")
	return (STATES[s.state] + " x=" + str(int(s.position.x))) if s else "none"
func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	var bus = root.get_node("/root/EventBus")
	# Cutscenes have their own test (cutscenes.gd): skip them here.
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	var caught := [0]
	bus.player_caught.connect(func(): caught[0] += 1)
	await _wait(0.3)
	bus.game_started.emit()
	var main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")
	gs.reset()
	gs.set_flag(&"has_flashlight")
	main._start_chapter(load("res://data/chapters/ch3.tres"))
	main.get_node("MenuLayer/IntroSequence").hide()
	main._pending = null
	await _wait(0.3)
	fm.go_to(&"ch3_margin")
	for i in 4:
		await _wait(0.5)
		print("t=", (i + 1) * 0.5, " shadow=", _st())
	await _shot("10_margin_rising.png")
	player.global_position = Vector2(48 + 385, 32 + 466)
	await _wait(0.2)
	await _tap("interact")
	await _wait(0.3)
	print("hidden=", player.is_concealed(), " shadow=", _st())
	for i in 14:
		await _wait(0.5)
		print("t+", (i + 1) * 0.5, " shadow=", _st(), " concealed=", player.is_concealed(), " caught=", caught[0])
		if i == 11:
			await _shot("11_margin_scribble.png")
		if not player.is_concealed():
			break
	await _shot("12_pushed_out.png")
	Input.action_press("sprint")
	Input.action_press("move_right")
	await _wait(2.6)
	Input.action_release("move_right")
	Input.action_release("sprint")
	await _wait(2.0)
	print("frame=", fm.current_frame.data.id, " caught total=", caught[0])
	await _shot("13_heart_card.png")
	quit()
