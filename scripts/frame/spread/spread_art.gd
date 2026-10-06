class_name SpreadArt
extends RefCounted
## Drawing for spread pages: the white page with torn edges and a page
## number, and each small panel (wall, floor, tear, pencil plank, border).

const FILL_SIZE: int = 64
const WALL: Dictionary = {
	&"gallery": Color(0.78, 0.74, 0.66), &"dark_room": Color(0.5, 0.48, 0.47),
	&"torn": Color(0.72, 0.7, 0.66), &"door_room": Color(0.7, 0.66, 0.6),
}
const FLOOR: Color = Color(0.55, 0.5, 0.44)
const PENCIL: Color = Color(0.45, 0.5, 0.6)

static var _fill: ImageTexture


## A soft-edged square light, scaled per panel (rectangular fill light).
static func fill_texture() -> ImageTexture:
	if _fill != null:
		return _fill
	var img: Image = Image.create(FILL_SIZE, FILL_SIZE, false, Image.FORMAT_RGBA8)
	for y in FILL_SIZE:
		for x in FILL_SIZE:
			var e: float = minf(minf(x + 0.5, FILL_SIZE - x - 0.5), minf(y + 0.5, FILL_SIZE - y - 0.5)) / 4.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(e, 0.0, 1.0)))
	_fill = ImageTexture.create_from_image(img)
	return _fill


## The page itself: white gutters, a torn outer edge, the page number.
static func page(ci: CanvasItem, data: PageSpreadData, tick: int) -> void:
	var size: Vector2 = Frame.PANEL_RECT.size
	ci.draw_rect(Rect2(Vector2.ZERO, size), InkDraw.WHITE)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1313
	for i in 18:
		var x: float = rng.randf_range(0, size.x)
		var bite: PackedVector2Array = PackedVector2Array([Vector2(x - 14, size.y), Vector2(x, size.y - rng.randf_range(4, 10)),
			Vector2(x + 14, size.y)])
		ci.draw_colored_polygon(bite, Color(0.8, 0.78, 0.74))
	var font: Font = ThemeDB.fallback_font
	ci.draw_string(font, Vector2(size.x - 46, size.y - 2), str(data.page_number), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(InkDraw.INK, 0.6))


static func _tilted(r: Rect2, degrees: float) -> PackedVector2Array:
	var c: Vector2 = r.get_center()
	var out: PackedVector2Array = PackedVector2Array()
	for p in InkDraw.rect_points(r):
		out.append(c + (p - c).rotated(deg_to_rad(degrees)))
	return out


static func panel(ci: CanvasItem, p: SpreadPanelData, controller: SpreadController, tick: int) -> void:
	var r: Rect2 = p.rect
	var s: int = tick * 17 + int(r.position.x)
	var outline: PackedVector2Array = _tilted(r, p.tilt)
	ci.draw_colored_polygon(outline, WALL.get(p.style, WALL[&"gallery"]))
	var floor_top: float = p.floor_y + 12.0
	ci.draw_rect(Rect2(r.position.x, floor_top, r.size.x, r.end.y - floor_top), FLOOR)
	InkDraw.line(ci, Vector2(r.position.x, floor_top), Vector2(r.end.x, floor_top), 3.0, s)
	match p.style:
		&"gallery":
			for i in 5:
				var x: float = r.position.x + 30 + i * (r.size.x - 60) / 4.0
				InkDraw.line(ci, Vector2(x, r.position.y + 10), Vector2(x, floor_top - 4), 1.5, s + i, Color(InkDraw.INK, 0.25))
		&"dark_room":
			for i in 6:
				var y: float = r.position.y + 20 + i * 34
				InkDraw.line(ci, Vector2(r.position.x + 6, y), Vector2(r.end.x - 6, y + 3), 1.5, s + i, Color(InkDraw.INK, 0.35))
		&"door_room":
			InkDraw.hatch(ci, Rect2(r.position + Vector2(10, 10), Vector2(r.size.x * 0.3, floor_top - r.position.y - 20)), 14.0, 1.5, s + 9,
				Color(InkDraw.INK, 0.2))
		&"torn":
			for i in 4:
				var x2: float = r.position.x + 40 + i * 120
				InkDraw.line(ci, Vector2(x2, floor_top), Vector2(x2 - 20, r.end.y), 1.5, s + i, Color(InkDraw.INK, 0.3))
	if p.gap != Vector2.ZERO:
		_gap(ci, p, controller, floor_top, s)
	InkDraw.polyline(ci, outline, 6.0, s + 30, true)


## A tear down to the gutter: white void, ragged edges; the pencil plank
## across it shows (and holds) only in the torchlight.
static func _gap(ci: CanvasItem, p: SpreadPanelData, controller: SpreadController, floor_top: float, s: int) -> void:
	var a: float = p.gap.x
	var b: float = p.gap.y
	var bottom: float = p.rect.end.y + 4.0
	var tear: PackedVector2Array = PackedVector2Array([Vector2(a, floor_top)])
	for i in 6:
		tear.append(Vector2(a + (i % 2) * 10.0 - 4.0, floor_top + (bottom - floor_top) * (i + 1) / 6.0))
	for i in 6:
		tear.append(Vector2(b - (i % 2) * 10.0 + 4.0, bottom - (bottom - floor_top) * i / 6.0))
	tear.append(Vector2(b, floor_top))
	ci.draw_colored_polygon(tear, InkDraw.WHITE)
	InkDraw.polyline(ci, tear, 2.5, s + 40, true)
	if p.gap_lit_bridge and controller.current == p:
		var k: float = controller.plank_lit
		var c: Color = Color(PENCIL, 0.25 + 0.75 * k)
		var y: float = floor_top - 2.0
		InkDraw.line(ci, Vector2(a - 10, y), Vector2(b + 10, y), 2.0 + 3.0 * k, s + 41, c, 2.5)
		InkDraw.line(ci, Vector2(a - 10, y + 10), Vector2(b + 10, y + 10), 1.5, s + 42, c, 2.5)
		for i in 4:
			var x: float = lerpf(a, b, (i + 0.5) / 4.0)
			InkDraw.line(ci, Vector2(x, y), Vector2(x, y + 10), 1.5, s + 43 + i, c, 2.0)
