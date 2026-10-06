extends Control
## End card, shown when a frame with `ending_card` loads: the card text, then
## (after an epilogue) the credits, and Back to Menu. A frame marked
## `epilogue` waits for the epilogue to finish first.

var _text: String = ""
var _credits: bool = false
var _button: Button


func _ready() -> void:
	UiTheme.make_screen(self)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.position.y = 250
	add_child(center)
	_button = UiTheme.make_button("Back to Menu", _on_back)
	center.add_child(_button)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.epilogue_finished.connect(_appear)
	EventBus.returned_to_menu.connect(hide)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	if data.ending_card == "":
		return
	_text = data.ending_card
	_credits = data.epilogue
	GameState.modal_open = true
	if data.epilogue:
		return
	# Let the panel be seen for a beat before the card drops in.
	await get_tree().create_timer(1.2).timeout
	_appear()


func _appear() -> void:
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
	_button.grab_focus()


## Esc on the end card works like Back to Menu.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _on_back() -> void:
	hide()
	EventBus.quit_to_menu_requested.emit()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5) if not _credits else InkDraw.WHITE)
	var font: Font = ThemeDB.fallback_font
	var tick: int = InkDraw.boil_tick()
	if _credits:
		# After the epilogue: THE END heads the comic credits page (CreditsArt).
		CreditsArt.page(self, Rect2(70, 34, size.x - 140, 540), _text, tick)
		return
	var text_size: Vector2 = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54)
	var top: float = 140.0 if _credits else size.y * 0.5 - 140.0
	var box: Rect2 = Rect2(Vector2(size.x * 0.5 - text_size.x * 0.5 - 50, top), Vector2(text_size.x + 100, 150))
	InkDraw.rect(self, box.grow(10), 3.0, tick, InkDraw.INK)
	InkDraw.rect(self, box, 6.0, tick + 1, InkDraw.WHITE)
	var baseline: Vector2 = box.position + Vector2(50, 75 + font.get_ascent(54) * 0.4)
	draw_string_outline(font, baseline, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, 4, InkDraw.INK)
	draw_string(font, baseline, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, InkDraw.INK)
