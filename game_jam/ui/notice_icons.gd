class_name NoticeIcons
extends RefCounted
## The noticed meter's two cause icons: a torch (light) and a footprint
## (running noise). Each lights up while it is feeding the meter.


static func draw(ci: CanvasItem, torch_at: Vector2, light: bool, foot_at: Vector2, noise: bool, tick: int) -> void:
	var font: Font = ThemeDB.fallback_font
	var on: Color = InkDraw.RED
	var off: Color = Color(InkDraw.INK, 0.3)
	# Torch: a barrel and a beam.
	var c: Color = on if light else off
	InkDraw.rect(ci, Rect2(torch_at + Vector2(-10, -5), Vector2(14, 10)), 2.0, tick, c, InkDraw.INK)
	ci.draw_colored_polygon(PackedVector2Array([torch_at + Vector2(4, -5), torch_at + Vector2(16, -10), torch_at + Vector2(16, 10), torch_at + Vector2(4, 5)]),
		Color(c, 0.7 if light else 0.25))
	ci.draw_string(font, torch_at + Vector2(-30, 4), "LIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c)
	# Footprint: a sole and four toes.
	c = on if noise else off
	ci.draw_colored_polygon(InkDraw.ellipse_points(foot_at + Vector2(2, 2), Vector2(6, 9), 12), c)
	for i in 4:
		ci.draw_circle(foot_at + Vector2(-4 + i * 3.5, -10 - (1.5 if i == 1 or i == 2 else 0.0)), 2.0, c)
	ci.draw_string(font, foot_at + Vector2(-34, 4), "NOISE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c)
