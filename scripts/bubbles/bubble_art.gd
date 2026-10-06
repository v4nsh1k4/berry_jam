class_name BubbleArt
extends RefCounted
## Shared speech-bubble drawing: white oval, ink outline, tail, bold word.
## Used by world bubbles, the inventory strip and the player's reactions.

const FONT_SIZE: int = 22
const PAD: Vector2 = Vector2(20, 13)
const NO_TAIL: Vector2 = Vector2.INF


static func size_for(text: String, font_size: int = FONT_SIZE) -> Vector2:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return Vector2(maxf(text_size.x + PAD.x * 2.0, 64.0), text_size.y + PAD.y * 2.0)


static func draw(ci: CanvasItem, center: Vector2, text: String, tail_tip: Vector2, seed_value: int,
		font_size: int = FONT_SIZE, alpha: float = 1.0, outline_width: float = 3.0) -> void:
	draw_shell(ci, center, size_for(text, font_size), tail_tip, seed_value, alpha, outline_width)
	if text != "":
		var font: Font = ThemeDB.fallback_font
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_bold(ci, baseline_for(center, text_size.x, font_size), text, font_size, Color(InkDraw.INK, alpha))


## The white oval and tail, sized to fit `size`.
static func draw_shell(ci: CanvasItem, center: Vector2, size: Vector2, tail_tip: Vector2, seed_value: int,
		alpha: float = 1.0, outline_width: float = 3.0) -> void:
	var white: Color = Color(1, 1, 1, alpha)
	var ink: Color = Color(InkDraw.INK, alpha)
	var radii: Vector2 = size * Vector2(0.56, 0.5)
	var outline: PackedVector2Array = InkDraw.ellipse_points(center, radii, 36)
	ci.draw_colored_polygon(outline, white)
	InkDraw.polyline(ci, outline, outline_width, seed_value, true, ink, 1.0)
	if tail_tip == NO_TAIL:
		return
	var dir: Vector2 = (tail_tip - center).normalized()
	var side: Vector2 = Vector2(-dir.y, dir.x)
	var base: Vector2 = center + dir * minf(radii.x, radii.y) * 0.7
	var a: Vector2 = base + side * 9.0
	var b: Vector2 = base - side * 9.0
	ci.draw_colored_polygon(PackedVector2Array([a, b, tail_tip]), white)
	InkDraw.line(ci, a, tail_tip, outline_width, seed_value + 1, ink)
	InkDraw.line(ci, b, tail_tip, outline_width, seed_value + 2, ink)


static func baseline_for(center: Vector2, text_width: float, font_size: int) -> Vector2:
	var font: Font = ThemeDB.fallback_font
	return center + Vector2(-text_width * 0.5, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)


## Outline in the same colour thickens the default font into a comic bold.
static func draw_bold(ci: CanvasItem, baseline: Vector2, text: String, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	ci.draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, color)
	ci.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
