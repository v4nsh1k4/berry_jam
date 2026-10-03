extends Control
## The epilogue, drawn in code (about 15 s; click skips). Plays on arriving at
## a frame marked `epilogue` (walking out through the border):
##   morning in the real world, the teenager closes the book -> one last panel:
##   everyone in the house complete, speaking full lines, and a faint red mark
##   on the page. Then the end card (credits, Back to Menu).
## The save is cleared as it starts (EventBus.game_completed).

const HIP: Vector2 = Vector2(330, 470)
const BOOK: Vector2 = Vector2(560, 360)
const T_CLOSE: float = 4.0
const T_PANEL: float = 8.0
const T_FADE: float = 14.0
const T_END: float = 15.0
## The last page's characters and their lines come from this frame's data.
const LAST_PAGE: String = "res://data/frames/ch3_escape.tres"

var _t: float = -1.0
var _cast: Array[NpcData] = []
var _closed: bool = false


func _ready() -> void:
	UiTheme.make_screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(_stop)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	if not data.epilogue:
		return
	var page: FrameData = load(LAST_PAGE) as FrameData
	_cast.assign(page.npcs if page != null else [])
	_t = 0.0
	_closed = false
	GameState.modal_open = true
	EventBus.interact_prompt_changed.emit("", Vector2.ZERO)
	EventBus.game_completed.emit()
	show()


func _stop() -> void:
	_t = -1.0
	hide()


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t >= T_CLOSE and not _closed:
		_closed = true
		AudioManager.play(&"slam", -9.0, 0.0)
	if _t >= T_END:
		_stop()
		EventBus.epilogue_finished.emit()
		return
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and _t > 1.0:
		accept_event()
		_t = maxf(_t, T_FADE)


func _draw() -> void:
	if _t < 0.0:
		return
	var tick: int = InkDraw.boil_tick()
	if _t < T_PANEL:
		_draw_morning(tick)
	else:
		_draw_last_panel(tick)
	var white: float = maxf(1.0 - _t / 1.0, smoothstep(T_FADE, T_END, _t))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, white))


## Dawn. The book glows faintly, then is shut.
func _draw_morning(tick: int) -> void:
	RealWorldArt.bedroom(self, size, 0.85, tick)
	var open: float = 1.0 - smoothstep(T_CLOSE - 0.3, T_CLOSE, _t)
	var lowered: Vector2 = BOOK.lerp(Vector2(560, 470), smoothstep(T_CLOSE + 0.5, T_PANEL - 1.0, _t))
	RealWorldArt.teen(self, HIP, lowered, 1.0, 0.0, tick)
	RealWorldArt.book(self, lowered, open, 0.5 * open, tick)
	var alpha: float = clampf((_t - 5.0) / 0.5, 0.0, 1.0) * clampf((T_PANEL - 0.2 - _t) / 0.4, 0.0, 1.0)
	RevealArt.caption(self, "I gave every word back.", Vector2(size.x * 0.5, 64), alpha, tick)


## The last panel: the house whole again, everyone speaking, and a faint red
## mark where the player was.
func _draw_last_panel(tick: int) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), InkDraw.WHITE)
	var panel: Rect2 = Rect2(80, 60, size.x - 160, size.y - 120)
	InkDraw.rect(self, panel, 8.0, tick, InkDraw.PAPER)
	InkDraw.line(self, Vector2(panel.position.x, panel.position.y + 430), Vector2(panel.end.x, panel.position.y + 430), 3.0, tick + 1)
	var font: Font = ThemeDB.fallback_font
	for i in _cast.size():
		var npc: NpcData = _cast[i]
		var feet: Vector2 = panel.position + Vector2(220 + i * 380, 440)
		if npc.visual_style == &"portrait":
			feet = panel.position + Vector2(200 + i * 380, 220)
		draw_set_transform(feet, 0.0, Vector2(0.85, 0.85))
		NpcArt.draw(self, npc.visual_style, tick)
		draw_set_transform(Vector2.ZERO)
		if npc.bubbles.is_empty() or npc.lines.is_empty():
			continue
		var line: String = npc.lines[0].replace("{word}", npc.bubbles[0].text)
		var half: float = BubbleArt.size_for(line, 18).x * 0.5 + 24.0
		var center: Vector2 = Vector2(clampf(feet.x, panel.position.x + half, panel.end.x - half), panel.position.y + 60 + (i % 2) * 56)
		BubbleArt.draw(self, center, line, feet + Vector2(0, -150 if npc.visual_style != &"portrait" else -10), tick + i)
	# The faint red mark: something was here, and was let go.
	var mark: Vector2 = panel.end - Vector2(90, 70)
	draw_colored_polygon(InkDraw.ellipse_points(mark, Vector2(26, 10), 14), Color(InkDraw.RED, 0.28))
	draw_circle(mark + Vector2(18, -10), 4.0, Color(InkDraw.RED, 0.22))
	var title: String = RealWorldArt.TITLE_TOP + " " + RealWorldArt.TITLE_BOTTOM
	var title_size: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	InkDraw.rect(self, Rect2(panel.position - Vector2(6, 6), title_size + Vector2(28, 14)), 3.0, tick + 9, InkDraw.PAPER)
	draw_string(font, panel.position + Vector2(8, 1 + font.get_ascent(18)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, InkDraw.INK)
