class_name BgBedrooms
extends RefCounted
## Frames 1-2: the small room you wake in, and the rotted bedchamber.

const WOOD: Color = Color(0.78, 0.75, 0.68)


static func awakening(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 17
	var paper: Color = InkDraw.PAPER
	# Narrow bed you wake in, blanket thrown back.
	InkDraw.shape(ci, PackedVector2Array([Vector2(60, 240), Vector2(92, 228), Vector2(92, 400), Vector2(60, 400)]), 4.0, s + 1, paper)
	InkDraw.rect(ci, Rect2(92, 322, 240, 46), 4.0, s + 2, paper)
	InkDraw.ellipse(ci, Vector2(140, 310), Vector2(38, 16), 3.0, s + 3, InkDraw.WHITE)
	InkDraw.shape(ci, PackedVector2Array([Vector2(230, 318), Vector2(336, 300), Vector2(344, 372), Vector2(250, 372)]), 3.0, s + 4, paper)
	InkDraw.hatch(ci, Rect2(256, 330, 80, 38), 9.0, 1.0, s + 5)
	for x in [100.0, 320.0]:
		InkDraw.line(ci, Vector2(x, 368), Vector2(x, 402), 6.0, s + 6)
	# Nightstand (the candle on it is a LightSpot).
	InkDraw.rect(ci, Rect2(345, 310, 76, 72), 3.5, s + 7, WOOD)
	InkDraw.rect(ci, Rect2(355, 330, 56, 22), 2.0, s + 8)
	# The mirror: an oval with nothing in it.
	InkDraw.ellipse(ci, Vector2(640, 214), Vector2(66, 96), 6.0, s + 9, Color(0.3, 0.28, 0.3))
	InkDraw.ellipse(ci, Vector2(640, 214), Vector2(54, 84), 2.5, s + 10, Color(0.85, 0.85, 0.88))
	for i in 3:
		InkDraw.line(ci, Vector2(612 + i * 18, 160 + i * 8), Vector2(636 + i * 18, 136 + i * 8), 1.5, s + 11 + i, Color(InkDraw.INK, 0.4))
	InkDraw.line(ci, Vector2(640, 118), Vector2(640, 82), 2.0, s + 14)
	# Small window with the moon.
	var win: Rect2 = Rect2(820, 80, 120, 150)
	InkDraw.rect(ci, win, 4.0, s + 15, Color(0.2, 0.2, 0.24))
	ci.draw_circle(Vector2(880, 132), 18.0, paper)
	InkDraw.line(ci, Vector2(880, 82), Vector2(880, 228), 3.0, s + 16)
	InkDraw.line(ci, Vector2(822, 155), Vector2(938, 155), 3.0, s + 17)
	# Door out, ajar.
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 20, true)


static func bedchamber(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 19
	var paper: Color = InkDraw.PAPER
	# Window. Ink runs down the inside of the glass.
	var win: Rect2 = Rect2(110, 60, 190, 210)
	InkDraw.rect(ci, win, 4.0, s + 1, Color(0.2, 0.2, 0.24))
	ci.draw_circle(Vector2(240, 118), 26.0, paper)
	for i in 6:
		var x: float = win.position.x + 16.0 + i * 31.0
		var run: float = fmod(ci.time * (14.0 + i * 5.0) + i * 47.0, win.size.y + 60.0)
		var length: float = minf(run, win.size.y - 8.0)
		InkDraw.line(ci, Vector2(x, win.position.y + 4), Vector2(x + sin(i) * 3.0, win.position.y + 4 + length), 3.0 + (i % 2), s + 2 + i, InkDraw.INK, 0.8)
		ci.draw_circle(Vector2(x + sin(i) * 3.0, win.position.y + 4 + length), 4.0 + (i % 3), InkDraw.INK)
	InkDraw.line(ci, Vector2(205, 62), Vector2(205, 268), 4.0, s + 9)
	InkDraw.line(ci, Vector2(112, 165), Vector2(298, 165), 4.0, s + 10)
	# Torn curtains.
	for side in [-1.0, 1.0]:
		var x0: float = win.position.x - 14.0 if side < 0.0 else win.end.x - 30.0
		var curtain: PackedVector2Array = PackedVector2Array([
			Vector2(x0, 44), Vector2(x0 + 44, 44), Vector2(x0 + 34, 160), Vector2(x0 + 44, 214), Vector2(x0 + 26, 230), Vector2(x0 + 12, 290), Vector2(x0, 240)])
		InkDraw.shape(ci, curtain, 3.0, s + 11 + int(side), paper)
		InkDraw.hatch(ci, Rect2(x0 + 4, 60, 18, 170), 8.0, 1.0, s + 13)
	InkDraw.line(ci, Vector2(80, 44), Vector2(330, 44), 5.0, s + 14)

	# Crooked portrait of the house on the hill.
	InkDraw.shape(ci, PackedVector2Array([Vector2(560, 92), Vector2(668, 104), Vector2(658, 196), Vector2(550, 184)]), 5.0, s + 15, paper)
	InkDraw.polyline(ci, PackedVector2Array([Vector2(570, 176), Vector2(612, 120), Vector2(646, 180)]), 2.5, s + 16)
	InkDraw.rect(ci, Rect2(592, 150, 36, 30), 2.0, s + 17)

	# The rotted bed: holes, a tattered blanket, a pool of ink beneath.
	var pool: PackedVector2Array = InkDraw.ellipse_points(Vector2(610, 404), Vector2(190, 14), 18)
	ci.draw_colored_polygon(pool, Color(InkDraw.INK, 0.8))
	InkDraw.shape(ci, PackedVector2Array([Vector2(420, 236), Vector2(452, 222), Vector2(446, 300), Vector2(456, 400), Vector2(420, 400)]), 4.0, s + 18, paper)
	InkDraw.rect(ci, Rect2(452, 316, 330, 52), 4.0, s + 19, paper)
	for hole in [Vector2(520, 342), Vector2(700, 350), Vector2(610, 336)]:
		InkDraw.ellipse(ci, hole, Vector2(16, 7), 2.0, s + 20, InkDraw.INK)
	var blanket: PackedVector2Array = PackedVector2Array([
		Vector2(540, 300), Vector2(600, 288), Vector2(660, 304), Vector2(720, 292), Vector2(788, 306),
		Vector2(792, 360), Vector2(770, 344), Vector2(748, 372), Vector2(720, 352), Vector2(690, 380),
		Vector2(650, 356), Vector2(610, 384), Vector2(580, 350), Vector2(548, 372)])
	InkDraw.shape(ci, blanket, 3.5, s + 21, paper)
	InkDraw.hatch(ci, Rect2(560, 316, 220, 30), 10.0, 1.2, s + 22)
	InkDraw.line(ci, Vector2(770, 368), Vector2(776, 404), 6.0, s + 23)

	# Wardrobe, one door hanging off its hinge.
	var wardrobe: Rect2 = Rect2(860, 110, 150, 280)
	InkDraw.rect(ci, wardrobe, 4.0, s + 24, paper)
	InkDraw.rect(ci, Rect2(866, 116, 66, 268), 2.0, s + 25, Color(0.05, 0.05, 0.06))
	InkDraw.shape(ci, PackedVector2Array([Vector2(866, 120), Vector2(820, 140), Vector2(824, 380), Vector2(866, 384)]), 3.0, s + 26, WOOD)
	ci.draw_circle(Vector2(946, 250), 4.0, InkDraw.INK)
	InkDraw.line(ci, Vector2(850, 108), Vector2(1020, 108), 5.0, s + 27)

	# Far doorway where Arthur waits.
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 28)
