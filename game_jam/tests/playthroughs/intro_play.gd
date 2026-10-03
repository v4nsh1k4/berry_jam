extends SceneTree
## The New Game intro cinematic (dev test, not exported): plays in full, then
## hands over to Chapter 1's captions; a second New Game is skipped with Space.
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/intro_play.gd

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _shot(name: String) -> void:
	if DisplayServer.window_get_size() != Vector2i(1280, 720):
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
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

func _run() -> void:
	var bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	await _wait(0.3)
	bus.menu_new_game.emit()
	current_scene.get_node("MenuLayer/MainMenu").hide()
	var cinematic = current_scene.get_node("MenuLayer/IntroCinematic")
	var captions = current_scene.get_node("MenuLayer/IntroSequence")
	var elapsed: float = 0.0
	for mark in [1.5, 6.0, 10.0, 13.6, 15.7, 18.3]:
		await _wait(mark - elapsed)
		elapsed = mark
		await _shot("30_intro_%04.1f.png" % mark)
	await _wait(1.2)
	print("I1 cinematic done=", not cinematic.visible, " chapter captions showing=", captions.visible)
	await _shot("31_intro_captions.png")
	captions.hide()
	bus.menu_new_game.emit()
	await _wait(1.0)
	await _tap("ui_accept")
	await _wait(0.3)
	print("I2 skipped with Space: cinematic visible=", cinematic.visible, " captions showing=", captions.visible)
	quit()
