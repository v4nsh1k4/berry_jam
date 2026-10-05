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
	gs = root.get_node("/root/GameState")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	bus.menu_new_game.emit()
	main.get_node("MenuLayer/ControlsCard").call("_accept")
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
	await _wait(1.0)
	var starts: PackedFloat32Array = reveal._starts
	print("reveal beats at ", starts, " total ", reveal.total())
	var prev := 0.5
	var am = root.get_node("/root/AudioManager")
	var cry_beat := -1
	for i in starts.size() - 1:
		var mid: float = (starts[i] + starts[i + 1]) * 0.5 + 0.5
		await _wait(mid - prev)
		prev = mid
		if cry_beat < 0 and String(am.last_played) == "cry_thin":
			cry_beat = i
		await _shot("rv_%d.png" % i)
	await _wait(reveal.total() - prev + 2.5)
	var ok: bool = gs.twist_revealed and not paused
	# Stage 5: the recorded cry, cut short, as the eraser rubs the figure out.
	print("cry (thin) heard by beat %d (%s), seen=%s" % [cry_beat, reveal._beats[maxi(cry_beat, 0)].id, gs.seen.has(&"cry_reveal")])
	ok = ok and reveal._beats[maxi(cry_beat, 0)].id == &"erase" and gs.seen.count(&"cry_reveal") == 1
	print("twist=", gs.twist_revealed, " frame=", gs.current_frame_id, " paused=", paused)
	await _wait(1.0)
	await _shot("rv_goal.png")
	var goal = main.get_node("HUDLayer/GoalLine")
	print("goal text=", goal._text, " target=", goal._target)
	ok = ok and goal._target == 1.0
	print("REVEAL TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
