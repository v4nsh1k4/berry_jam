class_name BgCh3End
extends RefCounted
## The end of Chapter 3: the Ink Heart (the Shadow's lair, the worst-drawn
## panel in the comic) and the Last Page (clean again, morning light).

const VOID: Color = Color(0.03, 0.03, 0.04)
const SKETCH: Color = Color(0.06, 0.05, 0.07, 0.35)


static func ink_heart(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 89
	var size: Vector2 = ci.panel_size
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	# Rough construction lines: the room was never properly drawn.
	for i in 22:
		var a: Vector2 = Vector2(rng.randf_range(-100, size.x), rng.randf_range(0, 360))
		InkDraw.line(ci, a, a + Vector2(rng.randf_range(200, 600), rng.randf_range(-60, 60)), 1.0, s + i, SKETCH, 3.0)
	# Panels from earlier pages, knocked askew and half sunk in ink.
	for i in 5:
		var c: Vector2 = Vector2(110 + i * 170, 120 + rng.randf_range(-40, 60))
		var half: Vector2 = Vector2(rng.randf_range(60, 90), rng.randf_range(45, 70))
		var turn: float = rng.randf_range(-0.5, 0.5)
		var corners: PackedVector2Array = PackedVector2Array()
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			corners.append(c + (half * (corner as Vector2)).rotated(turn))
		InkDraw.shape(ci, corners, 3.0, s + 10 + i, InkDraw.PAPER)
		InkDraw.line(ci, corners[0].lerp(corners[3], 0.7), corners[1].lerp(corners[2], 0.4), 2.0, s + 20 + i)
		InkDraw.line(ci, c + Vector2(-20, 30).rotated(turn), c + Vector2(-20, -10).rotated(turn), 2.0, s + 30 + i)
	# The lair: ink pooled on the floor to the right, and running down the
	# wall above it in streaks (the Shadow must still read against it).
	var pool: PackedVector2Array = PackedVector2Array([Vector2(size.x, 340), Vector2(1080, 372), Vector2(930, 392),
		Vector2(760, 440), Vector2(700, 500), Vector2(780, size.y), Vector2(size.x, size.y)])
	InkDraw.fill(ci, pool, VOID)
	InkDraw.polyline(ci, pool, 4.0, s + 40, false, InkDraw.INK, 4.0)
	for i in 7:
		var x: float = 940.0 + i * 36.0
		InkDraw.line(ci, Vector2(x, 0), Vector2(x + rng.randf_range(-8, 8), rng.randf_range(160, 340)), rng.randf_range(4, 9), s + 41 + i)
	# Drips off the panels and the broken floor line.
	for i in 9:
		var x: float = 60.0 + i * 85.0
		InkDraw.line(ci, Vector2(x, 210 + (i % 3) * 20), Vector2(x + 2, 300 + (i % 4) * 25), 3.0, s + 50 + i)
	var font: Font = ThemeDB.fallback_font
	ci.draw_string(font, Vector2(200, 330), "Author's note: start this page over", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(InkDraw.INK, 0.6))
	ci.draw_string(font, Vector2(560, 60), "ERASE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(InkDraw.INK, 0.55))
	InkDraw.line(ci, Vector2(555, 50), Vector2(660, 44), 3.0, s + 60)


static func escape(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 97
	# Morning: a tall window, a rug, the panelling drawn neatly again.
	InkDraw.rect(ci, Rect2(700, 50, 170, 230), 4.0, s, Color(0.97, 0.96, 0.92))
	InkDraw.line(ci, Vector2(785, 52), Vector2(785, 278), 3.0, s + 1)
	InkDraw.line(ci, Vector2(702, 165), Vector2(868, 165), 3.0, s + 2)
	for i in 5:
		InkDraw.line(ci, Vector2(720 + i * 30, 290), Vector2(640 + i * 60, 380), 1.0, s + 3 + i, Color(InkDraw.INK, 0.25))
	InkDraw.shape(ci, InkDraw.ellipse_points(Vector2(600, 462), Vector2(360, 38), 24), 2.5, s + 10, Color(0.9, 0.88, 0.82))
