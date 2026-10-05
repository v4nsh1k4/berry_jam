extends SceneTree
## Stage 4D gate test (dev, not exported): the Study lock (REMEMBER only
## shows the code; the door holds until the dials are solved; save/load),
## the Clock Room (read the face, wrong code "?", right code opens the way),
## the unified unlock feedback (captions), the Portrait Gallery lever, the
## cellar marker after reload / save-load, and the spread's door padlock.
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/gates_check.gd

var gs
var fm
var bus
var main
var player
var ok := true
var captions: Array = []
var unlocks: Array = []

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

func _check(label: String, cond: bool) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	ok = ok and cond

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _wait(0.06)
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _wait(0.1)

func _at(x: float) -> void:
	player.global_position = Vector2(48 + x, 32 + 466)
	await _wait(0.2)

func _select(text: String) -> void:
	for i in gs.inventory.size():
		if gs.inventory[i].text == text:
			gs.select(i, false)

func _go(frame: String) -> void:
	var ch = load("res://scripts/systems/debug_jump.gd").prepare(frame)
	main._start_chapter(ch, StringName(frame))
	await _wait(1.5)

## Sets the open lock UI's dials to `symbols` and presses TRY.
func _dial(symbols: Array) -> void:
	var ui = main.get_node("LockLayer/SymbolLockUI")
	var all: PackedStringArray = PackedStringArray(["moon", "eye", "key", "hand", "spiral", "house", "nib"])
	ui._dials.assign([all.find(symbols[0]), all.find(symbols[1]), all.find(symbols[2])])
	ui._try()
	await _wait(1.0)

func _run() -> void:
	gs = root.get_node("/root/GameState")
	fm = root.get_node("/root/FrameManager")
	bus = root.get_node("/root/EventBus")
	bus.cutscene_started.connect(func(_id): root.get_node("/root/CutsceneSystem").call_deferred("_finish"))
	bus.caption_requested.connect(func(t, _d): captions.append(t))
	bus.unlocked.connect(func(d, _p): unlocks.append(d.id))
	await _wait(0.3)
	main = current_scene
	bus.game_started.emit()
	main.get_node("MenuLayer/MainMenu").hide()
	player = main.get_node("World/Player")

	# --- Study (item 2) ---
	await _go("ch1_study")
	gs.add_bubble(load("res://data/bubbles/arthur_push.tres"))
	gs.add_bubble(load("res://data/bubbles/portrait_remember.tres"))
	_select("PUSH")
	await _at(780)
	await _tap("interact")
	await _wait(0.6)
	_select("REMEMBER")
	await _at(700)
	await _tap("interact")
	await _wait(0.8)
	await _shot("g_study_sketch.png")
	_check("REMEMBER shows the sketch but does not open the door", not gs.has_flag(&"study_lock_open"))
	_check("the sketch caption points at the lock", captions.any(func(c): return "lock" in c))
	await _at(1130)
	await _wait(1.0)
	_check("walking into the door without solving does not pass", fm.current_frame.data.id == &"ch1_study")
	var snap: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.from_dict(snap)
	fm.go_to(&"ch1_study")
	await _wait(1.0)
	await _at(1075)
	await _tap("interact")
	await _wait(0.3)
	_check("the dial UI opens (and pauses)", gs.modal_open and paused)
	await _dial(["moon", "moon", "moon"])
	_check("a wrong code gets '?' and keeps it shut", not gs.has_flag(&"study_lock_open") and main.get_node("LockLayer/SymbolLockUI")._wrong > 0.0)
	await _dial(["eye", "moon", "key"])
	_check("the right code opens it", gs.has_flag(&"study_lock_open") and not paused)
	_check("unlock feedback for the study door", unlocks.has(&"study_lock"))
	await _shot("g_study_open.png")
	await _at(1130)
	await _wait(2.4)
	_check("then the door lets the player through (after load too)", fm.current_frame.data.id == &"ch1_exit")

	# --- Clock Room (item 20) ---
	await _go("ch2_clock_room")
	var clock = null
	for n in fm.current_frame.get_node("Props").get_children():
		if n.get("data") is Resource and n.data.get("id") == &"grandfather_clock":
			clock = n
	_check("clock exit locked at first", not gs.has_flag(&"clock_solved"))
	gs.add_bubble(load("res://data/bubbles/vane_wait.tres"))
	_select("WAIT")
	await _at(600)
	await _tap("interact")
	await _wait(0.2)
	_check("WAIT froze the pendulum (marks steady)", clock.steady > 0.99)
	root.warp_mouse(Vector2(48 + 600, 32 + 136))
	root.get_node("/root/LightingSystem").set_light(true)
	await _wait(1.6)
	await _shot("g_clock_face.png")
	root.get_node("/root/LightingSystem").set_light(false)
	_check("reading the face does not open the door", gs.has_flag(&"clock_read") and not gs.has_flag(&"clock_solved"))
	await _wait(1.5)
	player.global_position = Vector2(48 + 745, 32 + 466)
	await _wait(0.2)
	await _tap("interact")
	await _wait(0.3)
	await _dial(["house", "hand", "spiral"])
	_check("left-to-right order is wrong", not gs.has_flag(&"clock_solved"))
	await _dial(["hand", "spiral", "house"])
	_check("clockwise from XII opens the way", gs.has_flag(&"clock_solved"))
	await _wait(0.4)
	_check("the opened exit announced itself", captions.any(func(c): return "door opened" in c.to_lower()))
	await _shot("g_clock_open.png")

	# --- Portrait Gallery lever (item 18) ---
	captions.clear()
	await _go("ch2_gallery")
	await _shot("g_gallery_locked.png")
	await _at(360)
	root.warp_mouse(Vector2(48 + 360, 32 + 320))
	root.get_node("/root/LightingSystem").set_light(true)
	await _wait(0.8)
	await _tap("interact")
	await _wait(1.0)
	root.get_node("/root/LightingSystem").set_light(false)
	_check("lever pulled -> 'The door opened!'", gs.has_flag(&"gallery_lever") and captions.any(func(c): return "door opened" in c.to_lower()))
	await _wait(0.6)
	await _shot("g_gallery_open.png")
	fm.go_to(&"ch2_gallery")
	await _wait(1.0)
	await _shot("g_gallery_revisit.png")

	# --- Cellar marker (item 8) ---
	await _go("ch2_cellar")
	gs.set_flag(&"cellar_dials_set")
	fm.go_to(&"ch2_cellar")
	await _wait(1.0)
	var shadow = null
	var door = null
	for n in fm.current_frame.get_node("Props").get_children():
		if n.get("data") is Resource and n.data.get("id") == &"cellar_shadow":
			shadow = n
		if n.get("data") is Resource and n.data.get("id") == &"cellar_door":
			door = n
	_check("cellar: shadow marker shown on reload (light off)", shadow.resolved)
	root.get_node("/root/LightingSystem").set_light(true)
	await _wait(0.4)
	_check("cellar: still shown with light on", shadow.resolved)
	root.get_node("/root/LightingSystem").set_light(false)
	var cs: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.from_dict(cs)
	fm.go_to(&"ch2_cellar")
	await _wait(1.0)
	for n in fm.current_frame.get_node("Props").get_children():
		if n.get("data") is Resource and n.data.get("id") == &"cellar_shadow":
			shadow = n
	_check("cellar: shown after save/load", shadow.resolved)
	await _shot("g_cellar_done.png")

	# --- Spread door padlock (item 22) ---
	await _go("ch3_gallery_words")
	await _shot("g_spread_locked.png")
	unlocks.clear()
	gs.set_flag(&"spread_lens")
	gs.set_flag(&"spread_lever")
	await _wait(1.2)
	_check("spread: the door's padlock drops when the lever is pulled", unlocks.has(&"spread_door"))
	await _shot("g_spread_unbolted.png")
	print("GATES TEST ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
