class_name BgHalls
extends RefCounted
## Frames 3-4 and the ending hallway: the landing outside the study, the
## study corridor, and the long hallway where Chapter 1 ends.


static func landing(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 23
	var paper: Color = InkDraw.PAPER
	_wainscot(ci, s)
	# Way back to the bedchamber.
	var arch: PackedVector2Array = PackedVector2Array([
		Vector2(24, 380), Vector2(24, 170), Vector2(40, 130), Vector2(80, 112), Vector2(120, 130), Vector2(136, 170), Vector2(136, 380)])
	ci.draw_colored_polygon(arch, Color(0.12, 0.11, 0.13))
	InkDraw.polyline(ci, arch, 5.0, s + 20)
	# Mouthless portraits; the middle one is tilted.
	var portraits: Array[Vector2] = [Vector2(250, 120), Vector2(470, 110), Vector2(690, 120)]
	for i in portraits.size():
		var c: Vector2 = portraits[i]
		var tilt: float = 0.12 if i == 1 else 0.0
		var corners: PackedVector2Array = PackedVector2Array()
		for corner in [Vector2(-50, -62), Vector2(50, -62), Vector2(50, 62), Vector2(-50, 62)]:
			corners.append(c + (corner as Vector2).rotated(tilt))
		InkDraw.shape(ci, corners, 5.0, s + 30 + i, paper)
		InkDraw.ellipse(ci, c + Vector2(0, -10).rotated(tilt), Vector2(22, 28), 2.5, s + 40 + i)
		ci.draw_circle(c + Vector2(-8, -16).rotated(tilt), 2.5, InkDraw.INK)
		ci.draw_circle(c + Vector2(8, -16).rotated(tilt), 2.5, InkDraw.INK)
		InkDraw.hatch(ci, Rect2(c.x - 44, c.y + 30, 88, 26), 7.0, 1.0, s + 60 + i)
	_sconces(ci, [360.0, 580.0, 800.0], s)
	_rug(ci, s)


static func study_corridor(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 29
	_wainscot(ci, s)
	# Bookshelves on the left, crammed.
	for shelf in 4:
		var y: float = 70.0 + shelf * 76.0
		InkDraw.line(ci, Vector2(40, y + 68), Vector2(330, y + 68), 4.0, s + shelf)
		var x: float = 46.0
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 77 + shelf
		while x < 320.0:
			var w: float = rng.randf_range(10, 22)
			var h: float = rng.randf_range(44, 64)
			InkDraw.rect(ci, Rect2(x, y + 68 - h, w, h), 1.5, s + int(x), InkDraw.PAPER if rng.randf() > 0.3 else Color(0.25, 0.24, 0.27), InkDraw.INK, 0.6)
			x += w + 2.0
	InkDraw.rect(ci, Rect2(34, 60, 302, 320), 5.0, s + 9)
	# Little table under the portrait for the candle.
	InkDraw.rect(ci, Rect2(860, 318, 110, 10), 3.0, s + 10, Color(0.78, 0.75, 0.68))
	InkDraw.line(ci, Vector2(872, 328), Vector2(872, 384), 4.0, s + 11)
	InkDraw.line(ci, Vector2(958, 328), Vector2(958, 384), 4.0, s + 12)
	_sconces(ci, [440.0], s)
	FrameBackground.doorway(ci, Rect2(1068, 150, 92, 232), s + 13)
	_rug(ci, s)


static func hallway(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 13
	_wainscot(ci, s)
	for i in 5:
		FrameBackground.doorway(ci, Rect2(160 + i * 210, 170, 70, 210), s + i * 4)


static func _wainscot(ci: FrameBackground, s: int) -> void:
	InkDraw.line(ci, Vector2(0, 250), Vector2(ci.panel_size.x, 250), 4.0, s + 1)
	for i in 10:
		InkDraw.rect(ci, Rect2(150.0 + i * 100.0, 272, 70, 84), 2.0, s + 2 + i)


## Wall brackets; the candles on them are LightSpots at (x, 120).
static func _sconces(ci: CanvasItem, xs: Array, s: int) -> void:
	for x in xs:
		InkDraw.line(ci, Vector2(x, 152), Vector2(x, 190), 3.0, s + 70)
		InkDraw.line(ci, Vector2(x - 14, 190), Vector2(x + 14, 190), 3.0, s + 72)


static func _rug(ci: FrameBackground, s: int) -> void:
	var rug: PackedVector2Array = PackedVector2Array([Vector2(160, 418), Vector2(980, 418), Vector2(1010, 496), Vector2(130, 496)])
	InkDraw.shape(ci, rug, 3.0, s + 80, Color(0.86, 0.83, 0.76))
	InkDraw.polyline(ci, PackedVector2Array([Vector2(170, 430), Vector2(976, 430), Vector2(998, 484), Vector2(142, 484)]), 1.5, s + 81, true)
