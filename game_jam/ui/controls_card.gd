class_name ControlsCard
extends Control
## The controls, as a comic page with an OK button. A new game shows it
## before anything starts and waits for OK (click, Enter or Space); the main
## menu's Controls page uses the same text. Continue never shows it.

signal accepted

## "keys | what they do" per line (plain text: typed constant arrays of
## packed arrays read back empty in exported builds).
const TEXT: String = """A / D  or  arrows | move
W / S | step nearer / further
Shift | run (loud: it can hear you)
Space  (W / Up) | jump (on the page spread)
E | interact: doors, locks, hiding spots, say the selected word
Hold E | steal a word / give a word back
Q / R  or  wheel | cycle your words (1 - 6 picks one)
Shift + Q / R  or  drag | reorder your words
F  or  left click | flashlight, aimed with the mouse
Esc  or  P | pause"""

var _ok: Button


func _ready() -> void:
	UiTheme.make_screen(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	box.add_child(UiTheme.make_label("HOW TO PLAY", 44))
	box.add_child(grid())
	_ok = UiTheme.make_button("OK", _accept)
	box.add_child(_ok)
	hide()


## The two-column key / action grid (also used by the main menu).
static func grid() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var g: GridContainer = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 28)
	g.add_theme_constant_override("v_separation", 6)
	for line in TEXT.split("\n"):
		var parts: PackedStringArray = line.split("|")
		var key: Label = UiTheme.make_label(parts[0].strip_edges(), 19, HORIZONTAL_ALIGNMENT_LEFT)
		key.add_theme_color_override("font_color", InkDraw.RED)
		g.add_child(key)
		g.add_child(UiTheme.make_label(parts[1].strip_edges() if parts.size() > 1 else "", 19, HORIZONTAL_ALIGNMENT_LEFT))
	panel.add_child(g)
	return panel


func open() -> void:
	show()
	_ok.grab_focus()


func _accept() -> void:
	if not visible:
		return
	hide()
	accepted.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")):
		get_viewport().set_input_as_handled()
		_accept()


func _draw() -> void:
	# A comic page behind the buttons: paper, a heavy border, speed lines.
	var tick: int = InkDraw.boil_tick()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.06, 0.08))
	var page: Rect2 = Rect2(Vector2(150, 40), size - Vector2(300, 80))
	InkDraw.rect(self, page, 8.0, tick, InkDraw.PAPER)
	for i in 10:
		var y: float = page.position.y + 30 + i * 62
		InkDraw.line(self, Vector2(page.position.x + 16, y), Vector2(page.position.x + 70, y + 6), 2.0, tick + i, Color(InkDraw.INK, 0.25))
		InkDraw.line(self, Vector2(page.end.x - 70, y), Vector2(page.end.x - 16, y + 6), 2.0, tick + 20 + i, Color(InkDraw.INK, 0.25))
