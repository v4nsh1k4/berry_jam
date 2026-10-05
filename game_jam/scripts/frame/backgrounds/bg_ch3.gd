class_name BgCh3
extends RefCounted
## Chapter 3, The Ink Heart: the comic coming apart. Rooms are drawn worse
## and worse (FrameData.sketch leaves strokes out on top of this).

const WOOD: Color = Color(0.78, 0.75, 0.68)
const VOID: Color = Color(0.03, 0.03, 0.04)


static func torn_page(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 71
	# A tear across the page: the black behind the comic shows through.
	var tear: PackedVector2Array = PackedVector2Array([Vector2(0, 40), Vector2(260, 70), Vector2(420, 30), Vector2(640, 110),
		Vector2(820, 60), Vector2(1184, 150), Vector2(1184, 210), Vector2(860, 130), Vector2(650, 180), Vector2(430, 95),
		Vector2(250, 140), Vector2(0, 110)])
	InkDraw.fill(ci, tear, VOID)
	InkDraw.polyline(ci, tear, 3.0, s, true, InkDraw.INK, 2.5)
	# Shards of other panels drifting in the dark.
	for i in 5:
		var c: Vector2 = Vector2(120 + i * 240, 90 + (i % 2) * 30)
		var corners: PackedVector2Array = PackedVector2Array()
		for corner in [Vector2(-34, -20), Vector2(34, -20), Vector2(34, 20), Vector2(-34, 20)]:
			corners.append(c + (corner as Vector2).rotated(0.4 * (i - 2)))
		InkDraw.shape(ci, corners, 2.0, s + 10 + i, InkDraw.PAPER)
	FrameBackground.doorway(ci, Rect2(1068, 170, 92, 212), s + 20)


static func returning_room(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 73
	# A small, calm room: window, armchair, a rug. Nothing is torn here.
	InkDraw.rect(ci, Rect2(180, 90, 150, 170), 4.0, s, Color(0.25, 0.25, 0.3))
	InkDraw.line(ci, Vector2(255, 92), Vector2(255, 258), 3.0, s + 1)
	InkDraw.shape(ci, PackedVector2Array([Vector2(330, 384), Vector2(340, 290), Vector2(420, 280), Vector2(430, 384)]), 3.0, s + 2, WOOD)
	InkDraw.rect(ci, Rect2(326, 320, 112, 30), 3.0, s + 3, InkDraw.PAPER)
	var rug: PackedVector2Array = InkDraw.ellipse_points(Vector2(600, 455), Vector2(330, 40), 24)
	InkDraw.shape(ci, rug, 2.5, s + 4, Color(0.84, 0.81, 0.74))
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 5)


static func gallery_words(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 79
	# A long wall for three portraits, a rail, the floor crumbling into sketch.
	InkDraw.line(ci, Vector2(0, 96), Vector2(ci.panel_size.x, 96), 3.0, s)
	for i in 6:
		InkDraw.line(ci, Vector2(60 + i * 200, 380), Vector2(10 + i * 200, 528), 2.0, s + i, Color(InkDraw.INK, 0.6), 4.0)


static func margin(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 83
	# The page margin: ruled lines, crossed-out panels and notes in a hand
	# that isn't any character's.
	for i in 9:
		InkDraw.line(ci, Vector2(0, 60 + i * 38), Vector2(ci.panel_size.x, 60 + i * 38), 1.0, s + i, Color(0.35, 0.4, 0.6, 0.45), 1.0)
	for c in [Vector2(260, 150), Vector2(700, 120)]:
		var r: Rect2 = Rect2(c - Vector2(80, 50), Vector2(160, 100))
		InkDraw.rect(ci, r, 2.0, s + int(c.x), Color.TRANSPARENT)
		InkDraw.line(ci, r.position, r.end, 3.0, s + 50)
		InkDraw.line(ci, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), 3.0, s + 51)
	var font: Font = ThemeDB.fallback_font
	# The Artist's pencil notes in the margin (atmosphere, signed so it's clear
	# whose they are and who they mean).
	ci.draw_string(font, Vector2(430, 230), "Artist's note: fix this page", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(InkDraw.INK, 0.7))
	ci.draw_string(font, Vector2(820, 200), "erase the red one?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(InkDraw.INK, 0.7))
	ci.draw_string(font, Vector2(860, 300), "...no. It gave them back.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(InkDraw.INK, 0.6))
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 60)
