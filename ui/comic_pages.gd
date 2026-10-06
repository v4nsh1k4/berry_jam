class_name ComicPages
extends Control
## Plays a short story as comic pages (the intro and the ending): each page
## has tilted, clipped panels that look into a 1280x720 "scene" drawn by
## `scene_drawer` (func(ci, scene_id, t, tick)), with a slow zoom, a tinted
## halftone wash and a narration box; pages change with a page turn.
## A page: {start, end, caption, panels: [{rect (0..1 of the page), src
## (Rect2 in scene space), tilt (deg), scene (int), zoom (end zoom)}]}.

const SCENE: Vector2 = Vector2(1280, 720)
const PAGE_RECT: Rect2 = Rect2(40, 28, 1200, 664)
const INNER: Rect2 = Rect2(66, 50, 1148, 540)
const GUTTER: float = 16.0
const TURN_TIME: float = 0.55

var pages: Array = []
var scene_drawer: Callable
## Halftone tint over the panels.
var tint: Color = Color(0.35, 0.45, 0.7, 0.12)
## Small print under the page (e.g. the skip hint).
var footer: String = ""
var t: float = 0.0

var _page: int = -1
var _panels: Array[Control] = []
var _turn: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn = Control.new()
	_turn.set_anchors_preset(Control.PRESET_FULL_RECT)
	_turn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn.draw.connect(_draw_turn)
	add_child(_turn)


func set_time(value: float) -> void:
	t = value
	var index: int = -1
	for i in pages.size():
		if t >= pages[i].start and t < pages[i].end:
			index = i
	if index != _page:
		_build(index)
	queue_redraw()
	for p in _panels:
		p.queue_redraw()
	_turn.queue_redraw()


func _build(index: int) -> void:
	_page = index
	for p in _panels:
		p.queue_free()
	_panels.clear()
	if index < 0:
		return
	var list: Array = pages[index].panels
	for i in list.size():
		var spec: Dictionary = list[i]
		var f: Rect2 = spec.rect
		var panel: Control = Control.new()
		panel.clip_contents = true
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.size = f.size * INNER.size - Vector2(GUTTER, GUTTER)
		panel.pivot_offset = panel.size * 0.5
		panel.position = INNER.position + f.position * INNER.size + Vector2(GUTTER, GUTTER) * 0.5
		panel.rotation = deg_to_rad(spec.get("tilt", 0.0))
		panel.draw.connect(_draw_panel.bind(panel, spec, i))
		add_child(panel)
		_panels.append(panel)
	move_child(_turn, -1)


func _draw() -> void:
	if _page < 0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.045, 0.06))
	draw_rect(Rect2(PAGE_RECT.position + Vector2(12, 16), PAGE_RECT.size), Color(0, 0, 0, 0.4))
	draw_rect(PAGE_RECT, InkDraw.PAPER)
	if footer != "":
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, size.y - 8), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.6, 0.6))
	var page: Dictionary = pages[_page]
	var caption: String = page.get("caption", "")
	if caption == "":
		return
	var local: float = t - page.start
	var shown: int = int(maxf(local - 0.8, 0.0) * 34.0)
	var box: Rect2 = Rect2(INNER.position.x + 60, INNER.end.y + 22, INNER.size.x - 120, 62)
	InkDraw.rect(self, box, 3.5, InkDraw.boil_tick(), Color(1.0, 0.97, 0.86))
	draw_string(ThemeDB.fallback_font, box.position + Vector2(24, 40), caption.substr(0, mini(shown, caption.length())),
		HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 48, 24, InkDraw.INK)


func _draw_panel(panel: Control, spec: Dictionary, index: int) -> void:
	var page: Dictionary = pages[_page]
	var local: float = t - page.start
	var appear: float = clampf((local - TURN_TIME - index * 0.4) / 0.35, 0.0, 1.0)
	if _page == 0:
		appear = clampf((local - index * 0.4) / 0.35, 0.0, 1.0)
	if appear <= 0.0:
		return
	var s: Vector2 = panel.size
	var src: Rect2 = spec.src
	var k: float = clampf(local / maxf(page.end - page.start, 0.1), 0.0, 1.0)
	var zoom: float = lerpf(1.0, spec.get("zoom", 1.08), k)
	var scale: float = maxf(s.x / src.size.x, s.y / src.size.y) * zoom
	var view: Transform2D = Transform2D(0.0, Vector2(scale, scale), 0.0, s * 0.5 - src.get_center() * scale)
	RevealArt.set_view(panel, view)
	scene_drawer.call(panel, int(spec.get("scene", 0)), t, InkDraw.boil_tick())
	RevealArt.set_view(panel, Transform2D.IDENTITY)
	_halftone(panel, s)
	InkDraw.rect(panel, Rect2(Vector2(3, 3), s - Vector2(6, 6)), 6.0, InkDraw.boil_tick() + index)
	if appear < 1.0:
		panel.draw_rect(Rect2(Vector2.ZERO, s), Color(InkDraw.PAPER, 1.0 - appear))


## A light dot screen in the page's tint (the printed-comic look).
func _halftone(panel: Control, s: Vector2) -> void:
	var step: float = 14.0
	var y: float = 0.0
	var row: int = 0
	while y < s.y:
		var x: float = (step * 0.5) if row % 2 == 1 else 0.0
		while x < s.x:
			panel.draw_rect(Rect2(x, y, 3, 3), tint)
			x += step
		y += step
		row += 1


## The previous page folding away to the left.
func _draw_turn() -> void:
	if _page <= 0:
		return
	var local: float = t - pages[_page].start
	if local >= TURN_TIME:
		return
	var k: float = ease(clampf(local / TURN_TIME, 0.0, 1.0), 0.6)
	var r: Rect2 = PAGE_RECT
	var edge: float = lerpf(r.end.x, r.position.x, k)
	var curl: float = 70.0 * sin(k * PI)
	_turn.draw_rect(Rect2(r.position, Vector2(edge - r.position.x, r.size.y)), InkDraw.PAPER)
	if curl < 2.0:
		return
	var fold: PackedVector2Array = PackedVector2Array([Vector2(edge, r.position.y), Vector2(edge + curl, r.position.y + 20),
		Vector2(edge + curl, r.end.y - 20), Vector2(edge, r.end.y)])
	_turn.draw_colored_polygon(fold, Color(0.82, 0.79, 0.72))
	_turn.draw_polyline(fold, InkDraw.INK, 2.5)
