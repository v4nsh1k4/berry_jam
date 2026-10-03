extends SceneTree
## Scripted playthrough (dev test, not exported). Run from game_jam/:
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
	quit()
