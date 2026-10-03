extends Control
## Text-only intro: chapter captions one at a time on a dark page. Click,
## Space or E advances; each line also moves on by itself.
## (A New Game plays IntroCinematic first, then these captions for Chapter 1.)

const AUTO_ADVANCE: float = 4.5

var _lines: PackedStringArray = PackedStringArray()
var _title: String = ""
var _index: int = -1
var _alpha: float = 0.0
var _time_on_line: float = 0.0


func _ready() -> void:
	UiTheme.make_screen(self)
	hide()


func play(chapter: ChapterData) -> void:
	_lines = chapter.intro_lines
	_title = chapter.title
	_index = -1
	show()
	_next()


func _next() -> void:
	_index += 1
	_time_on_line = 0.0
	if _index >= _lines.size():
		hide()
		EventBus.intro_finished.emit()
		return
	_alpha = 0.0
	create_tween().tween_property(self, "_alpha", 1.0, 0.6)


func _process(delta: float) -> void:
	if not visible:
		return
	_time_on_line += delta
	if _time_on_line > AUTO_ADVANCE:
		_next()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_next()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")):
		_next()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.06, 0.08))
	if _index < 0 or _index >= _lines.size():
		return
	var font: Font = ThemeDB.fallback_font
	var tick: int = InkDraw.boil_tick()
	var tw: float = font.get_string_size(_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, Vector2(size.x * 0.5 - tw * 0.5, 90), _title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(InkDraw.PAPER, 0.7))
	var line: String = _lines[_index]
	var text_size: Vector2 = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	var box: Rect2 = Rect2(size * 0.5 - text_size * 0.5 - Vector2(30, 20), text_size + Vector2(60, 40))
	InkDraw.rect(self, box, 4.0, tick, Color(InkDraw.PAPER, _alpha), Color(InkDraw.INK, _alpha))
	draw_string(font, box.position + Vector2(30, 20 + font.get_ascent(28)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(InkDraw.INK, _alpha))
	var hint: String = "click / space"
	draw_string(font, Vector2(size.x - 170, size.y - 40), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(InkDraw.PAPER, 0.5))
