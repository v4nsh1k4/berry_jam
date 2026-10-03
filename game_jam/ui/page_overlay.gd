extends Node2D
## Drawn on a CanvasLayer above the world so darkness never touches it: the
## white page gutter, the thick panel border, caption boxes, and the comic
## damage (a shakier border with cracks) that grows with every stolen word.

const CAPTION_FONT_SIZE: int = 18
const TITLE_FONT_SIZE: int = 20
const TOAST_FONT_SIZE: int = 19
const MAX_CRACKS: int = 7

var _title: String = ""
var _captions: PackedStringArray = PackedStringArray()
var _toast: String = ""
var _toast_left: float = 0.0
var _damage: float = 0.0
## 0..1 how close the Crawler is; the border warps near it.
var _crawler_near: float = 0.0
var _tick: int = -1


func _ready() -> void:
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.caption_requested.connect(_on_caption_requested)
	EventBus.comic_damage_changed.connect(_on_damage_changed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.crawler_proximity.connect(_on_crawler_proximity)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	_title = data.display_name.to_upper()
	_captions = data.captions
	_toast = ""
	_toast_left = 0.0
	show()
	queue_redraw()


func _on_caption_requested(text: String, duration: float) -> void:
	_toast = text
	_toast_left = duration
	queue_redraw()


func _on_crawler_proximity(amount: float, _moving: bool) -> void:
	_crawler_near = amount


func _on_damage_changed(_value: float) -> void:
	_damage = GameState.damage_visual()
	queue_redraw()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			_toast = ""
			queue_redraw()
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	var page: Rect2 = Rect2(Vector2.ZERO, get_viewport_rect().size)
	var panel: Rect2 = Frame.PANEL_RECT
	# Gutter: everything on the page outside the panel. Drawn generously so
	# screen shake never shows the world past the edge.
	var gutter: Color = InkDraw.WHITE
	draw_rect(Rect2(-100, -100, page.size.x + 200, panel.position.y + 100), gutter)
	draw_rect(Rect2(-100, panel.end.y, page.size.x + 200, page.size.y - panel.end.y + 100), gutter)
	draw_rect(Rect2(-100, -100, panel.position.x + 100, page.size.y + 200), gutter)
	draw_rect(Rect2(panel.end.x, -100, page.size.x - panel.end.x + 100, page.size.y + 200), gutter)
	InkDraw.rect(self, panel, 7.0 + _damage * 2.0, _tick * 7, Color.TRANSPARENT, InkDraw.INK, 1.6 + _damage * 3.5 + _crawler_near * 4.0)
	if _damage > 0.0:
		# Thin red edge just inside the border: comic damage made visible.
		InkDraw.rect(self, panel.grow(-5.0 - _damage * 2.0), 0.6 + _damage * 3.0, _tick * 7 + 3, Color.TRANSPARENT, Color(InkDraw.RED, 0.85), 1.2 + _damage * 2.0)
	_draw_cracks(panel)

	var font: Font = ThemeDB.fallback_font
	if _title != "":
		_draw_caption(font, _title, panel.position + Vector2(-6, -6), TITLE_FONT_SIZE, 1)
	if _toast != "":
		var toast_size: Vector2 = font.get_string_size(_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, TOAST_FONT_SIZE)
		_draw_caption(font, _toast, Vector2(panel.get_center().x - toast_size.x * 0.5 - 14, panel.position.y + 16), TOAST_FONT_SIZE, 3, InkDraw.WHITE)
	var y: float = panel.end.y - 18.0
	for i in range(_captions.size() - 1, -1, -1):
		var size: Vector2 = font.get_string_size(_captions[i], HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE)
		var top_left: Vector2 = Vector2(panel.end.x - size.x - 46.0, y - size.y - 14.0)
		_draw_caption(font, _captions[i], top_left, CAPTION_FONT_SIZE, 10 + i)
		y = top_left.y - 10.0


## Hairline cracks running in from the border. Positions are fixed per crack
## so they accumulate instead of jumping around.
func _draw_cracks(panel: Rect2) -> void:
	var count: int = int(round(_damage * MAX_CRACKS))
	var perimeter: float = (panel.size.x + panel.size.y) * 2.0
	for i in count:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 4021 + i * 977
		var t: float = rng.randf() * perimeter
		var start: Vector2
		var inward: Vector2
		if t < panel.size.x:
			start = panel.position + Vector2(t, 0)
			inward = Vector2.DOWN
		elif t < panel.size.x + panel.size.y:
			start = Vector2(panel.end.x, panel.position.y + t - panel.size.x)
			inward = Vector2.LEFT
		elif t < panel.size.x * 2.0 + panel.size.y:
			start = Vector2(panel.end.x - (t - panel.size.x - panel.size.y), panel.end.y)
			inward = Vector2.UP
		else:
			start = Vector2(panel.position.x, panel.end.y - (t - panel.size.x * 2.0 - panel.size.y))
			inward = Vector2.RIGHT
		var pts: PackedVector2Array = PackedVector2Array([start])
		var p: Vector2 = start
		for j in 4:
			p += inward.rotated(rng.randf_range(-0.7, 0.7)) * rng.randf_range(14.0, 34.0)
			pts.append(p)
		InkDraw.polyline(self, pts, 2.2, _tick + i, false, InkDraw.RED, 0.6)


func _draw_caption(font: Font, text: String, top_left: Vector2, font_size: int, seed_offset: int, fill: Color = InkDraw.PAPER) -> void:
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box: Rect2 = Rect2(top_left, size + Vector2(28, 14))
	InkDraw.rect(self, box, 3.0, _tick * 5 + seed_offset, fill)
	draw_string(font, top_left + Vector2(14, 7 + font.get_ascent(font_size)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, InkDraw.INK)
