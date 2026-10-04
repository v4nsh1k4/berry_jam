extends SceneTree
## Reveal test (dev, not exported): starts in the Ink Heart with the robbed
## words held, steals ERASE, screenshots each caption beat, then checks the
## return phase and the goal line. Run from game_jam/:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/reveal_check.gd

var gs
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
	gs = root.get_node("/root/GameState")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	bus.menu_new_game.emit()
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	main.get_node("MenuLayer/MainMenu").hide()
	bus.intro_finished.emit()
	main.get_node("MenuLayer/IntroSequence").hide()
	await _wait(0.5)
	# Carry the chapter 1-2 words, then go to the Heart via the debug helper.
	var dj = load("res://scripts/systems/debug_jump.gd")
	var ch = dj.prepare("ch3_ink_heart")
	gs.current_chapter = ch
	gs.is_playing = true
	root.get_node("/root/FrameManager").go_to(&"ch3_ink_heart")
	await _wait(1.5)
	var reveal = main.get_node("MenuLayer/RevealSequence")
	gs.add_bubble(load("res://data/bubbles/hand_erase.tres"))
	var times := [3.5, 7.5, 12.0, 15.5, 19.5, 22.5, 26.0, 29.5, 33.0]
	var prev := 0.0
	for i in times.size():
		await _wait(times[i] - prev + (0.5 if i == 0 else 0.0))
		prev = times[i]
		await _shot("rv_%d.png" % i)
	await _wait(5.0)
	var ok: bool = gs.twist_revealed and not paused
	print("twist=", gs.twist_revealed, " frame=", gs.current_frame_id, " paused=", paused)
	await _wait(1.0)
	await _shot("rv_goal.png")
	var goal = main.get_node("HUDLayer/GoalLine")
	print("goal text=", goal._text, " target=", goal._target)
	ok = ok and goal._target == 1.0
	print("REVEAL TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
