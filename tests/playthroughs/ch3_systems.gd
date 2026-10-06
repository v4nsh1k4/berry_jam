extends SceneTree
## Chapter 3 systems (dev test, not exported): save migration (v1 -> v2),
## resuming between the final theft and the end of the reveal, Restart Chapter
## after the reveal, the Artist's hand (telegraph, catch, hiding, WAIT, getting
## weaker), the Ink Heart's listening, and the lost-word fallback.
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_systems.gd

var gs
var fm
var bus
var main
var player
var caught: Array = [0]
const HAND := ["HOVER", "AIM", "RUB", "LIFT", "WATCH", "OFFER", "WITHDRAW"]
const STATES := ["DORMANT", "PATROL", "STALKING", "HUNTING", "TELEGRAPH", "LUNGE", "SEARCHING", "RETREATING"]
const SAVE: String = "user://ink_bleed_save.json"

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

func _at(x: float) -> void:
	player.global_position = Vector2(48 + x, 32 + 466)
	await _wait(0.15)

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

func _select(id: String) -> void:
	for i in gs.inventory.size():
		if String(gs.inventory[i].id) == id:
			gs.select(i, false)

func _hand():
	if fm.current_frame == null:
		return null
	for node in fm.current_frame.get_node("Props").get_children():
		if node.has_method("_aim"):
			return node
	return null

func _write_save(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func _jump(frame: String, words: Array, twist: bool) -> void:
	# A catch's reload transition may still be running: let it finish first.
	while fm._busy or root.get_node("/root/TransitionManager").is_playing:
		await _wait(0.1)
	gs.reset()
	gs.twist_revealed = twist
	for w in words:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	gs.set_flag(&"has_flashlight")
	gs.snap_damage()
	main._start_chapter(load("res://data/chapters/ch3.tres"), StringName(frame))
	main.get_node("MenuLayer/IntroSequence").hide()
	main._pending = null
	await _wait(0.6)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	# Cutscenes have their own test (cutscenes.gd): skip them here.
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	bus.player_caught.connect(func(): caught[0] += 1)
	await _wait(0.3)
	bus.game_started.emit()
	main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")
	var save_system = load("res://scripts/systems/save_system.gd")

	# A. Save migration.
	var v1_ch3 := {"version": 1, "frame": "ch3_gallery_words", "chapter": "res://data/chapters/ch3.tres",
		"inventory": ["res://data/bubbles/portrait_remember.tres"], "returned_ids": ["arthur_open", "vane_hide"],
		"chapter_start": {"frame": "ch3_torn_page", "chapter": "res://data/chapters/ch3.tres",
			"inventory": ["res://data/bubbles/arthur_open.tres", "res://data/bubbles/vane_hide.tres", "res://data/bubbles/portrait_remember.tres"],
			"stolen_ids": ["arthur_open", "vane_hide", "portrait_remember"], "damage": 3.0, "returned_ids": []}}
	var m: Dictionary = save_system.migrate(v1_ch3)
	print("A1 v1 ch3 -> frame=", m.get("frame"), " twist=", m.get("twist_revealed"), " returned=", m.get("returned_ids"), " words=", m.get("inventory").size(), " version=", m.get("version"))
	var v1_ch2 := {"version": 1, "frame": "ch2_pantry", "chapter": "res://data/chapters/ch2.tres", "inventory": []}
	print("A2 v1 ch2 -> frame=", save_system.migrate(v1_ch2).get("frame"))
	print("A3 v1 ch3 without start -> empty=", save_system.migrate({"version": 1, "frame": "ch3_margin", "chapter": "res://data/chapters/ch3.tres"}).is_empty())
	print("A4 future version -> empty=", save_system.migrate({"version": 99, "frame": "x"}).is_empty())
	_write_save(v1_ch3)
	main._on_continue()
	await _wait(0.8)
	print("A5 continue old save: frame=", fm.current_frame.data.id, " twist=", gs.twist_revealed, " can_return=", gs.can_return(), " words=", gs.inventory.size())
	var gone := {"version": 2, "frame": "ch3_heart_card", "chapter": "res://data/chapters/ch3.tres", "inventory": []}
	_write_save(gone)
	main._on_continue()
	await _wait(0.8)
	print("A6 save in a removed frame: frame=", fm.current_frame.data.id)

	# B. Saved between the theft and the end of the reveal: it plays again.
	await _jump("ch3_ink_heart", ["arthur_open", "arthur_push", "portrait_remember", "hand_erase"], false)
	gs.checkpoint()
	bus.quit_to_menu_requested.emit()
	await _wait(0.4)
	main._on_continue()
	await _wait(1.5)
	var reveal = main.get_node("MenuLayer/RevealSequence")
	print("B1 resume mid-reveal: reveal playing=", reveal.visible, " paused=", paused, " skippable(second viewing)=", reveal._skippable)
	await _wait(1.5)
	await _shot("20_reveal_resumed.png")
	await _tap("ui_accept")
	await _wait(1.6)
	print("B2 after skip: frame=", fm.current_frame.data.id, " twist=", gs.twist_revealed, " restart frame=", gs.chapter_start.get("frame"), " paused=", paused)

	# C. Restart Chapter after the reveal starts the return phase, not Chapter 3.
	_select("arthur_open")
	await _at(365)
	Input.action_press("interact")
	await _wait(0.9)
	Input.action_release("interact")
	await _wait(0.3)
	print("C1 returned OPEN=", gs.is_bubble_returned(&"arthur_open"))
	bus.restart_chapter_requested.emit()
	await _wait(1.4)
	print("C2 restart: frame=", fm.current_frame.data.id, " twist=", gs.twist_revealed, " OPEN back in hand=", not gs.is_bubble_returned(&"arthur_open"))

	# D. The hand: warning, rub, catch; returns survive the reload.
	await _jump("ch3_returning_room", ["arthur_open", "arthur_push", "arthur_wait", "portrait_remember", "vane_hide"], true)
	_select("arthur_push")
	await _at(255)
	Input.action_press("interact")
	await _wait(0.9)
	Input.action_release("interact")
	var hand = _hand()
	print("D0 hand=", HAND[hand.state], " PUSH returned=", gs.is_bubble_returned(&"arthur_push"))
	await _at(500)
	var aim_at: float = -1.0
	var rub_at: float = -1.0
	var t: float = 0.0
	var before: int = caught[0]
	while t < 9.0 and caught[0] == before:
		hand = _hand()
		if hand != null and hand.state == 1 and aim_at < 0.0:
			aim_at = t
			await _shot("21_hand_aim.png")
		if hand != null and hand.state == 2 and aim_at >= 0.0 and rub_at < 0.0:
			rub_at = t
		await _wait(0.05)
		t += 0.05
	if rub_at < 0.0:
		rub_at = t # caught on the eraser's first touch
	print("D1 telegraph=", snapped(rub_at - aim_at, 0.05), "s (min 0.6) caught=", caught[0] - before)
	await _wait(1.5)
	print("D2 after reload: frame=", fm.current_frame.data.id, " PUSH still returned=", gs.is_bubble_returned(&"arthur_push"))

	# E. Hiding in the table is safe; WAIT freezes the hand.
	while fm._busy:
		await _wait(0.1)
	await _wait(0.3)
	await _at(80)
	await _tap("interact")
	print("E0 hidden=", player.is_concealed())
	before = caught[0]
	await _wait(9.0)
	print("E1 caught while hidden=", caught[0] - before, " hand=", HAND[_hand().state])
	await _tap("interact")
	_select("arthur_wait")
	await _at(500)
	await _tap("interact")
	print("E2 WAIT froze hand=", _hand()._frozen > 0.0)

	# F. Weaker with every word: telegraph longer, strip narrower, rarer.
	var p = load("res://data/hand/hand_pressure.tres")
	print("F1 full: interval=", p.interval(1.0), " telegraph=", p.telegraph(1.0), " width=", p.width(1.0), " | one left: interval=", p.interval(0.2), " telegraph=", p.telegraph(0.2), " width=", p.width(0.2))
	for w in ["arthur_open", "arthur_wait"]:
		_select(w)
		await _at(365 if w == "arthur_open" else 755)
		Input.action_press("interact")
		await _wait(0.9)
		Input.action_release("interact")
		await _wait(0.3)
	print("F2 held share=", snapped(gs.held_share(), 0.01), " hand=", HAND[_hand().state])

	# G. Lost word fallback: stolen but no longer held -> goes home by itself.
	await _jump("ch3_returning_room", ["portrait_remember", "hand_erase"], true)
	gs.stolen_bubble_ids.append(&"vane_hush")
	print("G0 frame=", fm.current_frame.data.id, " can_return=", gs.can_return(), " time_scale=", Engine.time_scale, " paused=", paused)
	await _at(820)
	await _wait(0.5)
	print("G1 lost vane_hush restored=", gs.is_bubble_returned(&"vane_hush"))

	# H. Ink Heart: moving while it listens wakes it; caught keeps the words.
	await _jump("ch3_ink_heart", ["arthur_open", "arthur_push", "portrait_remember"], false)
	var shadow = get_first_node_in_group(&"crawler")
	print("H0 frame=", fm.current_frame.data.id, " shadow=", shadow, " state=", STATES[shadow.state], " ear=", shadow._ear, " t=", shadow._ear_time, " done=", shadow._done, " frozen=", shadow.is_frozen())
	await _at(600)
	t = 0.0
	while t < 8.0 and shadow._ear != 2:
		await _wait(0.1)
		t += 0.1
	print("H1 listening after ", snapped(t, 0.1), "s (warning first: ", shadow.LISTEN_WARNING, "s)")
	before = caught[0]
	Input.action_press("move_left")
	await _wait(0.4)
	Input.action_release("move_left")
	await _wait(0.2)
	print("H2 heard: state=", STATES[shadow.state])
	await _shot("22_heart_hunting.png")
	await _wait(6.0)
	print("H3 caught=", caught[0] - before, " frame=", fm.current_frame.data.id, " words=", gs.inventory.size())
	quit()
