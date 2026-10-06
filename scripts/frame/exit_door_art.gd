class_name ExitDoorArt
extends RefCounted
## The door a gated exit draws for itself (ExitZone): shut with a padlock and
## chain while locked; on unlock the padlock drops and the leaf swings in,
## leaving a dark open doorway with a faint glow at its edge.

const WOOD: Color = Color(0.36, 0.3, 0.26)
const FRAME: Color = Color(0.2, 0.19, 0.22)


static func draw(ci: CanvasItem, r: Rect2, open: float, tick: int) -> void:
	var s: int = tick * 23
	InkDraw.rect(ci, r.grow(8), 5.0, s, FRAME)
	ci.draw_rect(r, Color(0.04, 0.04, 0.05))
	# The leaf narrows as it swings in.
	var w: float = r.size.x * (1.0 - 0.72 * ease(open, 0.6))
	var leaf: PackedVector2Array = PackedVector2Array([r.position, r.position + Vector2(w, 10.0 * open),
		r.position + Vector2(w, r.size.y - 10.0 * open), r.position + Vector2(0, r.size.y)])
	InkDraw.shape(ci, leaf, 3.5, s + 1, WOOD)
	if open > 0.98:
		InkDraw.rect(ci, r.grow(-2), 2.0, s + 2, Color.TRANSPARENT, Color(1.0, 0.95, 0.7, 0.45))
		return
	# Chain across the door and the padlock, dropping as it opens.
	var a: float = 1.0 - open
	var mid: Vector2 = r.get_center() + Vector2(0, open * open * 150.0)
	InkDraw.line(ci, r.position + Vector2(6, r.size.y * 0.5), r.end - Vector2(6, r.size.y * 0.5), 4.0, s + 3, Color(0.5, 0.5, 0.52, a))
	InkDraw.ellipse(ci, mid + Vector2(0, -16), Vector2(12, 13), 4.0, s + 4, Color.TRANSPARENT, Color(InkDraw.INK, a))
	InkDraw.rect(ci, Rect2(mid + Vector2(-17, -8), Vector2(34, 28)), 3.0, s + 5, Color(0.55, 0.53, 0.5, a), Color(InkDraw.INK, a))
	ci.draw_circle(mid + Vector2(0, 5), 4.0, Color(InkDraw.INK, a))
