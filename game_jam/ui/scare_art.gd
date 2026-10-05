class_name ScareArt
extends RefCounted
## Full-screen scare drawings for JumpscareOverlay (screen space, `t` seconds
## into a 0.3-0.5 s scare, `seed` fixed per scare).
##   face      the Crawler's face fills the screen (Clock Room)
##   portrait  a gallery portrait snaps its face round at the camera
##   wardrobe  a wardrobe door flies open on a pulled-in face
##   lights    the lights die; the face is right beside the player
##   hand      the Artist's hand slams across the page with a nib stab


static func draw(ci: CanvasItem, art: StringName, screen: Vector2, t: float, seed_value: int, player: Vector2) -> void:
	match art:
		&"face":
			ci.draw_rect(Rect2(Vector2.ZERO, screen), InkDraw.PAPER)
			face(ci, screen * 0.5, 1.0 + t * 0.6, seed_value)
		&"portrait":
			_portrait(ci, screen, t, seed_value)
		&"wardrobe":
			_wardrobe(ci, screen, t, seed_value)
		&"lights":
			ci.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.01, 0.02))
			if t > 0.12:
				face(ci, player + Vector2(150, -120), 0.55 + (t - 0.12) * 0.5, seed_value)
		&"hand":
			_hand(ci, screen, t, seed_value)


## The Crawler's face: a pen-slashed ink head, staring eyes, a torn mouth
## ringed with nibs. `grow` 1 = fills the screen.
static func face(ci: CanvasItem, c: Vector2, grow: float, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	c += Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10))
	for i in 26:
		var a: float = rng.randf() * TAU
		var from: Vector2 = c + Vector2.from_angle(a) * rng.randf_range(120, 220) * grow
		InkDraw.line(ci, from, from + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * rng.randf_range(200, 600) * grow, rng.randf_range(4, 14) * grow, i, InkDraw.INK, 6.0)
	var head: PackedVector2Array = PackedVector2Array()
	for i in 22:
		var a: float = TAU * i / 22.0
		head.append(c + Vector2(cos(a) * 300.0, sin(a) * 330.0) * grow * rng.randf_range(0.82, 1.12))
	InkDraw.fill(ci, head, InkDraw.INK)
	var eyes: Array[Vector3] = [Vector3(-120, -90, 46), Vector3(95, -110, 30), Vector3(10, -10, 24), Vector3(170, 20, 14), Vector3(-200, 10, 12)]
	for e in eyes:
		var at: Vector2 = c + Vector2(e.x, e.y) * grow
		ci.draw_circle(at, e.z * grow, CrawlerArt.PALE)
		ci.draw_circle(at + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)), e.z * 0.22 * grow, InkDraw.INK)
	var mouth: PackedVector2Array = PackedVector2Array()
	for i in 12:
		mouth.append(c + Vector2(-230 + i * 42, 110 + rng.randf_range(-14, 14)) * grow)
	for i in range(11, -1, -1):
		mouth.append(c + Vector2(-230 + i * 42, 230 + rng.randf_range(-30, 30) - absf(i - 5.5) * 8.0) * grow)
	InkDraw.fill(ci, mouth, Color(0.85, 0.82, 0.76))
	for i in 11:
		CrawlerArt.nib(ci, c + Vector2(-210 + i * 42, 128) * grow, PI * 0.5, 16.0 * grow)
		CrawlerArt.nib(ci, c + Vector2(-210 + i * 42, 205) * grow, -PI * 0.5, 14.0 * grow)


## A gilt frame; the painted face whips round (squash) and stares, hollow-eyed.
static func _portrait(ci: CanvasItem, screen: Vector2, t: float, seed_value: int) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.1, 0.09, 0.11))
	var c: Vector2 = screen * 0.5
	var frame: Rect2 = Rect2(c - Vector2(300, 330), Vector2(600, 660))
	InkDraw.rect(ci, frame, 18.0, seed_value, Color(0.45, 0.38, 0.25))
	InkDraw.rect(ci, frame.grow(-40), 6.0, seed_value + 1, Color(0.82, 0.78, 0.7))
	var turn: float = clampf(t / 0.12, 0.0, 1.0)
	var squash: float = lerpf(0.15, 1.0, ease(turn, 0.3))
	var head: Vector2 = c + Vector2(0, -20)
	ci.draw_colored_polygon(InkDraw.ellipse_points(head, Vector2(170 * squash, 220), 28), Color(0.9, 0.87, 0.8))
	InkDraw.ellipse(ci, head, Vector2(170 * squash, 220), 6.0, seed_value + 2)
	if turn >= 1.0:
		hollow_face(ci, head, 1.0, seed_value)


## A wardrobe door slams open; a pale face lunges out of the dark inside.
static func _wardrobe(ci: CanvasItem, screen: Vector2, t: float, seed_value: int) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.04, 0.035, 0.05))
	var body: Rect2 = Rect2(screen * 0.5 - Vector2(330, 360), Vector2(660, 760))
	InkDraw.rect(ci, body, 10.0, seed_value, Color(0.3, 0.25, 0.22))
	var open: float = ease(clampf(t / 0.1, 0.0, 1.0), 0.3)
	var hinge: float = body.position.x
	var door: PackedVector2Array = PackedVector2Array([Vector2(hinge, body.position.y), Vector2(hinge - 300 * open, body.position.y - 40 * open),
		Vector2(hinge - 300 * open, body.end.y + 40 * open), Vector2(hinge, body.end.y)])
	InkDraw.shape(ci, door, 6.0, seed_value + 1, Color(0.36, 0.3, 0.26))
	ci.draw_rect(body.grow(-20), Color(0.01, 0.01, 0.01))
	var lunge: float = clampf((t - 0.08) / 0.2, 0.0, 1.0)
	var c: Vector2 = body.get_center()
	var g: float = 0.55 + 0.55 * lunge
	ci.draw_colored_polygon(InkDraw.ellipse_points(c, Vector2(150, 200) * g, 24), Color(0.85, 0.83, 0.78))
	hollow_face(ci, c, g * 0.85, seed_value)


## The hand slams in from the top right; its nib stabs a line across the page.
static func _hand(ci: CanvasItem, screen: Vector2, t: float, seed_value: int) -> void:
	var k: float = ease(clampf(t / 0.16, 0.0, 1.0), 0.3)
	var tip_target: Vector2 = screen * Vector2(0.42, 0.62)
	var size: float = 820.0
	var at: Vector2 = (tip_target - HandArt.tool_tip(size, &"pen")) + Vector2(screen.x * 0.6, -screen.y * 0.8) * (1.0 - k)
	if k >= 1.0:
		var stab: float = clampf((t - 0.16) / 0.12, 0.0, 1.0)
		InkDraw.line(ci, tip_target, tip_target.lerp(Vector2(screen.x * 0.05, screen.y * 0.9), stab), 14.0, seed_value, InkDraw.INK, 5.0)
	HandArt.draw(ci, at, size, seed_value, 0.0, &"pen", 0.4)


## A pale, hollow face: dripping eye sockets with pinpoint pupils and a torn
## mouth ringed with nibs (the portrait and the wardrobe scares).
static func hollow_face(ci: CanvasItem, c: Vector2, g: float, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for x in [-62.0, 62.0]:
		var eye: Vector2 = c + Vector2(x, -46) * g
		ci.draw_colored_polygon(InkDraw.ellipse_points(eye, Vector2(38, 30) * g, 16), InkDraw.INK)
		ci.draw_circle(eye + Vector2(0, 2) * g, 5.0 * g, CrawlerArt.PALE)
		for d in 3:
			var top: Vector2 = eye + Vector2(rng.randf_range(-20, 20), 22) * g
			InkDraw.line(ci, top, top + Vector2(0, rng.randf_range(40, 110)) * g, 6.0 * g, seed_value + d, InkDraw.INK, 1.0)
	var mouth: PackedVector2Array = PackedVector2Array()
	for i in 9:
		mouth.append(c + Vector2(-90 + i * 22.5, 70 + rng.randf_range(-8, 8)) * g)
	for i in range(8, -1, -1):
		mouth.append(c + Vector2(-90 + i * 22.5, 150 - absf(i - 4.0) * 9.0 + rng.randf_range(-10, 10)) * g)
	InkDraw.fill(ci, mouth, InkDraw.INK)
	for i in 8:
		CrawlerArt.nib(ci, c + Vector2(-78 + i * 22.5, 78) * g, PI * 0.5, 9.0 * g)
