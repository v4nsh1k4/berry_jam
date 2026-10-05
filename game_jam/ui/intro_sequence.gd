extends Control
## The chapter title card: "CHAPTER 2: THE HALLWAY OF SHADOWS" on a dark page,
## held HOLD seconds, skippable (click, Space or E). Shown once per chapter
## start (New Game after the cinematic, and each chapter hand-off), never on a
## room reload or Continue. (ChapterData.intro_lines are no longer shown.)

const HOLD: float = 2.5

var _title: String = ""
var _t: float = -1.0


func _ready() -> void:
	UiTheme.make_screen(self)
	hide()


func play(chapter: ChapterData) -> void:
	_title = chapter.title.to_upper()
	_t = 0.0
	show()


func _next() -> void:
	if _t < 0.0:
		return
	_t = -1.0
	hide()
	EventBus.intro_finished.emit()


func _process(delta: float) -> void:
	if not visible or _t < 0.0:
		return
	_t += delta
	if _t > HOLD:
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
	if _t < 0.0:
		return
	var a: float = clampf(_t / 0.4, 0.0, 1.0) * clampf((HOLD - _t) / 0.3 + 0.2, 0.0, 1.0)
	var font: Font = ThemeDB.fallback_font
	var tick: int = InkDraw.boil_tick()
	var parts: PackedStringArray = _title.split(":", true, 1)
	var head: String = parts[0]
	var name: String = parts[1].strip_edges() if parts.size() > 1 else ""
	var w: float = maxf(font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x, 400.0)
	var box: Rect2 = Rect2(size * 0.5 - Vector2(w * 0.5 + 50, 90), Vector2(w + 100, 180))
	InkDraw.rect(self, box, 6.0, tick, Color(InkDraw.PAPER, a), Color(InkDraw.INK, a))
	var hw: float = font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string(font, Vector2(size.x * 0.5 - hw * 0.5, box.position.y + 52), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(InkDraw.INK, 0.7 * a))
	var nw: float = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
	BubbleArt.draw_bold(self, Vector2(size.x * 0.5 - nw * 0.5, box.position.y + 128), name, 52, Color(InkDraw.INK, a))
	draw_string(font, Vector2(size.x - 170, size.y - 40), "click / space", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(InkDraw.PAPER, 0.4))
