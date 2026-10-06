extends SceneTree
## Intro and ending pages (dev test, not exported): screenshots each page of
## the New Game intro and of the epilogue. Run from the repo root:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/cinematics_check.gd

var bus
var main

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

## A hidden window (another Space, a full-screen app) is never drawn, so
## frame_post_draw never comes: then force a draw for the shot.
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
	var am = root.get_node("/root/AudioManager")
	var gs0 = root.get_node("/root/GameState")
	var t0: int = Time.get_ticks_msec()
	var cried := false
	var worst := 0
	var worst_all := 0
	var fast: bool = OS.get_environment("FAST") == "1"
	for at in [2.5, 5.2, 6.6, 7.9, 9.2, 10.6, 12.2, 13.3, 13.8, 15.6, 17.6]:
		if fast:
			intro._t = at - 0.02
			await process_frame
		while intro._t >= 0.0 and intro._t < at:
			var f0: int = Time.get_ticks_usec()
			await process_frame
			worst = maxi(worst, Time.get_ticks_usec() - f0)
			cried = cried or String(am.last_played) == "cry_raw"
		print("   up to %.1f s: slowest %.1f ms" % [at, worst / 1000.0])
		worst_all = maxi(worst_all, worst)
		worst = 0
		await _shot("in_%04.1f.png" % at)
	worst = worst_all
	while intro.visible:
		await process_frame
		cried = cried or String(am.last_played) == "cry_raw"
	if fast:
		print("FAST: shots only")
		quit()
		return
	print("intro length %.1f s (T_END %.1f), slowest frame %.1f ms (screenshot frames excluded)" % [(Time.get_ticks_msec() - t0) / 1000.0, intro.T_END, worst / 1000.0])
	print(("ok   " if cried and gs0.seen.has(&"cry_intro") else "FAIL ") + "the intro ends on the recorded cry (raw), marked seen")
	am.play_cry(&"raw", -17.0, 0.0, &"cry_intro")
	print(("ok   " if gs0.seen.count(&"cry_intro") == 1 else "FAIL ") + "the intro cry is one-time")
	await _wait(1.0)
	main.get_node("MenuLayer/MainMenu").hide()
	main.get_node("MenuLayer/IntroSequence").hide()
	var gs = root.get_node("/root/GameState")
	gs.is_playing = true
	root.get_node("/root/FrameManager").go_to(&"ch3_outside")
	var prev := 0.0
	for at in [5.0, 12.0, 16.0, 23.0, 29.0]:
		await _wait(at - prev)
		prev = at
		await _shot("ep_%04.1f.png" % at)
	await _wait(2.0)
	print("CINEMATICS DONE")
	quit()
