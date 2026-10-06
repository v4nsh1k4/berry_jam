class_name IntroArt
extends RefCounted
## The New Game intro's room (Stage 5, "sucked into the comic"), in scene
## space (1280x720) for ComicPages panels to look into: a desk at night, the
## comic open on it and glowing, the reader bent over it. As the pull starts
## (`warp`) the room tilts and shrinks toward the page, panel frames and speed
## lines rush inward and the page's lines curl round the edges (those three
## are shared with IntroArt2's tunnel). Greyscale; red is the reader becoming
## the player.

const BOOK: Vector2 = Vector2(660, 466)
## Where the reader's hand rests before it reaches for the page.
const REST_HAND: Vector2 = Vector2(566, 474)
const HEAD: Vector2 = Vector2(452, 318)
const SHOULDER: Vector2 = Vector2(398, 372)
const HIP: Vector2 = Vector2(300, 520)
const DARK: Color = Color(0.08, 0.075, 0.09)
const SKIN: Color = Color(0.8, 0.77, 0.73)
const WOOD: Color = Color(0.3, 0.28, 0.27)


## The room. `glow` lights the book; `ink` lifts its lines toward the reader;
## `reach` 0..1 moves the hand to the page; `red` turns the hand red; `warp`
## pulls everything toward the book; `reader` 0 = gone (after the slam).
static func room(ci: CanvasItem, t: float, glow: float, ink: float, reach: float, red: float, warp: float, reader: float, tick: int,
		shut: bool = false) -> void:
	var view: Transform2D = RevealArt._current
	ci.draw_rect(Rect2(-400, -400, 2080, 1520), DARK)
	if warp > 0.0:
		var k: float = warp * warp
		var xf: Transform2D = Transform2D(0.22 * k + sin(t * 3.0) * 0.04 * k, Vector2.ONE * (1.0 - 0.5 * k), 0.12 * k, Vector2.ZERO)
		xf.origin = BOOK - xf.basis_xform(BOOK)
		ci.draw_set_transform_matrix(view * xf)
	_walls(ci, glow, tick)
	_desk(ci, tick)
	if shut:
		_shut_book(ci, tick)
	else:
		book(ci, BOOK, glow, tick)
	if reader > 0.0:
		var hand: Vector2 = REST_HAND.lerp(BOOK + Vector2(46, -12), smoothstep(0.0, 1.0, reach))
		_reader(ci, hand, red, glow, reader, tick)
		_tendrils(ci, t, ink, hand, tick)
	ci.draw_set_transform_matrix(view)
	if warp > 0.0:
		frames(ci, BOOK, t, warp, false, tick)
		curls(ci, BOOK, t, warp, tick)
		speed_lines(ci, BOOK, t, warp, tick)


static func _walls(ci: CanvasItem, glow: float, tick: int) -> void:
	ci.draw_rect(Rect2(-400, 600, 2080, 520), Color(0.05, 0.048, 0.055))
	InkDraw.line(ci, Vector2(-60, 600), Vector2(1340, 600), 4.0, tick)
	InkDraw.hatch(ci, Rect2(-40, 0, 300, 600), 16.0, 1.5, tick + 1, Color(0, 0, 0, 0.45))
	# Window with a moon, the frame's cross, a sliver of curtain.
	var window: Rect2 = Rect2(70, 70, 200, 250)
	InkDraw.rect(ci, window, 6.0, tick + 2, Color(0.18, 0.19, 0.23))
	ci.draw_circle(window.position + Vector2(130, 70), 26.0, Color(0.86, 0.86, 0.82))
	InkDraw.line(ci, Vector2(170, 70), Vector2(170, 320), 4.0, tick + 3)
	InkDraw.line(ci, Vector2(70, 195), Vector2(270, 195), 4.0, tick + 4)
	InkDraw.shape(ci, PackedVector2Array([Vector2(56, 60), Vector2(110, 60), Vector2(96, 340), Vector2(50, 350)]), 3.0, tick + 5, Color(0.2, 0.19, 0.21))
	# A shelf of books on the right.
	InkDraw.rect(ci, Rect2(1060, 120, 190, 480), 5.0, tick + 6, Color(0.14, 0.13, 0.15))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 909
	for row in 4:
		var x: float = 1072.0
		var y: float = 230.0 + row * 110.0
		InkDraw.line(ci, Vector2(1060, y), Vector2(1250, y), 4.0, tick + 7 + row)
		while x < 1236.0:
			var w: float = rng.randf_range(12, 24)
			var h: float = rng.randf_range(60, 92)
			ci.draw_rect(Rect2(x, y - h, w - 3, h), Color(0.22, 0.21, 0.24).lightened(rng.randf_range(0.0, 0.35)))
			x += w
	# The lamp's warm pool and the book's own light.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(950, 350), Vector2(720, 476), Vector2(1030, 480)]), Color(1, 0.95, 0.8, 0.1))
	for i in 5:
		ci.draw_circle(BOOK + Vector2(0, -40), 60.0 + i * 60.0 * glow, Color(RealWorldArt.BOOK_GLOW, 0.1 * glow))


static func _desk(ci: CanvasItem, tick: int) -> void:
	InkDraw.shape(ci, PackedVector2Array([Vector2(360, 470), Vector2(1010, 470), Vector2(1040, 500), Vector2(330, 500)]), 4.0, tick, WOOD)
	InkDraw.rect(ci, Rect2(330, 500, 710, 34), 4.0, tick + 1, WOOD.darkened(0.3))
	InkDraw.rect(ci, Rect2(620, 506, 140, 22), 2.5, tick + 2, WOOD.darkened(0.1))
	for x in [350.0, 1000.0]:
		InkDraw.rect(ci, Rect2(x, 534, 22, 70), 3.0, tick + 3, WOOD.darkened(0.4))
	# Desk lamp: base, jointed arm, shade.
	InkDraw.ellipse(ci, Vector2(930, 468), Vector2(40, 8), 3.0, tick + 4, Color(0.25, 0.24, 0.26))
	InkDraw.line(ci, Vector2(930, 466), Vector2(900, 384), 5.0, tick + 5)
	InkDraw.line(ci, Vector2(900, 384), Vector2(958, 336), 5.0, tick + 6)
	InkDraw.shape(ci, PackedVector2Array([Vector2(934, 318), Vector2(990, 316), Vector2(1012, 360), Vector2(914, 366)]), 3.5, tick + 7, Color(0.7, 0.68, 0.64))
	# A pencil and a mug: someone was here a while.
	HandArt.pencil_lying(ci, Vector2(470, 486), 120.0)
	InkDraw.rect(ci, Rect2(840, 430, 34, 40), 3.0, tick + 8, Color(0.85, 0.83, 0.8))
	InkDraw.ellipse(ci, Vector2(880, 448), Vector2(9, 11), 3.0, tick + 9)


## The comic lying open (seen from above the desk), its pages glowing.
static func book(ci: CanvasItem, c: Vector2, glow: float, tick: int) -> void:
	var paper: Color = InkDraw.PAPER.lerp(RealWorldArt.BOOK_GLOW, glow)
	for side in [-1.0, 1.0]:
		var q: PackedVector2Array = PackedVector2Array([c + Vector2(6 * side, -34), c + Vector2(175 * side, -26),
			c + Vector2(185 * side, 6), c + Vector2(6 * side, 12)])
		InkDraw.shape(ci, q, 3.0, tick + int(side), paper)
		for box in [Vector4(0.1, 0.12, 0.5, 0.5), Vector4(0.56, 0.12, 0.92, 0.5), Vector4(0.1, 0.58, 0.92, 0.9)]:
			var pts: PackedVector2Array = PackedVector2Array([quad(q, box.x, box.y), quad(q, box.z, box.y), quad(q, box.z, box.w), quad(q, box.x, box.w)])
			InkDraw.polyline(ci, pts, 1.5, tick + 3, true, Color(InkDraw.INK, 0.7), 0.4)
	# The little house on the left page.
	var h: Vector2 = quad(PackedVector2Array([c + Vector2(-6, -34), c + Vector2(-175, -26), c + Vector2(-185, 6), c + Vector2(-6, 12)]), 0.3, 0.42)
	InkDraw.polyline(ci, PackedVector2Array([h + Vector2(-14, 0), h + Vector2(-14, -8), h + Vector2(0, -16), h + Vector2(14, -8), h + Vector2(14, 0)]), 1.5, tick + 5)
	InkDraw.line(ci, Vector2(c.x, c.y - 34), Vector2(c.x, c.y + 12), 2.5, tick + 6)


## The comic slammed shut, lying on the desk.
static func _shut_book(ci: CanvasItem, tick: int) -> void:
	InkDraw.shape(ci, PackedVector2Array([BOOK + Vector2(-130, 4), BOOK + Vector2(130, 4), BOOK + Vector2(136, 16), BOOK + Vector2(-136, 16)]), 3.0, tick, InkDraw.PAPER)
	InkDraw.shape(ci, PackedVector2Array([BOOK + Vector2(-112, -30), BOOK + Vector2(112, -30), BOOK + Vector2(132, 6), BOOK + Vector2(-132, 6)]), 4.0, tick + 1,
		Color(0.16, 0.15, 0.17))
	InkDraw.shape(ci, PackedVector2Array([BOOK + Vector2(-60, -24), BOOK + Vector2(60, -24), BOOK + Vector2(66, -10), BOOK + Vector2(-66, -10)]), 2.0, tick + 2)


## A point inside quad `q` (TL, TR, BR, BL) at (u, v).
static func quad(q: PackedVector2Array, u: float, v: float) -> Vector2:
	return q[0].lerp(q[1], u).lerp(q[3].lerp(q[2], u), v)


## The reader on a chair, bent over the book, one hand going to the page.
static func _reader(ci: CanvasItem, hand: Vector2, red: float, glow: float, alpha: float, tick: int) -> void:
	var ink: Color = Color(InkDraw.INK, alpha)
	var cloth: Color = Color(0.33, 0.32, 0.35, alpha)
	InkDraw.line(ci, Vector2(246, 340), Vector2(252, 604), 6.0, tick, ink)
	InkDraw.line(ci, Vector2(244, 526), Vector2(350, 526), 6.0, tick + 1, ink)
	InkDraw.line(ci, Vector2(340, 526), Vector2(336, 604), 5.0, tick + 2, ink)
	InkDraw.shape(ci, PackedVector2Array([HIP + Vector2(-40, 6), SHOULDER + Vector2(-46, -14), SHOULDER + Vector2(24, 4), HIP + Vector2(46, 4)]), 4.0, tick + 3, cloth, ink)
	InkDraw.shape(ci, PackedVector2Array([HIP + Vector2(-30, 0), HIP + Vector2(150, -6), HIP + Vector2(156, 30), HIP + Vector2(-30, 34)]), 4.0, tick + 4, cloth.darkened(0.2), ink)
	InkDraw.line(ci, HIP + Vector2(150, 12), HIP + Vector2(160, 84), 12.0, tick + 5, cloth.darkened(0.2))
	# Head bowed over the page, lit from below by it.
	var face: Color = Color(SKIN.lerp(RealWorldArt.BOOK_GLOW, glow * 0.5), alpha)
	InkDraw.ellipse(ci, HEAD, Vector2(34, 40), 4.0, tick + 6, face, ink)
	InkDraw.fill(ci, PackedVector2Array([HEAD + Vector2(-40, -6), HEAD + Vector2(-26, -44), HEAD + Vector2(14, -48), HEAD + Vector2(36, -26),
		HEAD + Vector2(10, -30), HEAD + Vector2(-14, -14), HEAD + Vector2(-30, 14)]), ink)
	InkDraw.line(ci, SHOULDER + Vector2(14, -8), HEAD + Vector2(-8, 34), 14.0, tick + 12, face)
	# Profile toward the page: brow, nose, an eye wide open, the mouth.
	InkDraw.fill(ci, PackedVector2Array([HEAD + Vector2(30, -4), HEAD + Vector2(44, 12), HEAD + Vector2(32, 16)]), face)
	InkDraw.polyline(ci, PackedVector2Array([HEAD + Vector2(30, -4), HEAD + Vector2(44, 12), HEAD + Vector2(32, 16)]), 2.5, tick + 7, false, ink)
	InkDraw.line(ci, HEAD + Vector2(10, -8), HEAD + Vector2(28, -6), 3.0, tick + 13, ink)
	InkDraw.ellipse(ci, HEAD + Vector2(18, 4), Vector2(7, 5), 2.0, tick + 14, Color(1, 1, 1, alpha), ink)
	ci.draw_circle(HEAD + Vector2(21, 6), 2.5, ink)
	ci.draw_circle(HEAD + Vector2(19, 3), 1.2, Color(1, 1, 1, alpha * glow))
	InkDraw.line(ci, HEAD + Vector2(26, 26), HEAD + Vector2(32, 25), 2.5, tick + 15, ink)
	# The page light catching the underside of the face.
	ci.draw_colored_polygon(InkDraw.ellipse_points(HEAD + Vector2(12, 24), Vector2(20, 9), 12), Color(RealWorldArt.BOOK_GLOW, 0.35 * glow * alpha))
	# The arm and the hand.
	# Fixed bone lengths (Stage 6b: the arm never stretches): the hand stops
	# where the arm can reach and the elbow bends to get there.
	var upper: float = 150.0
	var fore: float = 166.0
	var to_hand: Vector2 = hand - SHOULDER
	var d: float = clampf(to_hand.length(), 1.0, upper + fore - 1.0)
	hand = SHOULDER + to_hand.normalized() * d
	var along: float = (upper * upper - fore * fore + d * d) / (2.0 * d)
	var elbow: Vector2 = SHOULDER + to_hand.normalized() * along + to_hand.normalized().orthogonal() * -sqrt(maxf(upper * upper - along * along, 0.0))
	InkDraw.line(ci, SHOULDER, elbow, 13.0, tick + 8, cloth)
	InkDraw.line(ci, elbow, hand, 11.0, tick + 9, cloth)
	var skin: Color = Color(SKIN.lerp(InkDraw.RED, red), alpha)
	InkDraw.ellipse(ci, hand, Vector2(14, 9), 2.5, tick + 10, skin, ink)
	InkDraw.line(ci, hand + Vector2(10, 2), hand + Vector2(26, 6), 4.0, tick + 11, skin)


## Lines of ink lifting off the page and reaching for the reader's face and hand.
static func _tendrils(ci: CanvasItem, t: float, ink: float, hand: Vector2, tick: int) -> void:
	if ink <= 0.0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 61
	for i in 7:
		var base: Vector2 = BOOK + Vector2(rng.randf_range(-160, 160), rng.randf_range(-28, 6))
		var target: Vector2 = (HEAD + Vector2(20, 20) if i % 2 == 0 else hand) + Vector2(rng.randf_range(-30, 30), rng.randf_range(-20, 20))
		var reach: float = ink * rng.randf_range(0.6, 1.0)
		var pts: PackedVector2Array = PackedVector2Array()
		var side: Vector2 = (target - base).normalized().orthogonal()
		for j in 10:
			var k: float = j / 9.0
			pts.append(base.lerp(target, k * reach) + side * sin(j * 0.9 + t * 4.0 + i) * 16.0 * k)
		InkDraw.polyline(ci, pts, 4.0 - i * 0.3, tick + 20 + i, false, InkDraw.INK, 2.0)
		ci.draw_circle(pts[9], 4.0, InkDraw.INK)


## Comic panel borders rushing in toward `c` (tunnel = filled, alternating).
static func frames(ci: CanvasItem, c: Vector2, t: float, amount: float, tunnel: bool, tick: int) -> void:
	var n: int = 9 if tunnel else 6
	var list: Array = []
	for i in n:
		list.append(fposmod(float(i) / n - t * 0.45, 1.0))
	list.sort()
	for i in range(n - 1, -1, -1):
		var s: float = pow(list[i], 1.6) * 2.2
		if s < 0.03:
			continue
		var rot: float = (1.0 - s / 2.2) * 0.9 + t * 0.15
		var half: Vector2 = Vector2(640, 360) * s
		var pts: PackedVector2Array = PackedVector2Array()
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			pts.append(c + (half * corner).rotated(rot))
		if tunnel:
			ci.draw_colored_polygon(pts, InkDraw.PAPER.darkened(0.15 + 0.6 * (1.0 - s / 2.2)) if i % 2 == 0 else DARK)
		InkDraw.polyline(ci, pts, 3.0 + 6.0 * s, tick + i, true, Color(InkDraw.INK, amount), 2.0)


## Speed lines pointing in at `c`, streaming inward.
static func speed_lines(ci: CanvasItem, c: Vector2, t: float, amount: float, tick: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 314
	for i in 40:
		var a: float = TAU * i / 40.0 + rng.randf_range(-0.05, 0.05)
		var run: float = fposmod(t * 1.3 + rng.randf(), 1.0)
		var r0: float = lerpf(1000.0, 180.0, run)
		var dir: Vector2 = Vector2.from_angle(a)
		InkDraw.line(ci, c + dir * r0, c + dir * (r0 + rng.randf_range(120, 260)), rng.randf_range(2.0, 5.0), tick + i,
			Color(InkDraw.PAPER, amount * 0.7), 0.6)


## The page's printed lines peeling up and curling round toward `c`.
static func curls(ci: CanvasItem, c: Vector2, t: float, amount: float, tick: int) -> void:
	for i in 6:
		var pts: PackedVector2Array = PackedVector2Array()
		for j in 22:
			var r: float = lerpf(620.0, 50.0, j / 21.0)
			var a: float = TAU * i / 6.0 + j * 0.2 + t * 1.6
			pts.append(c + Vector2(cos(a), sin(a) * 0.62) * r)
		InkDraw.polyline(ci, pts, 3.0, tick + 50 + i, false, Color(0.55, 0.53, 0.5, amount), 1.5)
