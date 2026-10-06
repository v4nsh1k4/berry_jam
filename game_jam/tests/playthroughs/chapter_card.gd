extends SceneTree
## Stage 7: the chapter title card appears as soon as the player leaves a
## chapter's last room (dev test, not exported). Walks into the Chapter 1 and
## Chapter 2 exits with real input (page turn, C4 cutscene) and checks, every
## frame, that the player never has control between leaving the room and
## the card, that the card shows while the hand-off panel is still the frame
## (before the next chapter's first room exists), and that the new chapter
## then starts with control back and its chapter_start snapshot.
##   godot --path . --disable-vsync --resolution 1280x720 --script res://tests/playthroughs/chapter_card.gd

var gs
var fm
var main
var player
var failures: Array = []

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
	await create_timer(sec, true, false, true).timeout

func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		failures.append(what)

## Walks right from `from_x` in `room` into its exit, then follows the hand-off.
func _cross(label: String, room: StringName, chapter: String, from_x: float, end_frame: StringName, next_first: StringName) -> void:
	main._start_chapter(load(chapter), room)
	main.get_node("MenuLayer/IntroSequence").hide()
	main._pending = null
	await _wait(1.0)
	player.global_position = Vector2(48 + from_x, 32 + 466)
	await _wait(0.2)
	var card = main.get_node("MenuLayer/IntroSequence")
	Input.action_press("move_right")
	var left_room: bool = false
	var moved_after: bool = false
	var acted_after: bool = false
	var card_frame: StringName = &""
	var t_left: float = 0.0
	var t: float = 0.0
	var last_x: float = 0.0
	while t < 30.0:
		await process_frame
		var dt: float = get_root().get_process_delta_time()
		t += dt
		var frame: StringName = fm.current_frame.data.id if fm.current_frame != null else &""
		if not left_room and frame == end_frame:
			left_room = true
			t_left = t
			Input.action_release("move_right")
			last_x = player.global_position.x
		if left_room and not card.visible:
			# Between leaving the room and the card: no control, no movement
			# (the page turn's own swap moves the player once; ignore that).
			if player.can_act():
				acted_after = true
			if not root.get_node("/root/TransitionManager").is_playing and absf(player.global_position.x - last_x) > 0.5:
				moved_after = true
			last_x = player.global_position.x
		if card.visible:
			card_frame = frame
			break
	Input.action_release("move_right")
	_check(left_room, "%s: walked out of %s into %s" % [label, room, end_frame])
	_check(card.visible, "%s: title card shown" % label)
	_check(card_frame == end_frame, "%s: card visible before the next chapter's first room exists (frame=%s)" % [label, card_frame])
	_check(not acted_after, "%s: player never had control between leaving the room and the card" % label)
	_check(not moved_after, "%s: player did not move in the hand-off panel" % label)
	_check(not player.can_act(), "%s: no control while the card is up" % label)
	print("%s: card %.2f s after the swap (page turn + cutscene included)" % [label, t - t_left])
	await _shot("card_%s.png" % label)
	await _wait(0.3)
	card._next()
	await _wait(0.6)
	_check(fm.current_frame.data.id == next_first, "%s: new chapter starts in %s (got %s)" % [label, next_first, fm.current_frame.data.id])
	_check(player.can_act(), "%s: control back in the new chapter" % label)
	_check(String(gs.chapter_start.get("frame", "")) == String(next_first), "%s: chapter_start anchored on %s" % [label, next_first])

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	var bus = root.get_node("/root/EventBus")
	await _wait(0.3)
	bus.game_started.emit()
	main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")
	gs.reset()
	for w in ["arthur_open", "arthur_push", "portrait_remember"]:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	gs.set_flag(&"has_flashlight")
	await _cross("ch1_to_ch2", &"ch1_exit", "res://data/chapters/ch1.tres", 980.0, &"ch1_end", &"ch2_long_hallway")
	gs.set_flag(&"cellar_open")
	await _cross("ch2_to_ch3", &"ch2_cellar", "res://data/chapters/ch2.tres", 980.0, &"ch2_end", &"ch3_gallery_words")
	print("CHAPTER CARD TEST ", "PASSED" if failures.is_empty() else "FAILED %s" % str(failures))
	quit()
