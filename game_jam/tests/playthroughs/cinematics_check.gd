extends SceneTree
## Intro and ending pages (dev test, not exported): screenshots each page of
## the New Game intro and of the epilogue. Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/cinematics_check.gd

var bus
var main

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

func _run() -> void:
	bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	bus.menu_new_game.emit()
	current_scene.get_node("MenuLayer/ControlsCard").call("_accept")
	var intro = main.get_node("MenuLayer/IntroCinematic")
	main.get_node("MenuLayer/MainMenu").hide()
	var prev := 0.0
	for at in [4.0, 7.0, 12.5, 16.0, 19.9, 23.5]:
		await _wait(at - prev)
		prev = at
		await _shot("in_%04.1f.png" % at)
	await _wait(2.0)
	print("intro done visible=", intro.visible)
	main.get_node("MenuLayer/MainMenu").hide()
	main.get_node("MenuLayer/IntroSequence").hide()
	var gs = root.get_node("/root/GameState")
	gs.is_playing = true
	root.get_node("/root/FrameManager").go_to(&"ch3_outside")
	prev = 0.0
	for at in [5.0, 12.0, 16.0, 23.0, 29.0]:
		await _wait(at - prev)
		prev = at
		await _shot("ep_%04.1f.png" % at)
	await _wait(2.0)
	print("CINEMATICS DONE")
	quit()
