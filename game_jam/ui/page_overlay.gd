extends Node2D
## Drawn on a CanvasLayer above the world so darkness never touches it: the
## white page gutter, the thick panel border, caption boxes, and the comic
## damage (a shakier border with cracks) that grows with every stolen word.
## Once the comic is repaired, frames marked border_gap show the way out: a
## gap in the right border with the lit real-world page behind it.

const CAPTION_FONT_SIZE: int = 18
const TITLE_FONT_SIZE: int = 20
const TOAST_FONT_SIZE: int = 19
const MAX_CRACKS: int = 7

var _title: String = ""
var _captions: PackedStringArray = PackedStringArray()
## Spread pages fill the whole panel: their captions teach, then get out of
## the way after this many seconds.
const SPREAD_CAPTION_TIME: float = 9.0
var _captions_left: float = -1.0
var _toast: String = ""
var _toast_left: float = 0.0
var _damage: float = 0.0
## 0..1 how close the Crawler is; the border warps near it.
var _crawler_near: float = 0.0
## FrameData.glitch of the current panel (Chapter 3 breakdown).
var _glitch: float = 0.0
## 0..1 how far the way-out gap in the right border has opened.
var _gap: float = 0.0
var _gap_frame: bool = false
var _tick: int = -1


func _ready() -> void:
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.caption_requested.connect(_on_caption_requested)
	EventBus.comic_damage_changed.connect(_on_damage_changed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.crawler_proximity.connect(_on_crawler_proximity)
	EventBus.comic_repaired.connect(_on_comic_repaired)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	_glitch = GameState.glitch_of(data)
	_gap_frame = data.border_gap
	_gap = 1.0 if _gap_frame and GameState.has_flag(&"comic_repaired") else 0.0
	_title = data.display_name.to_upper()
	_captions = data.captions
	_captions_left = SPREAD_CAPTION_TIME if data.spread != null else -1.0
	_toast = ""
	_toast_left = 0.0
	show()
	queue_redraw()


## The last word went home: the breakdown calms, then the way out opens.
func _on_comic_repaired() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "_glitch", 0.0, 2.5)
	if _gap_frame:
		tween.tween_property(self, "_gap", 1.0, 1.5).set_trans(Tween.TRANS_SINE)


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
	if _captions_left > 0.0:
		_captions_left -= delta
		if _captions_left <= 0.0:
			_captions = PackedStringArray()
			queue_redraw()
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
	_draw_breakdown(panel)
	InkDraw.gap_ratio = _glitch * 0.3
	InkDraw.rect(self, panel, 7.0 + _damage * 2.0, _tick * 7, Color.TRANSPARENT, InkDraw.INK, 1.6 + _damage * 3.5 + _crawler_near * 4.0)
	InkDraw.gap_ratio = 0.0
	if _damage > 0.0:
		# Thin red edge just inside the border: comic damage made visible.
		InkDraw.rect(self, panel.grow(-5.0 - _damage * 2.0), 0.6 + _damage * 3.0, _tick * 7 + 3, Color.TRANSPARENT, Color(InkDraw.RED, 0.85), 1.2 + _damage * 2.0)
	_draw_cracks(panel)
	if _gap > 0.0:
		_draw_gap(panel)

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


## Chapter 3: a misregistered ghost of the panel, and ink running off the
## bottom edge into the gutter. Scales with how broken the frame is and with
## comic damage, so returning words calms it.
func _draw_breakdown(panel: Rect2) -> void:
	var amount: float = _glitch * (0.35 + 0.65 * _damage)
	if amount <= 0.01:
		return
	var shift: Vector2 = Vector2(14, -9) * amount * 1.6
	InkDraw.rect(self, Rect2(panel.position + shift, panel.size), 3.0, _tick * 9, Color.TRANSPARENT, Color(InkDraw.INK, 0.45), 2.5)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 911
	for i in int(amount * 9.0):
		var x: float = panel.position.x + rng.randf_range(20, panel.size.x - 20)
		var length: float = rng.randf_range(20, 110) * amount
		InkDraw.line(self, Vector2(x, panel.end.y), Vector2(x + rng.randf_range(-4, 4), panel.end.y + length), rng.randf_range(2, 5), _tick + i)
		draw_circle(Vector2(x, panel.end.y + length), 4.0, InkDraw.INK)


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


## A tear in the right border, lit from outside: the real page, a lamp-lit
## desk beyond the comic. Warm white, never red.
func _draw_gap(panel: Rect2) -> void:
	var bottom: float = panel.position.y + 508.0
	var height: float = 128.0 * _gap
	var gap: Rect2 = Rect2(panel.end.x - 14.0, bottom - height, 60.0, height)
	var light: Color = Color(1.0, 0.97, 0.86)
	draw_rect(gap, light)
	for i in 5:
		var y: float = gap.position.y + gap.size.y * (i + 0.5) / 5.0
		draw_line(Vector2(gap.position.x, y), Vector2(gap.position.x - 70.0 * _gap, y + (i - 2) * 14.0), Color(light, 0.45), 6.0, true)
	draw_line(gap.position + Vector2(18, 10), Vector2(gap.end.x, gap.position.y + 10), Color(0.5, 0.44, 0.36, 0.4), 3.0, true)
	InkDraw.line(self, gap.position, Vector2(gap.position.x, gap.end.y), 3.0, _tick * 3)
