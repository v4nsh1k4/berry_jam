class_name NpcArt
extends RefCounted
## Procedural drawing for each NpcData.visual_style. Origin: feet for
## standing characters, picture centre for portraits.


static func mouth(style: StringName) -> Vector2:
	match style:
		&"portrait":
			return Vector2(0, 12)
		&"housekeeper":
			return Vector2(-5, -150)
	return Vector2(-6, -168)


static func default_bubble_spots(style: StringName) -> PackedVector2Array:
	match style:
		&"portrait":
			return PackedVector2Array([Vector2(190, -40)])
		&"housekeeper":
			return PackedVector2Array([Vector2(-190, -196), Vector2(-292, -292), Vector2(200, -214)])
	# Lower pair close in, upper pair further out: each tail runs from the
	# mouth above the bubble below it instead of through it.
	return PackedVector2Array([Vector2(-195, -210), Vector2(-305, -305), Vector2(195, -222), Vector2(305, -318)])


static func draw(ci: CanvasItem, style: StringName, tick: int) -> void:
	match style:
		&"butler":
			_butler(ci, tick * 19)
		&"portrait":
			_portrait(ci, tick * 23)
		&"housekeeper":
			_housekeeper(ci, tick * 29)
		_:
			InkDraw.ellipse(ci, Vector2(0, -90), Vector2(24, 90), 3.0, tick)


## Arthur the Butler, facing left. Tall, bald, tailcoat, waxed moustache.
static func _butler(ci: CanvasItem, s: int) -> void:
	var coat: Color = Color(0.2, 0.19, 0.22)
	InkDraw.line(ci, Vector2(-7, -84), Vector2(-9, -2), 5.0, s + 1)
	InkDraw.line(ci, Vector2(7, -84), Vector2(6, -2), 5.0, s + 2)
	InkDraw.line(ci, Vector2(-9, -2), Vector2(-24, -2), 6.0, s + 3)
	InkDraw.line(ci, Vector2(6, -2), Vector2(-8, -2), 6.0, s + 4)
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(-20, -150), Vector2(20, -150), Vector2(22, -96), Vector2(36, -44),
		Vector2(18, -50), Vector2(12, -84), Vector2(-18, -84)])
	InkDraw.shape(ci, body, 3.0, s + 5, coat)
	InkDraw.shape(ci, PackedVector2Array([Vector2(-10, -150), Vector2(4, -150), Vector2(-3, -104)]), 2.0, s + 6, InkDraw.WHITE)
	InkDraw.shape(ci, PackedVector2Array([Vector2(-12, -150), Vector2(-3, -145), Vector2(6, -150), Vector2(6, -140), Vector2(-3, -145), Vector2(-12, -140)]), 2.0, s + 7, InkDraw.INK)
	InkDraw.polyline(ci, PackedVector2Array([Vector2(16, -146), Vector2(22, -112), Vector2(18, -86)]), 4.0, s + 8)
	InkDraw.polyline(ci, PackedVector2Array([Vector2(-16, -146), Vector2(-24, -116), Vector2(-4, -110)]), 4.0, s + 9)
	InkDraw.shape(ci, PackedVector2Array([Vector2(-20, -116), Vector2(-6, -114), Vector2(-8, -88), Vector2(-18, -92)]), 2.0, s + 10, InkDraw.WHITE)
	InkDraw.ellipse(ci, Vector2(0, -174), Vector2(14, 20), 3.0, s + 11, InkDraw.PAPER)
	ci.draw_circle(Vector2(-7, -178), 2.2, InkDraw.INK)
	ci.draw_circle(Vector2(3, -178), 2.2, InkDraw.INK)
	InkDraw.polyline(ci, PackedVector2Array([Vector2(-18, -162), Vector2(-10, -166), Vector2(-3, -164), Vector2(4, -166), Vector2(10, -161)]), 3.0, s + 12)


## A lady in an oval portrait frame, the only portrait with a mouth.
static func _portrait(ci: CanvasItem, s: int) -> void:
	InkDraw.rect(ci, Rect2(-62, -78, 124, 156), 7.0, s + 1, Color(0.3, 0.28, 0.3))
	InkDraw.ellipse(ci, Vector2.ZERO, Vector2(50, 66), 3.0, s + 2, InkDraw.PAPER)
	InkDraw.ellipse(ci, Vector2(0, -36), Vector2(22, 14), 2.5, s + 3, InkDraw.INK)
	InkDraw.ellipse(ci, Vector2(0, -8), Vector2(18, 23), 2.5, s + 4, InkDraw.WHITE)
	ci.draw_circle(Vector2(-7, -12), 2.0, InkDraw.INK)
	ci.draw_circle(Vector2(7, -12), 2.0, InkDraw.INK)
	InkDraw.ellipse(ci, Vector2(0, 5), Vector2(4, 3), 1.5, s + 5, InkDraw.INK)
	InkDraw.polyline(ci, PackedVector2Array([Vector2(-40, 62), Vector2(-24, 22), Vector2(24, 22), Vector2(40, 62)]), 2.5, s + 6)
	InkDraw.hatch(ci, Rect2(-38, 32, 76, 28), 7.0, 1.0, s + 7)


## Mrs. Vane the Housekeeper: bun, long dress, apron, a ring of keys. Anxious:
## every few seconds her head snaps round to stare into the dark.
static func _housekeeper(ci: CanvasItem, s: int) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var glance: float = 1.0 if fmod(t, 3.4) > 2.5 else 0.0
	var dress: Color = Color(0.24, 0.23, 0.26)
	var skirt: PackedVector2Array = PackedVector2Array([
		Vector2(-16, -118), Vector2(16, -118), Vector2(34, -2), Vector2(-34, -2)])
	InkDraw.shape(ci, skirt, 3.0, s + 1, dress)
	InkDraw.shape(ci, PackedVector2Array([Vector2(-12, -112), Vector2(12, -112), Vector2(20, -24), Vector2(-20, -24)]), 2.5, s + 2, InkDraw.WHITE)
	InkDraw.shape(ci, PackedVector2Array([Vector2(-15, -136), Vector2(15, -136), Vector2(16, -112), Vector2(-16, -112)]), 3.0, s + 3, dress)
	# Arms clutched in, keys hanging at her waist.
	InkDraw.polyline(ci, PackedVector2Array([Vector2(-14, -132), Vector2(-20, -108), Vector2(-4, -100)]), 4.0, s + 4)
	InkDraw.polyline(ci, PackedVector2Array([Vector2(14, -132), Vector2(18, -108), Vector2(2, -100)]), 4.0, s + 5)
	InkDraw.ellipse(ci, Vector2(14, -92), Vector2(7, 7), 2.0, s + 6)
	for i in 3:
		InkDraw.line(ci, Vector2(14, -86), Vector2(10 + i * 4, -72), 1.5, s + 7 + i)
	# Head turns hard to the right when she glances at the dark.
	var head: Vector2 = Vector2(4.0 * glance, -152)
	InkDraw.ellipse(ci, head, Vector2(13, 15), 3.0, s + 10, InkDraw.PAPER)
	InkDraw.ellipse(ci, head + Vector2(-2 + 6 * glance, -16), Vector2(9, 7), 2.5, s + 11, InkDraw.INK)
	var eye_shift: float = 6.0 * glance - 4.0
	ci.draw_circle(head + Vector2(eye_shift - 3, -3), 2.0, InkDraw.INK)
	ci.draw_circle(head + Vector2(eye_shift + 5, -3), 2.0, InkDraw.INK)
	InkDraw.line(ci, head + Vector2(eye_shift - 3, 7), head + Vector2(eye_shift + 4, 7), 2.0, s + 12)
