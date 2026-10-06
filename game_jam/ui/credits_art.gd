class_name CreditsArt
extends RefCounted
## The credits as a black-and-white comic page (Stage 6), drawn by the menu's
## Credits page and the End Card: a white gutter, thick wobbly ink panel
## borders, halftone corners, caption boxes, speech bubbles holding the credit
## lines (Arthur and Mrs. Vane say them), and a few tiny ink doodles. No red.
## The page fits in the rect it is given (1280x720 needs no scrolling).

## Credit lines (plain text, split at runtime: see the export gotchas).
const TEAM: String = "Made for the Infinium 26 game jam|by the Berry Jam team."
const ENGINE: String = "Made with the Godot Engine.|MIT licence: godotengine.org/license"
const FONT_LINE: String = "Font: Godot's built-in default font."
const TITLE: String = "INK-BLEED"
const SUBTITLE: String = "The Silent House of Hollow Hill"


## `area`: where the page goes; `heading`: the top panel's big words.
static func page(ci: CanvasItem, area: Rect2, heading: String, tick: int) -> void:
	RevealArt.set_view(ci, Transform2D.IDENTITY)
	ci.draw_rect(area.grow(8), InkDraw.WHITE)
	var g: float = 14.0
	var top: Rect2 = Rect2(area.position, Vector2(area.size.x, area.size.y * 0.34))
	var mid_y: float = top.end.y + g
	var mid_h: float = area.size.y * 0.42
	var left: Rect2 = Rect2(area.position.x, mid_y, area.size.x * 0.56 - g * 0.5, mid_h)
	var right: Rect2 = Rect2(left.end.x + g, mid_y, area.end.x - left.end.x - g, mid_h)
	var bottom: Rect2 = Rect2(area.position.x, mid_y + mid_h + g, area.size.x, area.end.y - mid_y - mid_h - g)
	for r in [top, left, right, bottom]:
		ci.draw_rect(r, InkDraw.PAPER)
		_halftone(ci, r, r.end)
	_top(ci, top, heading, tick)
	_speaker(ci, left, &"butler", TEAM.split("|"), tick + 10)
	_speaker(ci, right, &"housekeeper", ENGINE.split("|"), tick + 20)
	_bottom(ci, bottom, tick + 30)
	for i in 4:
		InkDraw.rect(ci, [top, left, right, bottom][i], 7.0, tick + 40 + i, Color.TRANSPARENT, InkDraw.INK, 2.2)


## Dots shrinking away from `corner` (Ben-Day shading).
static func _halftone(ci: CanvasItem, r: Rect2, corner: Vector2) -> void:
	var reach: float = minf(r.size.x, r.size.y) * 0.6
	var dir: Vector2 = Vector2(-1.0 if corner.x > r.get_center().x else 1.0, -1.0 if corner.y > r.get_center().y else 1.0)
	var step: float = 11.0
	for gy in int(reach / step):
		for gx in int(reach / step):
			var p: Vector2 = corner + Vector2(gx * step + (step * 0.5 if gy % 2 == 1 else 0.0), gy * step) * dir
			var k: float = 1.0 - p.distance_to(corner) / reach
			if k > 0.05:
				ci.draw_circle(p, k * 3.6, Color(InkDraw.INK, 0.85))


## A caption box (comic narration): pale fill, ink border, text inside.
static func caption(ci: CanvasItem, at: Vector2, text: String, size: int, tick: int) -> Rect2:
	var font: Font = ThemeDB.fallback_font
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var box: Rect2 = Rect2(at, Vector2(w + 28, size * 1.6))
	InkDraw.rect(ci, box, 3.0, tick, InkDraw.WHITE)
	ci.draw_string(font, box.position + Vector2(14, size * 1.15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, InkDraw.INK)
	return box


static func _top(ci: CanvasItem, r: Rect2, heading: String, tick: int) -> void:
	var font: Font = ThemeDB.fallback_font
	caption(ci, r.position + Vector2(18, 16), "CREDITS", 18, tick)
	var size: int = 64
	var w: float = font.get_string_size(heading, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base: Vector2 = Vector2(r.get_center().x - w * 0.5, r.get_center().y + 18)
	ci.draw_string_outline(font, base + Vector2(5, 5), heading, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(InkDraw.INK, 0.25))
	ci.draw_string_outline(font, base, heading, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, InkDraw.INK)
	ci.draw_string(font, base, heading, HORIZONTAL_ALIGNMENT_LEFT, -1, size, InkDraw.WHITE)
	var sub: String = SUBTITLE if heading == TITLE else TITLE + "  -  " + SUBTITLE
	var sw: float = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	caption(ci, Vector2(r.end.x - sw - 46, r.end.y - 52), sub, 20, tick + 1)
	# Doodles: an ink splat and a little spiral in the corners.
	CutsceneDetail.splatter(ci, r.position + Vector2(r.size.x * 0.12, r.size.y * 0.72), 9.0, 41, InkDraw.INK)
	_spiral(ci, r.position + Vector2(r.size.x * 0.88, r.size.y * 0.3), 22.0, tick + 2)


## A character at the panel's left saying the lines (first in a speech
## bubble, the rest in a caption box under it).
static func _speaker(ci: CanvasItem, r: Rect2, style: StringName, lines: PackedStringArray, tick: int) -> void:
	var feet: Vector2 = Vector2(r.position.x + 70, r.end.y - 14)
	var sc: float = minf(0.8, (r.size.y - 60) / 200.0)
	InkDraw.line(ci, Vector2(r.position.x + 8, feet.y), Vector2(r.end.x - 8, feet.y + 2), 3.0, tick)
	RevealArt._character(ci, style, feet, sc, tick + 1)
	var mouth: Vector2 = feet + NpcArt.mouth(style) * sc
	var size: int = 21
	var bsize: Vector2 = BubbleArt.size_for(lines[0], size)
	var c: Vector2 = Vector2(clampf(mouth.x + 60 + bsize.x * 0.5, r.position.x + bsize.x * 0.55, r.end.x - bsize.x * 0.58), r.position.y + 20 + bsize.y * 0.6)
	# The tail runs from the bubble's lower-left edge to the mouth (under the
	# oval, so it never crosses the words).
	var base: Vector2 = c + Vector2(-bsize.x * 0.3, bsize.y * 0.3)
	var tip: Vector2 = mouth + Vector2(10, -4)
	var side: Vector2 = (tip - base).normalized().orthogonal() * 9.0
	ci.draw_colored_polygon(PackedVector2Array([base + side, base - side, tip]), InkDraw.WHITE)
	InkDraw.line(ci, base + side, tip, 3.0, tick + 4)
	InkDraw.line(ci, base - side, tip, 3.0, tick + 5)
	BubbleArt.draw(ci, c, lines[0], BubbleArt.NO_TAIL, tick + 2, size, 1.0, 3.0)
	if lines.size() > 1:
		var font: Font = ThemeDB.fallback_font
		var cw: float = font.get_string_size(lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 28
		caption(ci, Vector2(minf(c.x - cw * 0.3, r.end.x - cw - 14), c.y + bsize.y * 0.6 + 18), lines[1], 19, tick + 3)


static func _bottom(ci: CanvasItem, r: Rect2, tick: int) -> void:
	var box: Rect2 = caption(ci, r.position + Vector2(24, r.size.y * 0.5 - 16), FONT_LINE, 19, tick)
	# A row of ink drops falling, and a nib, along the strip.
	for i in 5:
		var x: float = box.end.x + 60 + i * (r.end.x - box.end.x - 140) / 5.0
		var y: float = r.position.y + r.size.y * (0.35 + 0.1 * (i % 2))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 12), Vector2(x + 6, y + 2), Vector2(x, y + 8), Vector2(x - 6, y + 2)]), InkDraw.INK)
	CrawlerArt.nib(ci, Vector2(r.end.x - 40, r.get_center().y + 10), PI * 0.6, 7.0)
	InkDraw.line(ci, Vector2(r.end.x - 120, r.get_center().y + 22), Vector2(r.end.x - 52, r.get_center().y - 6), 2.0, tick + 5)


static func _spiral(ci: CanvasItem, c: Vector2, radius: float, tick: int) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 40:
		var k: float = i / 39.0
		pts.append(c + Vector2.from_angle(k * TAU * 2.6) * radius * k)
	InkDraw.polyline(ci, pts, 2.0, tick, false, InkDraw.INK, 0.8)
