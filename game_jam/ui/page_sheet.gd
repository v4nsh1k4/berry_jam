class_name PageSheet
extends Node2D
## A blank comic page used by the slide transition. Origin is its left edge;
## the shadow is drawn just left of it (the leading edge while sliding left).

const SHADOW_WIDTH: float = 36.0

var page_size: Vector2 = Vector2(1280, 720)


func _draw() -> void:
	var tick: int = InkDraw.boil_tick()
	var shadow: PackedVector2Array = PackedVector2Array([
		Vector2(-SHADOW_WIDTH, 0), Vector2(0, 0), Vector2(0, page_size.y), Vector2(-SHADOW_WIDTH, page_size.y)])
	var dark: Color = Color(InkDraw.INK, 0.45)
	var clear: Color = Color(InkDraw.INK, 0.0)
	draw_polygon(shadow, PackedColorArray([clear, dark, dark, clear]))
	draw_rect(Rect2(Vector2.ZERO, page_size), InkDraw.WHITE)
	InkDraw.rect(self, Frame.PANEL_RECT, 7.0, tick, InkDraw.PAPER, InkDraw.INK, 1.6)
	InkDraw.hatch(self, Frame.PANEL_RECT.grow(-20), 18.0, 1.0, tick + 4, Color(InkDraw.INK, 0.25))
	InkDraw.line(self, Vector2(0, 0), Vector2(0, page_size.y), 4.0, tick + 9)
