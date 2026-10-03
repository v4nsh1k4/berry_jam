class_name BgCh2Rooms
extends RefCounted
## Chapter 2, frames 4-6: the housekeeper's pantry, the clock room and the
## locked cellar stair.

const WOOD: Color = Color(0.78, 0.75, 0.68)


static func pantry(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 59
	# Shelves of jars.
	for shelf in 3:
		var y: float = 110.0 + shelf * 80.0
		InkDraw.line(ci, Vector2(80, y), Vector2(420, y), 5.0, s + shelf)
		for j in 6:
			var x: float = 96.0 + j * 54.0
			InkDraw.rect(ci, Rect2(x, y - 46, 34, 44), 2.0, s + 10 + shelf * 6 + j, Color(0.85, 0.85, 0.82))
			InkDraw.rect(ci, Rect2(x + 6, y - 52, 22, 8), 1.5, s + 40 + j, WOOD)
	# Hanging herbs.
	for i in 4:
		var x: float = 760.0 + i * 50.0
		InkDraw.line(ci, Vector2(x, 0), Vector2(x, 80), 1.5, s + 60 + i)
		InkDraw.shape(ci, PackedVector2Array([Vector2(x - 12, 80), Vector2(x + 12, 80), Vector2(x, 128)]), 2.0, s + 64 + i, Color(0.4, 0.4, 0.38))
	# Work table for Mrs. Vane's candle, sacks on the floor.
	InkDraw.rect(ci, Rect2(640, 312, 150, 14), 3.0, s + 70, WOOD)
	InkDraw.line(ci, Vector2(652, 326), Vector2(652, 384), 4.0, s + 71)
	InkDraw.line(ci, Vector2(778, 326), Vector2(778, 384), 4.0, s + 72)
	for x in [150.0, 230.0]:
		InkDraw.shape(ci, PackedVector2Array([Vector2(x - 30, 384), Vector2(x - 24, 320), Vector2(x, 306), Vector2(x + 24, 320), Vector2(x + 30, 384)]), 3.0, s + 73, InkDraw.PAPER)
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 80)


static func clock_room(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 61
	# Wall clocks with no hands.
	for c in [Vector2(160, 120), Vector2(380, 90), Vector2(820, 110), Vector2(1010, 96)]:
		InkDraw.ellipse(ci, c, Vector2(26, 26), 3.0, s + int(c.x), InkDraw.PAPER)
		ci.draw_circle(c, 3.0, InkDraw.INK)
	# Tall window behind the curtain spot.
	InkDraw.rect(ci, Rect2(230, 120, 120, 200), 4.0, s + 1, Color(0.2, 0.2, 0.24))
	# Patterned rug.
	var rug: PackedVector2Array = PackedVector2Array([Vector2(420, 424), Vector2(860, 424), Vector2(900, 494), Vector2(380, 494)])
	InkDraw.shape(ci, rug, 3.0, s + 2, Color(0.8, 0.77, 0.7))
	for i in 5:
		InkDraw.ellipse(ci, Vector2(470 + i * 90, 458), Vector2(18, 10), 1.5, s + 3 + i)
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 9)


static func cellar_stair(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 67
	# Low beams and cold stone.
	for x in [0.0, 300.0, 600.0, 900.0]:
		InkDraw.rect(ci, Rect2(x, 30, 300, 26), 3.0, s + int(x), Color(0.3, 0.28, 0.27))
	for row in 6:
		for col in 9:
			var x: float = col * 140.0 + (70.0 if row % 2 == 1 else 0.0)
			InkDraw.rect(ci, Rect2(x, 70 + row * 52, 134, 48), 1.2, s + row * 11 + col, Color.TRANSPARENT, Color(InkDraw.INK, 0.4), 1.6)
	# Cobwebs in the corners.
	for corner in [Vector2(0, 56), Vector2(ci.panel_size.x, 56)]:
		var dir: float = 1.0 if corner.x == 0.0 else -1.0
		for k in 4:
			InkDraw.line(ci, corner, corner + Vector2(dir * (40 + k * 22), 70 - k * 14), 1.0, s + 90 + k, Color(InkDraw.INK, 0.5))
