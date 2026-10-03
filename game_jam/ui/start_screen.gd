extends Control
## "Click to start" page. Browsers only allow audio and full input after a
## user gesture, so the game waits for a click or a key press.

var _time: float = 0.0
var _started: bool = false


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
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(r, InkDraw.WHITE)
	var tick: int = InkDraw.boil_tick()
	var cover: Rect2 = r.grow(-48)
	InkDraw.rect(self, cover, 8.0, tick, InkDraw.PAPER, InkDraw.INK, 2.0)
	InkDraw.hatch(self, Rect2(cover.position.x + 8, cover.end.y - 150, cover.size.x - 16, 142), 12.0, 1.4, tick + 3)

	var font: Font = ThemeDB.fallback_font
	var center_x: float = r.size.x * 0.5
	_centered(font, "INK-BLEED", Vector2(center_x, 280), 96, InkDraw.INK)
	_centered(font, "The Silent House of Hollow Hill", Vector2(center_x, 340), 26, InkDraw.INK)
	var alpha: float = 0.55 + 0.45 * sin(_time * 3.0)
	_centered(font, "- click or press any key -", Vector2(center_x, 470), 24, Color(InkDraw.INK, alpha))


func _centered(font: Font, text: String, baseline_center: Vector2, font_size: int, color: Color) -> void:
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos: Vector2 = baseline_center - Vector2(w * 0.5, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, InkDraw.WHITE)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
