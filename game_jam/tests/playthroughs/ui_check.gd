extends SceneTree
## Stage 4D UI screenshots (dev, not exported): controls card, chapter title
## card, doodles, word tooltip / selected line / x2 badge, the noticed meter's
## icons, and the final room's hand with its pencil.
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/ui_check.gd

var gs
var fm
var bus
var main
var player

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

func _find_hand() -> Node:
	for n in root.get_tree().get_nodes_in_group(&"freezable"):
		if n.get_script() != null and String(n.get_script().resource_path).ends_with("artist_hand.gd"):
			return n
	return null

func _go(frame: String) -> void:
	var ch = load("res://scripts/systems/debug_jump.gd").prepare(frame)
	main._start_chapter(ch, StringName(frame))
	await _wait(1.5)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	await _wait(0.3)
	main = current_scene
	# Stage 6: the crows backdrop inks in over the first frames (a hidden test
	# window doesn't draw on its own, so force the draws here).
	var title_art = load("res://ui/title_art.gd")
	var f0: int = Time.get_ticks_msec()
	var frames := 0
	while not title_art.done and frames < 400:
		RenderingServer.force_draw(false)
		await process_frame
		frames += 1
	print("title backdrop inked over %d frames (%d ms), done=%s" % [frames, Time.get_ticks_msec() - f0, title_art.done])
	await _wait(0.5)
	await _shot("ui_start.png")
	bus.game_started.emit()
	# Stage 6: the menu, its comic Credits page; Esc and a click on Back return.
	var menu = main.get_node("MenuLayer/MainMenu")
	menu.open()
	await _wait(1.2)
	await _shot("ui_menu.png")
	menu._show_page("controls")
	await _wait(0.3)
	await _shot("ui_menu_controls.png")
	menu._show_page("credits")
	await _wait(0.4)
	await _shot("ui_credits_menu.png")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _wait(0.3)
	var esc_ok: bool = menu._pages["main"].visible and not menu._pages["credits"].visible
	menu._show_page("credits")
	await _wait(0.3)
	var back: Button = menu._first_button(menu._pages["credits"])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = back.get_global_rect().get_center()
	click.global_position = click.position
	click.pressed = true
	Input.parse_input_event(click)
	var up: InputEventMouseButton = click.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await _wait(0.3)
	var click_ok: bool = menu._pages["main"].visible
	print("credits: Esc back=", esc_ok, " click Back=", click_ok, " back button at ", back.get_global_rect())
	main.get_node("MenuLayer/MainMenu").hide()
	bus.menu_new_game.emit()
	await _wait(0.4)
	await _shot("ui_controls.png")
	print("controls card visible=", main.get_node("MenuLayer/ControlsCard").visible)
	main.get_node("MenuLayer/ControlsCard").call("_accept")
	main.get_node("MenuLayer/IntroCinematic").call("_finish")
	await _wait(0.8)
	await _shot("ui_title.png")
	await _wait(2.5)
	await _shot("ui_awakening.png")
	player = main.get_node("World/Player")
	# Stage 6: the mirror ghoul (E on the mirror). Never blocks input; the
	# second look is shorter.
	var mirror: Node = null
	for n in get_nodes_in_group(&"interactable"):
		if n.get("data") != null and n.data.id == &"mirror":
			mirror = n
	var ghoul: Node = null
	for n in fm.current_frame.get_node("Props").get_children():
		if n.get_script() != null and String(n.get_script().resource_path).ends_with("mirror_ghoul_event.gd"):
			ghoul = n
	player.global_position.x = 48 + 640
	await _wait(0.3)
	mirror.interact_plain()
	var free := true
	for at in [0.5, 1.2, 2.0]:
		await _wait(at - (0.0 if at == 0.5 else [0.5, 1.2, 2.0][[0.5, 1.2, 2.0].find(at) - 1]))
		free = free and player.can_act()
		await _shot("ui_ghoul_%.1f.png" % at)
	var full_len: float = ghoul._length
	await _wait(1.5)
	mirror.interact_plain()
	await _wait(0.1)
	print("ghoul: full %.1f s, then %.1f s; sound %s; input free %s; seen %s" % [full_len, ghoul._length,
		root.get_node("/root/AudioManager").last_played, free, gs.seen.has(&"mirror_ghoul")])
	await _wait(1.6)
	for w in ["arthur_open", "arthur_wait", "vane_wait", "portrait_remember"]:
		gs.add_bubble(load("res://data/bubbles/%s.tres" % w))
	await _wait(0.8)
	var strip = main.get_node("HUDLayer/InventoryStrip")
	var motion := InputEventMouseMotion.new()
	motion.position = strip.get_global_transform() * strip._slot_rect(1).get_center()
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await _wait(0.4)
	print("hover slot=", strip._hover_slot)
	await _shot("ui_tooltip.png")
	print("words=", gs.inventory.size())
	root.warp_mouse(Vector2(640, 200))
	await _go("ch2_clock_room")
	root.warp_mouse(Vector2(48 + 600, 32 + 140))
	root.get_node("/root/LightingSystem").set_light(true)
	await _wait(1.2)
	await _shot("ui_meter.png")
	root.get_node("/root/LightingSystem").set_light(false)
	# Stage 6: webs and watching eyes in some rooms (dark, then the torch on them).
	for room in ["ch2_servants_passage", "ch2_cellar", "ch1_bedchamber"]:
		await _go(room)
		var decor: Node = null
		for n in fm.current_frame.get_node("Props").get_children():
			if n.get_script() != null and String(n.get_script().resource_path).ends_with("room_decor.gd"):
				decor = n
		print("decor in %s: webs %d, eyes %d, lights %d" % [room, decor._webs.size(), decor._eyes.size(), decor.get_child_count()])
		await _shot("ui_decor_%s.png" % room)
		player.global_position.x = 48 + (950 if room != "ch1_bedchamber" else 260)
		root.get_node("/root/LightingSystem").set_light(true)
		root.warp_mouse(Vector2(48 + (1150 if room != "ch1_bedchamber" else 40), 32 + 40))
		await _wait(0.6)
		await _shot("ui_decor_%s_lit.png" % room)
		root.get_node("/root/LightingSystem").set_light(false)
	# Stage 6: the return-phase hand holds the ERASER end in every state.
	await _go("ch3_returning_room")
	var hand = _find_hand()
	player.global_position.x = 48 + 1000
	hand.set("_wrist", Vector2(500, -30))
	await _wait(0.6)
	await _shot("ui_hand_hover.png")
	for st in [[1, "aim", 1.2], [2, "rub", 0.5], [3, "lift", 0.6]]:
		hand.set("_target_x", 420.0)
		hand.set("_width", 200.0)
		hand.call("_set_state", st[0], st[2])
		await _wait(st[2] * 0.55)
		print("hand state=", hand.state, " tool tip=", hand.get_global_transform_with_canvas() * (hand._wrist + Vector2(-0.6, 0.8) * 300.0 * 0.94))
		await _shot("ui_hand_%s.png" % st[1])
	await _go("ch3_heart_return")
	await _wait(1.0)
	hand = _find_hand()
	for i in range(gs.inventory.size() - 1, -1, -1):
		if not gs.inventory[i].story_final:
			gs.inventory.remove_at(i)
	gs.selected_index = 0
	hand.state = 4
	await _wait(1.0)
	print("heart hand state=", hand.state)
	await _shot("ui_hand_watch.png")
	player = main.get_node("World/Player")
	player.global_position.x = 48 + 860 - 120
	await _wait(1.6)
	print("offer state=", hand.state, " grip=", hand._grip)
	await _shot("ui_hand_offer.png")
	var ec = main.get_node("MenuLayer/EndCard")
	ec._text = "THE END"
	ec._credits = true
	gs.modal_open = true
	ec._appear()
	await _wait(1.2)
	await _shot("ui_credits_end.png")
	Input.parse_input_event(esc)
	await _wait(0.4)
	print("end card: Esc closes=", not ec.visible)
	print("frame=", fm.current_frame.data.id if fm.current_frame != null else "(menu)", " paused=", paused, " modal=", gs.modal_open)
	print("UI CHECK DONE")
	quit()
