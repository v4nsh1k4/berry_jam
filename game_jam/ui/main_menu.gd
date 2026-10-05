extends Control
## Title page with Start / Continue / Controls / Credits.

const CREDITS_TEXT: String = """INK-BLEED
Made for the Infinium 26 game jam by the Berry Jam team.

Code, art and sound are made in Godot from code: no assets,
no addons. Font: Godot's built-in default font."""

var _pages: Dictionary = {}
var _continue_button: Button


func _ready() -> void:
	UiTheme.make_screen(self)
	_pages["main"] = _build_main().get_parent()
	_pages["controls"] = _build_controls_page().get_parent()
	_pages["credits"] = _build_text_page("CREDITS", CREDITS_TEXT).get_parent()
	EventBus.returned_to_menu.connect(open)
	hide()


func open() -> void:
	_continue_button.visible = SaveSystem.has_save()
	show()
	_show_page("main")


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(r, InkDraw.WHITE)
	var tick: int = InkDraw.boil_tick()
	InkDraw.rect(self, r.grow(-48), 8.0, tick, InkDraw.PAPER, InkDraw.INK, 2.0)
	InkDraw.hatch(self, Rect2(56, size.y - 150, size.x - 112, 94), 12.0, 1.4, tick + 3)


func _process(_delta: float) -> void:
	queue_redraw()


## Pages are full-screen wrappers; only the shown one is visible, so a
## hidden page can never sit on top and swallow clicks.
func _show_page(page_name: String) -> void:
	for key in _pages:
		(_pages[key] as Control).visible = key == page_name
	var first: Button = _first_button(_pages[page_name])
	if first != null:
		first.grab_focus()


## Esc / Backspace on a sub-page goes back to the main page.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or (_pages["main"] as Control).visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_show_page("main")
		get_viewport().set_input_as_handled()


func _first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and (child as Button).visible:
			return child
		var found: Button = _first_button(child)
		if found != null:
			return found
	return null


func _build_main() -> Control:
	var box: VBoxContainer = _centered_column()
	box.add_child(UiTheme.make_label("INK-BLEED", 84))
	box.add_child(UiTheme.make_label("The Silent House of Hollow Hill", 24))
	box.add_child(_spacer(26))
	box.add_child(UiTheme.make_button("Start", _on_start))
	_continue_button = UiTheme.make_button("Continue", _on_continue)
	box.add_child(_continue_button)
	box.add_child(UiTheme.make_button("Controls", _show_page.bind("controls")))
	box.add_child(UiTheme.make_button("Credits", _show_page.bind("credits")))
	return box


func _build_controls_page() -> Control:
	var box: VBoxContainer = _centered_column()
	box.add_child(UiTheme.make_label("CONTROLS", 48))
	box.add_child(ControlsCard.grid())
	box.add_child(UiTheme.make_button("Back", _show_page.bind("main")))
	return box


func _build_text_page(title: String, body: String) -> Control:
	var box: VBoxContainer = _centered_column()
	box.add_child(UiTheme.make_label(title, 48))
	var panel: PanelContainer = PanelContainer.new()
	var text: Label = UiTheme.make_label(body, 19, HORIZONTAL_ALIGNMENT_LEFT)
	panel.add_child(text)
	box.add_child(panel)
	box.add_child(UiTheme.make_button("Back", _show_page.bind("main")))
	return box


func _centered_column() -> VBoxContainer:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	return box


func _spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


func _on_start() -> void:
	hide()
	EventBus.menu_new_game.emit()


func _on_continue() -> void:
	hide()
	EventBus.menu_continue.emit()
