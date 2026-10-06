extends SceneTree
## Scripted playthrough (dev test, not exported). Run from the repo root:
##   godot --path . --resolution 1280x720 --script res://tests/playthroughs/menu_clicks.gd
## Screenshots go to $SHOT_DIR (default: the user data folder). Prints a log.

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	_run.call_deferred()

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _click(pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	Input.parse_input_event(down)
	await _wait(0.05)
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await _wait(0.2)

func _run() -> void:
	await _wait(0.3)
	await _click(Vector2(640, 360))
	var menu = current_scene.get_node("MenuLayer/MainMenu")
	print("menu visible after title click: ", menu.visible)
	var hovered = root.gui_get_hovered_control() if root.has_method("gui_get_hovered_control") else null
	for b in menu.find_children("*", "Button", true, false):
		if b.is_visible_in_tree():
			print("button ", b.text, " rect=", b.get_global_rect())
	var start_btn: Button = null
	for b in menu.find_children("*", "Button", true, false):
		if b.text == "Controls":
			start_btn = b
	var c: Vector2 = start_btn.get_global_rect().get_center()
	await _click(c)
	var ctrl_page_visible := false
	for l in menu.find_children("*", "Label", true, false):
		if l.text == "CONTROLS" and l.is_visible_in_tree():
			ctrl_page_visible = true
	print("controls page opened by click: ", ctrl_page_visible)
	var top = root.gui_get_hovered_control() if root.has_method("gui_get_hovered_control") else "n/a"
	print("hovered control: ", top, " path=", top.get_path() if top is Node else "")
	# Stage 7: About opens by a click; its Back (click) and Esc both return.
	menu._show_page("main")
	await _wait(0.3)
	var about_btn: Button = null
	for b in menu.find_children("*", "Button", true, false):
		if b.text == "About" and b.is_visible_in_tree():
			about_btn = b
	print("about button rect=", about_btn.get_global_rect() if about_btn != null else "missing")
	await _click(about_btn.get_global_rect().get_center())
	var about_open: bool = menu._pages["about"].visible and not menu._pages["main"].visible
	var back: Button = menu._first_button(menu._pages["about"])
	await _click(back.get_global_rect().get_center())
	var back_ok: bool = menu._pages["main"].visible and not menu._pages["about"].visible
	await _click(about_btn.get_global_rect().get_center())
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _wait(0.3)
	var esc_ok: bool = menu._pages["main"].visible and not menu._pages["about"].visible
	# No spoilers: the twist's words never appear on the page.
	var text: String = load("res://ui/about_art.gd").TEXT.to_lower()
	var spoilers: Array = []
	for word in ["artist", "author", "hand", "erase", "give back", "giving", "monster", "return"]:
		if text.contains(word):
			spoilers.append(word)
	print("about page opened by click: ", about_open, ", Back click returns: ", back_ok, ", Esc returns: ", esc_ok, ", spoiler words: ", spoilers)
	print("MENU CLICKS ", "PASSED" if ctrl_page_visible and about_open and back_ok and esc_ok and spoilers.is_empty() else "FAILED")
	quit()
