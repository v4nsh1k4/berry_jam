extends Control
## Title page with Start / Continue / Controls / Credits.

var _pages: Dictionary = {}
var _continue_button: Button
## The credits page's comic drawing (CreditsArt), redrawn with the line boil.
var _credits_art: Control
var _title: Control


func _ready() -> void:
	UiTheme.make_screen(self)
	_pages["main"] = _build_main().get_parent()
	_pages["controls"] = _build_controls_page().get_parent()
	_pages["credits"] = _build_credits_page().get_parent()
	EventBus.returned_to_menu.connect(open)
	hide()


func open() -> void:
	_continue_button.visible = SaveSystem.has_save()
	show()
	_show_page("main")


## The crows backdrop (TitleArt, built by the start screen) on every page.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), InkDraw.WHITE)
	TitleLive.draw(self, size, InkDraw.boil_tick())


func _process(_delta: float) -> void:
	queue_redraw()
	_title.queue_redraw()
	if _credits_art.is_visible_in_tree():
		_credits_art.queue_redraw()


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
	# The scrawled title (TitleLettering), then room for the red figure.
	var title: Control = Control.new()
	title.custom_minimum_size = Vector2(900, 170)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.draw.connect(func() -> void: TitleLive.title(title, Vector2(450, 92), InkDraw.boil_tick()))
	title.set_process(true)
	_title = title
	box.add_child(title)
	box.add_child(_spacer(150))
	_continue_button = UiTheme.make_button("Continue", _on_continue)
	for b in [UiTheme.make_button("Start", _on_start), _continue_button, UiTheme.make_button("Controls", _show_page.bind("controls")),
			UiTheme.make_button("Credits", _show_page.bind("credits"))]:
		(b as Button).custom_minimum_size.x = 340
		(b as Button).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(b)
	return box


func _build_controls_page() -> Control:
	var box: VBoxContainer = _centered_column()
	box.add_child(UiTheme.make_label("CONTROLS", 48))
	box.add_child(ControlsCard.grid())
	box.add_child(UiTheme.make_button("Back", _show_page.bind("main")))
	return box


## Credits: one black-and-white comic page (fits 1280x720, no scrolling).
func _build_credits_page() -> Control:
	var box: VBoxContainer = _centered_column()
	_credits_art = Control.new()
	_credits_art.custom_minimum_size = Vector2(1130, 566)
	_credits_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits_art.draw.connect(func() -> void:
		CreditsArt.page(_credits_art, Rect2(Vector2.ZERO, _credits_art.size), CreditsArt.TITLE, InkDraw.boil_tick()))
	box.add_child(_credits_art)
	var back: Button = UiTheme.make_button("Back", _show_page.bind("main"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(back)
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
