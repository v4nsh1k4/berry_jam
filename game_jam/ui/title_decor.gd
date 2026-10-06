class_name TitleDecor
extends RefCounted
## A few sparse comic-page touches on the title page / menu backdrop (Stage
## 7), painted once into TitleArt's texture as one job: a white gutter and an
## ink panel border round the page, faint pencil construction lines across
## the paper, three short ink drips from the top border, and a small page
## number. Black and white, low contrast, clear of the title plate (x 400-880,
## y 40-235) and the menu buttons.

const GUTTER: float = 14.0
const PENCIL: Color = Color(0.3, 0.29, 0.28, 0.2)


static func paint(ci: CanvasItem, size: Vector2) -> void:
	_gutter(ci, size)
	_pencil(ci, size)
	_drips(ci)
	_page_number(ci, size)


## White gutter strips at the edges, then the panel's ink border.
static func _gutter(ci: CanvasItem, size: Vector2) -> void:
	var g: float = GUTTER
	for r in [Rect2(0, 0, size.x, g), Rect2(0, size.y - g, size.x, g), Rect2(0, 0, g, size.y), Rect2(size.x - g, 0, g, size.y)]:
		ci.draw_rect(r, InkDraw.WHITE)
	var border: Rect2 = Rect2(Vector2(g, g), size - Vector2(g, g) * 2.0)
	InkDraw.polyline(ci, InkDraw.rect_points(border), 3.0, 1907, true, InkDraw.INK, 1.0)


## A few light construction lines, as if the page was laid out in pencil.
static func _pencil(ci: CanvasItem, size: Vector2) -> void:
	ci.draw_line(Vector2(150, 362), Vector2(size.x - 150, 358), PENCIL, 1.0, true)
	ci.draw_line(Vector2(642, 250), Vector2(638, size.y - 40), PENCIL, 1.0, true)
	ci.draw_line(Vector2(330, 250), Vector2(560, 610), PENCIL, 1.0, true)
	ci.draw_arc(TitleArt.CENTRE, 232.0, PI * 0.15, PI * 0.85, 40, PENCIL, 1.0, true)


## Ink run down from the top border, short, between the crows and the plate.
static func _drips(ci: CanvasItem) -> void:
	for d in [Vector3(585, 22, 2.6), Vector3(612, 12, 2.0), Vector3(700, 30, 3.0)]:
		var top: Vector2 = Vector2(d.x, GUTTER + 1.0)
		var end: Vector2 = top + Vector2(0.5, d.y)
		ci.draw_line(top, end, InkDraw.INK, d.z, true)
		ci.draw_circle(end, d.z * 1.3, InkDraw.INK)


## "1" in a small caption box at the bottom right, over the hatching.
static func _page_number(ci: CanvasItem, size: Vector2) -> void:
	var box: Rect2 = Rect2(size - Vector2(GUTTER + 58, GUTTER + 40), Vector2(44, 28))
	ci.draw_rect(box, InkDraw.PAPER)
	ci.draw_rect(box, InkDraw.INK, false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var w: float = font.get_string_size("1", HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	ci.draw_string(font, Vector2(box.get_center().x - w * 0.5, box.end.y - 7), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, InkDraw.INK)
