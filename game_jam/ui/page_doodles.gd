class_name PageDoodles
extends RefCounted
## Little hand-drawn margin doodles (FrameData.doodles: the Awakening and each
## chapter's first room): tiny margin characters, stars, scribbles, arrows,
## a panel number, a "meanwhile..." box and speed lines, all faint and in the
## gutters or the panel's corners so they never cover play.

const FAINT: Color = Color(0.06, 0.05, 0.07, 0.45)


static func draw(ci: CanvasItem, panel: Rect2, screen: Vector2, tick: int) -> void:
	var s: int = tick * 5
	var font: Font = ThemeDB.fallback_font
	# Panel number in the top-right corner.
	var num: Vector2 = Vector2(panel.end.x - 26, panel.position.y + 24)
	InkDraw.ellipse(ci, num, Vector2(14, 14), 2.0, s, Color(1, 1, 1, 0.8), FAINT)
	ci.draw_string(font, num + Vector2(-4, 6), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, FAINT)
	# Speed lines off the right edge of the panel.
	for i in 5:
		var y: float = panel.position.y + 140 + i * 18
		InkDraw.line(ci, Vector2(panel.end.x + 6, y), Vector2(panel.end.x + 30 - i * 3, y + 2), 1.5, s + 1 + i, FAINT)
	# A tiny margin character in the left gutter, waving.
	var feet: Vector2 = Vector2(24, panel.position.y + 300)
	InkDraw.ellipse(ci, feet + Vector2(0, -34), Vector2(5, 6), 1.5, s + 10, Color.TRANSPARENT, FAINT)
	InkDraw.line(ci, feet + Vector2(0, -28), feet + Vector2(0, -12), 1.5, s + 11, FAINT)
	InkDraw.line(ci, feet + Vector2(0, -12), feet + Vector2(-5, 0), 1.5, s + 12, FAINT)
	InkDraw.line(ci, feet + Vector2(0, -12), feet + Vector2(5, 0), 1.5, s + 13, FAINT)
	InkDraw.line(ci, feet + Vector2(0, -24), feet + Vector2(9, -32 + sin(tick * 0.9) * 3.0), 1.5, s + 14, FAINT)
	# Another peeking over the top edge, and stars.
	var peek: Vector2 = Vector2(panel.position.x + 560, panel.position.y - 4)
	InkDraw.ellipse(ci, peek + Vector2(0, -8), Vector2(9, 7), 1.5, s + 20, Color(1, 1, 1, 0.8), FAINT)
	ci.draw_circle(peek + Vector2(-3, -9), 1.3, FAINT)
	ci.draw_circle(peek + Vector2(3, -9), 1.3, FAINT)
	for p in [Vector2(panel.position.x + 420, 12), Vector2(panel.end.x - 180, 14), Vector2(screen.x - 22, panel.position.y + 420)]:
		_star(ci, p, 6.0, s + int(p.x))
	# A scribble and an arrow in the bottom gutter.
	var sc: Vector2 = Vector2(panel.position.x + 40, panel.end.y + 10)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 9:
		pts.append(sc + Vector2(i * 7.0, (6.0 if i % 2 == 0 else -2.0)))
	InkDraw.polyline(ci, pts, 1.5, s + 30, false, FAINT)
	var a: Vector2 = Vector2(panel.end.x - 120, panel.end.y + 12)
	InkDraw.line(ci, a, a + Vector2(60, 0), 1.5, s + 31, FAINT)
	InkDraw.polyline(ci, PackedVector2Array([a + Vector2(52, -5), a + Vector2(60, 0), a + Vector2(52, 5)]), 1.5, s + 32, false, FAINT)
	# "meanwhile..." caption box in the top margin.
	var box: Rect2 = Rect2(panel.end.x - 330, 6, 120, 20)
	InkDraw.rect(ci, box, 1.5, s + 40, Color(1.0, 0.97, 0.86, 0.85), FAINT)
	ci.draw_string(font, box.position + Vector2(8, 15), "meanwhile...", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, FAINT)


static func _star(ci: CanvasItem, c: Vector2, r: float, s: int) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 11:
		var a: float = -PI * 0.5 + TAU * i / 10.0
		pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.45))
	InkDraw.polyline(ci, pts, 1.2, s, false, FAINT)
