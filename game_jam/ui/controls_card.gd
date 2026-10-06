class_name ControlsCard
extends Control
## The controls, as a comic page with an OK button. A new game shows it
## before anything starts and waits for OK (click, Enter or Space); the main
## menu's and pause menu's Controls pages use the same text. Continue never
## shows it. Stage 6b: F1 or H opens it any time while playing (not in a
## cutscene, transition or another modal): it pauses like the pause menu and
## closes with F1 / H, Esc or OK, restoring the paused / modal state it found
## (and never emits `accepted`, which only New Game waits on).

signal accepted

## "keys | what they do" per line (plain text: typed constant arrays of
## packed arrays read back empty in exported builds).
const TEXT: String = """A / D, arrow keys | walk left / right
W / S | step nearer / further
Shift | run (loud: it can hear you, so walk near it)
Space, W / Up | jump (on the page spread)
E | say the selected word; use doors, locks and hiding spots
Hold E | steal a word / give a word back
1 - 6, Q / R, wheel | pick the word E says (or click the strip's arrows)
Shift + Q / R, drag | reorder your words
F, left click | flashlight, aimed with the mouse
The light | draws it: the NOTICED blot fills; full means it hunts you
To be safe | light off and stand still: the blot drains
F1, H | these controls, any time
Esc, P | pause
Tips | the text at the bottom right of the screen"""
## Column widths of the grid (Stage 7: fixed, so every row lines up and a long
## description wraps under its own column instead of widening the page).
const KEY_WIDTH: float = 250.0
const TEXT_WIDTH: float = 600.0

var _ok: Button
var _page: Control
var _in_game: bool = false
var _was_paused: bool = false
var _was_modal: bool = false


func _ready() -> void:
	UiTheme.make_screen(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_ok = UiTheme.make_button("OK", _accept)
	_page = page("HOW TO PLAY", _ok)
	center.add_child(_page)
	_page.item_rect_changed.connect(queue_redraw)
	EventBus.frame_changed.connect(func(_d: FrameData) -> void:
		if GameState.is_playing:
			Hints.once("f1_controls", "F1 or H: see the controls again, any time.", 5.0))
	hide()


## The controls as one comic page (paper, ink border, shadow): the title,
## the grid and `button` (OK / Back), sized to its content. Used by this
## card, the main menu's Controls page and the pause menu's.
static func page(title: String, button: Button) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(UiTheme.make_label(title, 40))
	box.add_child(grid())
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	panel.add_child(box)
	return panel


## The two-column key / action grid: fixed column widths, both columns
## top-aligned, descriptions wrapping inside their own column.
static func grid() -> GridContainer:
	var g: GridContainer = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 5)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for line in TEXT.split("\n"):
		var parts: PackedStringArray = line.split("|")
		var key: Label = _cell(parts[0].strip_edges(), KEY_WIDTH)
		key.add_theme_color_override("font_color", InkDraw.RED)
		g.add_child(key)
		g.add_child(_cell(parts[1].strip_edges() if parts.size() > 1 else "", TEXT_WIDTH))
	return g


static func _cell(text: String, width: float) -> Label:
	var label: Label = UiTheme.make_label(text, 19, HORIZONTAL_ALIGNMENT_LEFT)
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func open() -> void:
	show()
	_ok.grab_focus()


## Mid-game (F1 / H): pauses like the pause menu.
func open_in_game() -> void:
	if visible:
		return
	_in_game = true
	_was_paused = get_tree().paused
	_was_modal = GameState.modal_open
	get_tree().paused = true
	GameState.modal_open = true
	open()


static func _is_controls_key(event: InputEvent) -> bool:
	var key: InputEventKey = event as InputEventKey
	return key != null and key.pressed and not key.echo and (key.keycode == KEY_F1 or key.keycode == KEY_H)


func _accept() -> void:
	if not visible:
		return
	hide()
	if _in_game:
		_in_game = false
		get_tree().paused = _was_paused
		GameState.modal_open = _was_modal
		return
	accepted.emit()


func _unhandled_input(event: InputEvent) -> void:
	var closing: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")
	closing = closing or (_in_game and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or _is_controls_key(event)))
	if visible and closing:
		get_viewport().set_input_as_handled()
		_accept()
	elif not visible and _is_controls_key(event) and GameState.is_playing and not GameState.modal_open \
			and not get_tree().paused and not CutsceneSystem.is_playing and not TransitionManager.is_playing:
		get_viewport().set_input_as_handled()
		open_in_game()


func _draw() -> void:
	# A dark desk, a white gutter round the page (the page is page()'s panel,
	# so its ink border reads on the dark).
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.06, 0.08))
	draw_rect(_page.get_global_rect().grow(10.0), InkDraw.WHITE)
