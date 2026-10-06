extends SceneTree
## Reveal test (dev, not exported): starts in the Ink Heart with the robbed
## words held, steals ERASE, screenshots each caption beat, then checks the
## return phase and the goal line. Run from the repo root:
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
	var ok_text := true
	print("reveal beats at ", starts, " total ", reveal.total())
	# Stage 6: the second half's captions, in order, one per beat; "author"
	# everywhere; "never a monster" once; the last line held longest.
	var want: Array = ["The monster was never a monster.", "It was, in fact, the author's hand.",
		"To the author, you were the anomaly. A glitch. A mistake.",
		"You starved the characters of their words, and broke the story.", "You were the monster."]
	var texts: Array = []
	var all_text: String = ""
	var longest_other := 0.0
	var you_len := 0.0
	for i in reveal._beats.size():
		var b: Dictionary = reveal._beats[i]
		var d: float = starts[i + 1] - starts[i]
		print("  beat %d %s %.2fs \"%s\"" % [i, b.id, d, b.text])
		if b.text != "":
			texts.append(b.text)
			ok_text = ok_text and d >= 2.5
			if b.id == &"you":
				you_len = d
			else:
				longest_other = maxf(longest_other, d)
		all_text += String(b.text) + "\n"
	var beats_cls = load("res://ui/reveal_beats.gd")
	all_text += String(beats_cls.LABEL) + "\n" + "\n".join(beats_cls.RECAP)
	print("label card: ", beats_cls.LABEL, " | recap: ", beats_cls.RECAP)
	ok_text = ok_text and texts.slice(texts.size() - 5) == want
	ok_text = ok_text and all_text.count("never a monster") == 1 and all_text.findn("artist") < 0
	ok_text = ok_text and all_text.contains("author's hand") and String(beats_cls.RECAP[1]).contains("glitch")
	ok_text = ok_text and you_len > longest_other
	print("captions ok=", ok_text, " (you %.2fs vs longest other %.2fs)" % [you_len, longest_other])
	var am = root.get_node("/root/AudioManager")
	var mm = root.get_node("/root/MusicManager")
	var cry_beat := -1
	var hushed := false
	for i in starts.size() - 1:
		var marks: Array = [0.5]
		if reveal._beats[i].id in [&"hand", &"erase", &"you"]:
			marks = [0.3, 0.85]
		for m in marks.size():
			while reveal._t < lerpf(starts[i], starts[i + 1], marks[m]):
				await process_frame
			if cry_beat < 0 and String(am.last_played) == "cry_thin":
				cry_beat = i
			if reveal._beats[i].id == &"you" and m == 0:
				hushed = mm._duck >= 0.95 and am._hush > 0.0
				print("held beat: music duck=%.2f ambience hush=%.2f" % [mm._duck, am._hush])
			await _shot("rv_%d%s.png" % [i, "" if marks.size() == 1 else "ab"[m]])
	while reveal._t < reveal.total():
		await process_frame
	await _wait(2.5)
	var ok: bool = gs.twist_revealed and not paused and ok_text and hushed
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
