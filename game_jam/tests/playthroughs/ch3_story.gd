extends SceneTree
## Scripted playthrough of Chapter 3 in story order (dev test, not exported):
## Torn Page (no returning yet) -> Gallery puzzle -> Margin -> Ink Heart (final
## steal) -> reveal -> Returning Room -> Torn Page -> Gallery -> Ink Heart
## (ERASE back, repair) -> Last Page -> epilogue -> end card.
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ch3_story.gd
## Screenshots go to $SHOT_DIR. Set MINIMAL=1 to carry only OPEN, PUSH, REMEMBER.

var gs
var fm
var bus
var main
var player
var captions: Array = []
var caught: Array = [0]
const STATES := ["DORMANT", "PATROL", "STALKING", "HUNTING", "TELEGRAPH", "LUNGE", "SEARCHING", "RETREATING"]
const HAND := ["HOVER", "AIM", "RUB", "LIFT", "WATCH", "OFFER", "WITHDRAW"]

func _shot_dir() -> String:
	var dir: String = OS.get_environment("SHOT_DIR")
	return dir if dir != "" else OS.get_user_data_dir()

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _shot(name: String) -> void:
	# Long runs can get their window shrunk by the desktop: put it back first.
	if DisplayServer.window_get_size() != Vector2i(1280, 720):
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
	await RenderingServer.frame_post_draw
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

func _select(id: String) -> bool:
	for i in gs.inventory.size():
		if String(gs.inventory[i].id) == id:
			gs.select(i, false)
			return true
	return false

func _hold(sec: float) -> void:
	Input.action_press("interact")
	await _wait(sec)
	Input.action_release("interact")
	await _wait(0.3)

## Gives a word back under its owner's bubble at panel x; retries if the hand
## rubs the player out mid-hold (returns must survive the reload).
func _give(id: String, x: float) -> void:
	for attempt in 4:
		if not _select(id):
			break
		await _at(x)
		await _hold(0.9)
		if gs.is_bubble_returned(StringName(id)):
			break
		await _wait(1.5)
	_log("give " + id + " -> returned=" + str(gs.is_bubble_returned(StringName(id))) + " damage=" + str(gs.comic_damage) + " caught=" + str(caught[0]))

func _say(id: String, x: float) -> void:
	_select(id)
	await _at(x)
	await _tap("interact")
	await _wait(0.4)

func _walk_right(from: float = 1000.0) -> void:
	var before = fm.current_frame.data.id
	await _at(from)
	Input.action_press("move_right")
	for i in 30:
		await _wait(0.1)
		if fm.current_frame.data.id != before:
			break
	Input.action_release("move_right")
	await _wait(1.0)

func _log(msg: String) -> void:
	print("[", fm.current_frame.data.id if fm.current_frame else "-", "] ", msg)

func _enemy():
	return get_first_node_in_group(&"crawler")

func _hand():
	for node in get_nodes_in_group(&"freezable"):
		if node.get("state") != null and node.has_method("_aim"):
			return node
	for node in fm.current_frame.get_node("Props").get_children():
		if node.has_method("_aim"):
			return node
	return null

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.caption_requested.connect(func(text, _d): captions.append(text))
	bus.player_caught.connect(func(): caught[0] += 1)
	await _wait(0.3)
	bus.game_started.emit()
	main = current_scene
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")
	gs.reset()
	var minimal: bool = OS.get_environment("MINIMAL") == "1"
	var words: Array = ["arthur_open", "arthur_push", "portrait_remember"] if minimal else \
		["arthur_open", "arthur_push", "arthur_help", "portrait_remember", "vane_hide", "vane_hush", "vane_wait"]
	for w in words:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	gs.set_flag(&"has_flashlight")
	main._start_chapter(load("res://data/chapters/ch3.tres"))
	await _wait(0.5)
	_log("start words=" + str(gs.inventory.size()) + " twist=" + str(gs.twist_revealed) + " can_return=" + str(gs.can_return()))

	# 1. Torn Page: nothing can be given back before the reveal.
	await _at(300)
	await _wait(0.4)
	if not minimal:
		_select("vane_hide")
		await _at(280)
		var prompt: Array = [""]
		bus.interact_prompt_changed.connect(func(t, _p): prompt[0] = t, CONNECT_ONE_SHOT)
		await _hold(0.9)
		_log("pre-reveal give: returned=" + str(gs.is_bubble_returned(&"vane_hide")) + " returnable=" + str(get_nodes_in_group(&"returnable").size()))
	_select("portrait_remember")
	await _at(770)
	await _hold(0.9)
	_log("portrait plea captions=" + str(captions.filter(func(c): return "Portrait" in c or "Vane" in c)))
	await _shot("00_torn_page.png")
	await _walk_right()

	# 2. Gallery of Words: PUSH, REMEMBER, dials, OPEN. No returning.
	_log("arrived gallery_open=" + str(gs.has_flag(&"gallery_open")) + " return spots usable=" + str(get_nodes_in_group(&"interactable").filter(func(n): return n.data.kind == &"return_spot").size()))
	await _walk_right(1000)
	_log("locked exit holds: frame=" + str(fm.current_frame.data.id))
	await _say("arthur_push", 395)
	_log("push frame moved=" + str(gs.has_flag(&"gallery_frame_moved")))
	await _say("portrait_remember", 395)
	await _wait(0.6)
	await _shot("01_gallery_memory.png")
	await _at(765)
	await _tap("interact")
	await _wait(0.3)
	_log("dial ui modal=" + str(gs.modal_open))
	await _shot("02_gallery_dials.png")
	# Dials start on "house" (index 5 of 7): nib = 6 (up once), eye = 1 (up 3), hand = 3 (up 5).
	for a in ["move_up", "move_right", "move_up", "move_up", "move_up", "move_right", "move_up", "move_up", "move_up", "move_up", "move_up"]:
		await _tap(a)
	await _wait(1.2)
	_log("dials=" + str(gs.has_flag(&"gallery_dials")) + " modal=" + str(gs.modal_open))
	await _say("arthur_open", 1114)
	await _wait(0.4)
	_log("door open=" + str(gs.has_flag(&"gallery_open")))
	await _wait(1.6)
	if fm.current_frame.data.id == &"ch3_gallery_words":
		await _walk_right()

	# 3. Margin: run.
	_log("arrived")
	await _wait(1.8)
	Input.action_press("sprint")
	Input.action_press("move_right")
	for i in 40:
		await _wait(0.1)
		if fm.current_frame.data.id != &"ch3_margin":
			break
	Input.action_release("move_right")
	Input.action_release("sprint")
	await _wait(1.2)

	# 4. Ink Heart: sneak between listens, steal ERASE.
	_log("arrived enemy=" + STATES[_enemy().state] + " caught so far=" + str(caught[0]))
	await _shot("03_ink_heart.png")
	var heard_before: int = caught[0]
	for step in 160:
		var e = _enemy()
		var listening: bool = e.listening > 0.02 or e._ear != 0
		if player.global_position.x - 48 >= 850:
			break
		if listening:
			Input.action_release("move_right")
		else:
			Input.action_press("move_right")
		if step == 30:
			await _shot("04_listening.png")
		await _wait(0.1)
	Input.action_release("move_right")
	_log("under the word x=" + str(int(player.global_position.x - 48)) + " enemy=" + STATES[_enemy().state] + " caught=" + str(caught[0] - heard_before))
	await _hold(0.7)
	_log("stole ERASE=" + str(gs.is_bubble_stolen(&"hand_erase")) + " damage=" + str(gs.comic_damage) + " ratio=" + str(gs.damage_ratio()))

	# 5. The reveal.
	var marks: Array = [1.4, 3.6, 7.0, 9.5, 12.6, 14.8, 17.2, 20.5]
	var elapsed: float = 0.0
	for i in marks.size():
		await _wait(marks[i] - elapsed)
		elapsed = marks[i]
		await _shot("05_reveal_%d.png" % i)
	await _wait(4.0)
	_log("after reveal twist=" + str(gs.twist_revealed) + " paused=" + str(paused) + " restart frame=" + str(gs.chapter_start.get("frame")))

	# 6. Return phase: Returning Room.
	await _wait(0.6)
	var hand = _hand()
	_log("hand=" + (HAND[hand.state] if hand else "none") + " held_share=" + str(gs.held_share()))
	await _shot("06_returning_room.png")
	await _give("arthur_open", 365)
	await _shot("07_thank_you.png")
	await _give("arthur_push", 255)
	if not minimal:
		await _give("arthur_help", 865)
	await _wait(0.3)
	var pressure = load("res://data/hand/hand_pressure.tres")
	_log("hand interval now=" + str(snapped(pressure.interval(gs.held_share()), 0.01)) + " width=" + str(int(pressure.width(gs.held_share()))))
	await _walk_right()

	# 7. Torn Page again.
	_log("arrived")
	if not minimal:
		await _give("vane_hide", 280)
		await _give("vane_hush", 178)
		await _give("vane_wait", 670)
	await _give("portrait_remember", 770)
	_log("normal words held=" + str(gs.normal_words_held()) + " hand=" + (HAND[_hand().state] if _hand() else "none"))
	await _shot("08_torn_return.png")
	await _walk_right()

	# 8. Gallery: everyone whole -> gate open.
	await _wait(0.8)
	_log("arrived gate=" + str(gs.has_flag(&"gallery_open")))
	await _shot("09_gallery_return.png")
	await _walk_right()

	# 9. Ink Heart: ERASE back to the hand.
	await _wait(1.0)
	_log("arrived hand=" + (HAND[_hand().state] if _hand() else "none"))
	_select("hand_erase")
	await _at(860)
	await _wait(1.2)
	_log("offer: hand=" + HAND[_hand().state])
	await _shot("10_offer.png")
	await _hold(1.6)
	_log("ERASE returned=" + str(gs.is_bubble_returned(&"hand_erase")) + " repaired=" + str(gs.has_flag(&"comic_repaired")) + " damage=" + str(gs.comic_damage) + " words=" + str(gs.inventory.size()))
	await _wait(1.0)
	await _shot("11_repairing.png")
	await _wait(3.0)
	await _shot("12_repaired.png")
	await _walk_right()

	# 10. The Last Page, then out through the border.
	_log("arrived")
	await _wait(0.8)
	await _shot("13_last_page.png")
	await _walk_right(1060)
	_log("frame now (epilogue)")
	for t in [2.0, 3.5, 4.0, 4.0]:
		await _wait(t)
		await _shot("14_epilogue_%d.png" % int(t * 10))
	await _wait(3.0)
	await _shot("15_end_card.png")
	_log("end card visible=" + str(main.get_node("MenuLayer/EndCard").visible) + " save exists=" + str(FileAccess.file_exists("user://ink_bleed_save.json")) + " playing=" + str(gs.is_playing))
	_log("caught total=" + str(caught[0]))
	quit()
