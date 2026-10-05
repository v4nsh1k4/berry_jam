class_name BgCh2Halls
extends RefCounted
## Chapter 2, frames 1-3: the long hallway, the portrait gallery and the
## servants' passage. The drawing is rougher here (InkDraw.jitter_scale).

const WOOD: Color = Color(0.78, 0.75, 0.68)


static func long_hallway(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 43
	# A row of dim landscape paintings down the hall (no doors: the only way
	# on is the inked-over door at the far end).
	for i in 4:
		var x: float = 150.0 + i * 230.0
		var r: Rect2 = Rect2(x, 196 + i * 4, 110 - i * 6, 80 - i * 4)
		InkDraw.rect(ci, r.grow(7), 4.0, s + i, Color(0.2, 0.19, 0.22))
		InkDraw.rect(ci, r, 2.0, s + 10 + i, Color(0.72, 0.7, 0.64))
		InkDraw.polyline(ci, PackedVector2Array([r.position + Vector2(0, r.size.y * 0.7), r.position + Vector2(r.size.x * 0.35, r.size.y * 0.4),
			r.position + Vector2(r.size.x * 0.6, r.size.y * 0.62), r.end - Vector2(0, r.size.y * 0.45)]), 2.0, s + 14 + i)
	# Wallpaper peeling in curls.
	for i in 6:
		var x: float = 110.0 + i * 170.0
		InkDraw.shape(ci, PackedVector2Array([Vector2(x, 60), Vector2(x + 34, 60), Vector2(x + 22, 120), Vector2(x + 8, 96)]), 2.0, s + 20 + i, InkDraw.PAPER)
		InkDraw.hatch(ci, Rect2(x, 60, 30, 34), 6.0, 1.0, s + 30 + i)
	# The end of the hall: blank panelling (the secret door sits here).
	InkDraw.rect(ci, Rect2(1040, 110, 140, 272), 4.0, s + 40, Color(0.74, 0.71, 0.64))
	_runner(ci, s)


static func gallery(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 47
	var paper: Color = InkDraw.PAPER
	var spots: Array[Vector2] = [Vector2(170, 130), Vector2(370, 120), Vector2(570, 132), Vector2(770, 118), Vector2(960, 128)]
	for i in spots.size():
		var c: Vector2 = spots[i]
		InkDraw.rect(ci, Rect2(c - Vector2(56, 70), Vector2(112, 140)), 6.0, s + i, paper)
		if i == 3:
			continue  # an empty frame
		InkDraw.ellipse(ci, c + Vector2(0, -12), Vector2(24, 30), 2.5, s + 10 + i)
		if i % 2 == 0:
			# Face scribbled out.
			for k in 6:
				InkDraw.line(ci, c + Vector2(-20, -30 + k * 7), c + Vector2(20, -24 + k * 7), 2.0, s + 20 + i * 6 + k)
		InkDraw.hatch(ci, Rect2(c.x - 50, c.y + 30, 100, 36), 7.0, 1.0, s + 40 + i)
	# Two plinths with busts.
	for x in [270.0, 870.0]:
		InkDraw.rect(ci, Rect2(x - 26, 290, 52, 92), 3.0, s + 50, WOOD)
		InkDraw.ellipse(ci, Vector2(x, 268), Vector2(18, 22), 3.0, s + 51, paper)
	InkDraw.line(ci, Vector2(0, 236), Vector2(ci.panel_size.x, 236), 2.0, s + 52)


static func passage(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 53
	# Pipes along the ceiling.
	for y in [52.0, 76.0]:
		InkDraw.line(ci, Vector2(0, y), Vector2(ci.panel_size.x, y), 7.0, s + int(y))
		for i in 6:
			InkDraw.rect(ci, Rect2(80 + i * 200, y - 8, 14, 16), 2.0, s + i, Color(0.3, 0.29, 0.31))
	# Bare brick, roughly hatched.
	for row in 5:
		for col in 12:
			var x: float = col * 100.0 + (50.0 if row % 2 == 1 else 0.0)
			InkDraw.rect(ci, Rect2(x, 120 + row * 46, 96, 42), 1.2, s + row * 13 + col, Color.TRANSPARENT, Color(InkDraw.INK, 0.45), 1.5)
	# Laundry line with a sheet.
	InkDraw.line(ci, Vector2(440, 110), Vector2(820, 120), 1.5, s + 90)
	InkDraw.shape(ci, PackedVector2Array([Vector2(480, 112), Vector2(600, 115), Vector2(596, 250), Vector2(560, 236), Vector2(520, 256), Vector2(484, 240)]), 2.5, s + 91, InkDraw.PAPER)
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 92)


static func _runner(ci: FrameBackground, s: int) -> void:
	var rug: PackedVector2Array = PackedVector2Array([Vector2(120, 420), Vector2(1020, 420), Vector2(1050, 496), Vector2(90, 496)])
	InkDraw.shape(ci, rug, 3.0, s + 80, Color(0.82, 0.79, 0.72))
