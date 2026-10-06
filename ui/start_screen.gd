extends Control
## "Click to start" page. Browsers only allow audio and full input after a
## user gesture, so the game waits for a click or a key press.
## Stage 6: the crows backdrop (TitleArt, inked into a texture over the first
## frames, owned here and shared with the menu) and the scrawled title.

var _time: float = 0.0
var _started: bool = false


func _ready() -> void:
	add_child(TitleArt.new())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		accept_event()
		_start()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and (event as InputEventKey).pressed and not event.is_echo():
		get_viewport().set_input_as_handled()
		_start()


func _start() -> void:
	if _started:
		return
	_started = true
	EventBus.game_started.emit()


func _draw() -> void:
	var tick: int = InkDraw.boil_tick()
	TitleLive.draw(self, size, tick)
	TitleLive.title(self, Vector2(size.x * 0.5, 150), tick)
	var font: Font = ThemeDB.fallback_font
	var alpha: float = 0.55 + 0.45 * sin(_time * 3.0)
	_centered(font, "- click or press any key -", Vector2(size.x * 0.5, 684), 22, Color(InkDraw.INK, alpha))


func _centered(font: Font, text: String, baseline_center: Vector2, font_size: int, color: Color) -> void:
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos: Vector2 = baseline_center - Vector2(w * 0.5, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(InkDraw.PAPER, 0.8))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
