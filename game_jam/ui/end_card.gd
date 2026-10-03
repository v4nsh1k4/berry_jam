extends Control
## "Chapter 2: coming soon" card, shown when a frame with ending_card loads.

var _text: String = ""
var _button: Button


func _ready() -> void:
	UiTheme.make_screen(self)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.position.y = 150
	add_child(center)
	_button = UiTheme.make_button("Back to Menu", _on_back)
	center.add_child(_button)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(hide)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	if data.ending_card == "":
		return
	_text = data.ending_card
	GameState.modal_open = true
	# Let the panel be seen for a beat before the card drops in.
	await get_tree().create_timer(1.2).timeout
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	_button.grab_focus()


func _on_back() -> void:
	hide()
	EventBus.quit_to_menu_requested.emit()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
	var font: Font = ThemeDB.fallback_font
	var tick: int = InkDraw.boil_tick()
	var text_size: Vector2 = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54)
	var box: Rect2 = Rect2(size * 0.5 - Vector2(text_size.x * 0.5 + 50, 140), Vector2(text_size.x + 100, 150))
	InkDraw.rect(self, box.grow(10), 3.0, tick, InkDraw.INK)
	InkDraw.rect(self, box, 6.0, tick + 1, InkDraw.WHITE)
	var baseline: Vector2 = box.position + Vector2(50, 75 + font.get_ascent(54) * 0.4)
	draw_string_outline(font, baseline, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, 4, InkDraw.INK)
	draw_string(font, baseline, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, InkDraw.INK)
	var sub: String = "Thanks for playing Chapter 1."
	var sw: float = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(font, Vector2(size.x * 0.5 - sw * 0.5, box.end.y + 40), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, InkDraw.WHITE)
