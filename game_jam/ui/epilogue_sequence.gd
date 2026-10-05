extends Control
## The ending, drawn in code as comic pages (about 30 s; click skips to the
## fade). Plays on arriving at a frame marked `epilogue` (walking out through
## the border):
##   page 1: the red figure steps through the gap in the panel border into a
##           lit rectangle of the real world;
##   page 2: dawn; the teenager closes the book;
##   page 3: one clear last panel: everyone in the house complete, speaking
##           full lines, a faint red mark on the page, and a closing line.
## Then the end card (credits, Back to Menu). The save is cleared as it
## starts (EventBus.game_completed).

const HIP: Vector2 = Vector2(330, 470)
const BOOK: Vector2 = Vector2(560, 360)
const T_PAGE2: float = 9.0
const T_CLOSE: float = 13.5
const T_PAGE3: float = 18.0
const T_FADE: float = 27.6
const T_END: float = 30.0
## The last page's characters and their lines come from this frame's data.
const LAST_PAGE: String = "res://data/frames/ch3_escape.tres"

var _t: float = -1.0
var _cast: Array[NpcData] = []
var _closed: bool = false
var _pages: ComicPages
## White in at the start, white out at the end, over the pages.
var _white: ColorRect


func _ready() -> void:
	UiTheme.make_screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(_stop)
	_pages = ComicPages.new()
	_pages.scene_drawer = _scene
	_pages.tint = Color(0.85, 0.7, 0.45, 0.10)
	_pages.footer = "click: skip"
	_pages.pages = [
		{start = 0.0, end = T_PAGE2, caption = "Through the gap in the border, there was morning.", panels = [
			{rect = Rect2(0, 0, 0.62, 1), src = Rect2(260, 60, 860, 640), scene = 0, zoom = 1.04},
			{rect = Rect2(0.62, 0, 0.38, 1), src = Rect2(380, 120, 420, 600), scene = 1, tilt = 1.5, zoom = 1.1}]},
		{start = T_PAGE2, end = T_PAGE3, caption = "Every word went back. The Artist's hand set down its pencil.", panels = [
			{rect = Rect2(0, 0, 1, 0.55), src = Rect2(0, 80, 1280, 580), scene = 1, zoom = 1.05},
			{rect = Rect2(0, 0.55, 0.5, 0.45), src = Rect2(430, 260, 260, 200), scene = 1, tilt = -1.5, zoom = 1.2},
			{rect = Rect2(0.5, 0.55, 0.5, 0.45), src = Rect2(200, 150, 340, 230), scene = 1, tilt = 1.5, zoom = 1.15}]},
		{start = T_PAGE3, end = T_END + 1.0, caption = "Some stories keep a little of whoever visits them.", panels = [
			{rect = Rect2(0, 0, 1, 1), src = Rect2(0, 0, 1280, 720), scene = 2, zoom = 1.03}]},
	]
	add_child(_pages)
	_white = ColorRect.new()
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_white)
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
	for at in [T_PAGE2, T_PAGE3]:
		if _t >= at and _t - delta < at:
			AudioManager.play(&"swoosh", -6.0, 0.05)
	if _t >= T_CLOSE and not _closed:
		_closed = true
		AudioManager.play(&"slam", -9.0, 0.0)
	if _t >= T_END:
		_stop()
		EventBus.epilogue_finished.emit()
		return
	_pages.set_time(_t)
	_white.color = Color(1, 1, 1, maxf(1.0 - _t, smoothstep(T_FADE, T_END, _t)))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and _t > 1.0:
		accept_event()
		_t = maxf(_t, T_FADE)


func _scene(ci: CanvasItem, id: int, t: float, tick: int) -> void:
	match id:
		0:
			_escape(ci, t, tick)
		1:
			_morning(ci, t, tick)
		_:
			_last_panel(ci, tick)


## Inside the comic: the border splits and the red figure walks into light.
func _escape(ci: CanvasItem, t: float, tick: int) -> void:
	var s: Vector2 = ComicPages.SCENE
	ci.draw_rect(Rect2(Vector2(-100, -100), s + Vector2(200, 200)), InkDraw.PAPER)
	InkDraw.line(ci, Vector2(-100, 560), Vector2(s.x + 100, 562), 4.0, tick)
	var open: float = smoothstep(0.5, 4.0, t)
	var gap: Rect2 = Rect2(880, 560 - 360 * open, 90, 360 * open)
	ci.draw_rect(Rect2(910, -100, 24, s.y + 200), InkDraw.INK)
	ci.draw_rect(gap, Color(1.0, 0.97, 0.86))
	if open > 0.02:
		ci.draw_colored_polygon(PackedVector2Array([gap.position, gap.position + Vector2(0, gap.size.y),
		Vector2(gap.position.x - 700 * open, 600), Vector2(gap.position.x - 700 * open, gap.position.y - 40)]), Color(1.0, 0.95, 0.75, 0.4))
	var x: float = lerpf(380.0, 915.0, smoothstep(3.0, 8.5, t))
	RevealArt.red_figure(ci, Vector2(x, 560), 2.0 * (1.0 - smoothstep(7.5, 8.8, t) * 0.4), tick)


## Dawn in the bedroom; the book glows faintly, then is shut and set down.
func _morning(ci: CanvasItem, t: float, tick: int) -> void:
	RealWorldArt.bedroom(ci, ComicPages.SCENE, 0.85, tick)
	var open: float = 1.0 - smoothstep(T_CLOSE - 0.3, T_CLOSE, t)
	var lowered: Vector2 = BOOK.lerp(Vector2(560, 470), smoothstep(T_CLOSE + 0.5, T_PAGE3 - 1.0, t))
	RealWorldArt.teen(ci, HIP, lowered, 1.0, 0.0, tick)
	RealWorldArt.book(ci, lowered, open, 0.5 * open, tick)


## The last panel: the house whole again, everyone speaking, and a faint red
## mark where the player was.
func _last_panel(ci: CanvasItem, tick: int) -> void:
	var s: Vector2 = ComicPages.SCENE
	ci.draw_rect(Rect2(Vector2(-100, -100), s + Vector2(200, 200)), InkDraw.PAPER)
	var floor_y: float = 560.0
	InkDraw.line(ci, Vector2(-100, floor_y), Vector2(s.x + 100, floor_y), 3.0, tick + 1)
	for i in _cast.size():
		var npc: NpcData = _cast[i]
		var feet: Vector2 = Vector2(300 + i * 340, floor_y + 10)
		if npc.visual_style == &"portrait":
			feet = Vector2(300 + i * 340, 330)
		RevealArt._character(ci, npc.visual_style, feet, 1.1, tick)
		if npc.bubbles.is_empty() or npc.lines.is_empty():
			continue
		var line: String = npc.lines[0].replace("{word}", npc.bubbles[0].text)
		var half: float = BubbleArt.size_for(line, 20).x * 0.5 + 24.0
		var center: Vector2 = Vector2(clampf(feet.x, half + 20, s.x - half - 20), 90 + (i % 2) * 64)
		BubbleArt.draw(ci, center, line, feet + Vector2(0, -210 if npc.visual_style != &"portrait" else -40), tick + i, 20)
	var mark: Vector2 = Vector2(s.x - 130, floor_y + 60)
	ci.draw_colored_polygon(InkDraw.ellipse_points(mark, Vector2(34, 12), 14), Color(InkDraw.RED, 0.3))
	ci.draw_circle(mark + Vector2(24, -12), 5.0, Color(InkDraw.RED, 0.24))
