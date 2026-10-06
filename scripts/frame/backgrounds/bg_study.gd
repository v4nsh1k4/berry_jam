class_name BgStudy
extends RefCounted
## Frames 5-6: the study (cabinet, alcove, symbol door) and the back room
## where the flashlight waits.

const WOOD: Color = Color(0.78, 0.75, 0.68)


static func study(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 37
	var paper: Color = InkDraw.PAPER
	# Writing desk: papers, an inkwell, a pen.
	InkDraw.rect(ci, Rect2(160, 300, 270, 16), 4.0, s + 1, WOOD)
	InkDraw.rect(ci, Rect2(170, 316, 80, 64), 3.0, s + 2, WOOD)
	InkDraw.line(ci, Vector2(420, 316), Vector2(420, 384), 5.0, s + 3)
	InkDraw.shape(ci, PackedVector2Array([Vector2(330, 300), Vector2(392, 292), Vector2(400, 298), Vector2(338, 306)]), 1.5, s + 4, InkDraw.WHITE)
	InkDraw.rect(ci, Rect2(210, 284, 22, 16), 2.0, s + 5, InkDraw.INK)
	InkDraw.line(ci, Vector2(222, 286), Vector2(250, 240), 2.0, s + 6)
	# Tall bookcase.
	InkDraw.rect(ci, Rect2(470, 90, 150, 290), 4.0, s + 7, paper)
	for i in 4:
		InkDraw.line(ci, Vector2(476, 150 + i * 60), Vector2(614, 150 + i * 60), 3.0, s + 8 + i)
		InkDraw.hatch(ci, Rect2(480, 100 + i * 60, 128, 46), 6.0, 1.0, s + 12 + i)
	# The alcove the cabinet hides: a dark recess in the wall.
	var alcove: PackedVector2Array = PackedVector2Array([
		Vector2(710, 380), Vector2(710, 170), Vector2(740, 136), Vector2(820, 136), Vector2(850, 170), Vector2(850, 380)])
	ci.draw_colored_polygon(alcove, Color(0.16, 0.15, 0.17))
	InkDraw.polyline(ci, alcove, 4.0, s + 17)


static func exit_room(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 41
	# Skylight with the moon (a LightSpot shines through it).
	InkDraw.rect(ci, Rect2(520, 0, 160, 40), 4.0, s + 1, Color(0.2, 0.2, 0.24))
	InkDraw.line(ci, Vector2(600, 0), Vector2(600, 40), 3.0, s + 2)
	# Stairs going down on the left.
	for i in 6:
		InkDraw.line(ci, Vector2(40 + i * 34, 220 + i * 28), Vector2(110 + i * 34, 220 + i * 28), 3.0, s + 3 + i)
		InkDraw.line(ci, Vector2(110 + i * 34, 220 + i * 28), Vector2(110 + i * 34, 248 + i * 28), 3.0, s + 9 + i)
	InkDraw.line(ci, Vector2(30, 200), Vector2(260, 390), 4.0, s + 16)
	# Coats on pegs.
	for i in 3:
		var x: float = 780.0 + i * 70.0
		InkDraw.line(ci, Vector2(x, 140), Vector2(x, 150), 4.0, s + 20 + i)
		InkDraw.shape(ci, PackedVector2Array([Vector2(x, 150), Vector2(x + 26, 190), Vector2(x + 20, 300), Vector2(x - 20, 300), Vector2(x - 26, 190)]), 3.0, s + 24 + i, Color(0.25, 0.24, 0.27))
	# The door out to the hallway.
	var door: Rect2 = Rect2(1068, 150, 92, 232)
	InkDraw.rect(ci, door.grow(9), 5.0, s + 30, Color(0.2, 0.19, 0.22))
	InkDraw.rect(ci, door, 4.0, s + 31, WOOD)
	ci.draw_circle(Vector2(1080, 272), 5.0, InkDraw.INK)
