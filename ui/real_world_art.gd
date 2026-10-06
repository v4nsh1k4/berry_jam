class_name RealWorldArt
extends RefCounted
## The world outside the comic, for the intro cinematic and the epilogue: a
## teenager's bedroom at night (or at dawn), the teenager, and the comic book
## "The Silent House of Hollow Hill". Greyscale like the comic, so the red ink
## (the player) is still the only colour. Screen space, 1280x720.

const TITLE_TOP: String = "THE SILENT HOUSE"
const TITLE_BOTTOM: String = "OF HOLLOW HILL"
const BOOK_GLOW: Color = Color(1.0, 0.98, 0.9)


## `dawn` 0 = night (lamp on), 1 = early morning.
static func bedroom(ci: CanvasItem, screen: Vector2, dawn: float, tick: int) -> void:
	var wall: Color = Color(0.09, 0.09, 0.11).lerp(Color(0.5, 0.49, 0.47), dawn)
	ci.draw_rect(Rect2(Vector2.ZERO, screen), wall)
	ci.draw_rect(Rect2(0, 560, screen.x, screen.y - 560), wall.darkened(0.35))
	InkDraw.line(ci, Vector2(0, 560), Vector2(screen.x, 560), 4.0, tick)
	# Window: moon at night, pale sky at dawn.
	var window: Rect2 = Rect2(860, 80, 230, 270)
	InkDraw.rect(ci, window, 6.0, tick + 1, Color(0.2, 0.21, 0.25).lerp(Color(0.9, 0.9, 0.88), dawn))
	if dawn < 0.5:
		ci.draw_circle(window.position + Vector2(160, 80), 30.0, Color(0.9, 0.9, 0.85, 1.0 - dawn * 2.0))
	InkDraw.line(ci, Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), 4.0, tick + 2)
	InkDraw.line(ci, Vector2(window.position.x, window.get_center().y), Vector2(window.end.x, window.get_center().y), 4.0, tick + 3)
	# Bed and nightstand with a lamp.
	InkDraw.shape(ci, PackedVector2Array([Vector2(80, 470), Vector2(760, 470), Vector2(760, 600), Vector2(80, 600)]), 5.0, tick + 4, Color(0.3, 0.29, 0.3))
	InkDraw.shape(ci, PackedVector2Array([Vector2(60, 330), Vector2(110, 330), Vector2(110, 600), Vector2(60, 600)]), 5.0, tick + 5, Color(0.22, 0.21, 0.22))
	InkDraw.shape(ci, PackedVector2Array([Vector2(110, 420), Vector2(250, 410), Vector2(260, 470), Vector2(110, 470)]), 4.0, tick + 6, Color(0.75, 0.74, 0.72))
	InkDraw.rect(ci, Rect2(800, 470, 130, 130), 5.0, tick + 7, Color(0.24, 0.23, 0.24))
	InkDraw.shape(ci, PackedVector2Array([Vector2(830, 390), Vector2(900, 390), Vector2(915, 440), Vector2(815, 440)]), 4.0, tick + 8, Color(0.8, 0.78, 0.72))
	InkDraw.line(ci, Vector2(865, 440), Vector2(865, 470), 5.0, tick + 9)
	if dawn < 0.5:
		ci.draw_circle(Vector2(865, 430), 150.0, Color(1, 0.95, 0.8, 0.08 * (1.0 - dawn * 2.0)))


## The teenager sitting on the bed, holding the book up in front of them
## (`hands` is where the book is). `alpha` fades them; `shrink` 0..1 pulls them
## into the book (they get smaller and slide toward it).
static func teen(ci: CanvasItem, hip: Vector2, hands: Vector2, alpha: float, shrink: float, tick: int) -> void:
	if alpha <= 0.01:
		return
	var s: float = 1.0 - shrink * 0.95
	var at: Vector2 = hip.lerp(hands, shrink)
	var ink: Color = Color(InkDraw.INK, alpha)
	var body: Color = Color(0.32, 0.31, 0.33, alpha)
	var shoulder: Vector2 = at + Vector2(10, -150) * s
	InkDraw.shape(ci, PackedVector2Array([at + Vector2(-50, 0) * s, at + Vector2(-20, -160) * s, at + Vector2(40, -160) * s,
		at + Vector2(55, 0) * s]), 4.0, tick, body, ink)
	InkDraw.ellipse(ci, shoulder + Vector2(0, -50) * s, Vector2(40, 46) * s, 4.0, tick + 1, Color(0.85, 0.83, 0.8, alpha), ink)
	# Messy hair, and the face turned to the book.
	InkDraw.fill(ci, PackedVector2Array([shoulder + Vector2(-44, -60) * s, shoulder + Vector2(-20, -104) * s,
		shoulder + Vector2(30, -100) * s, shoulder + Vector2(46, -58) * s, shoulder + Vector2(10, -78) * s]), ink)
	var hand_at: Vector2 = at.lerp(hands, 0.85) if shrink > 0.0 else hands
	InkDraw.line(ci, shoulder, hand_at + Vector2(-30, 10) * s, 9.0 * s, tick + 2, body)
	InkDraw.line(ci, shoulder + Vector2(20, 0) * s, hand_at + Vector2(30, 14) * s, 9.0 * s, tick + 3, body)
	# Legs under the blanket.
	InkDraw.shape(ci, PackedVector2Array([at + Vector2(-40, 0) * s, at + Vector2(260, -10) * s, at + Vector2(270, 40) * s,
		at + Vector2(-40, 40) * s]), 4.0, tick + 4, Color(0.42, 0.41, 0.42, alpha), ink)


## The comic book. `open` 0 = shut (cover and title), 1 = open (pages with
## little panels). `glow` lights it from inside.
static func book(ci: CanvasItem, c: Vector2, open: float, glow: float, tick: int) -> void:
	if glow > 0.0:
		for i in 5:
			ci.draw_circle(c, 60.0 + i * 55.0 * glow, Color(BOOK_GLOW, 0.12 * glow))
	var half: Vector2 = Vector2(lerpf(58.0, 116.0, open), 78.0)
	var r: Rect2 = Rect2(c - half, half * 2.0)
	if open < 0.5:
		InkDraw.rect(ci, r, 5.0, tick, Color(0.16, 0.15, 0.17))
		InkDraw.rect(ci, Rect2(r.position + Vector2(8, 14), Vector2(r.size.x - 16, 40)), 3.0, tick + 1, InkDraw.PAPER)
		var font: Font = ThemeDB.fallback_font
		for i in 2:
			var line: String = TITLE_TOP if i == 0 else TITLE_BOTTOM
			var w: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			ci.draw_string(font, Vector2(c.x - w * 0.5, r.position.y + 31 + i * 14), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, InkDraw.INK)
		return
	var pages: Color = InkDraw.PAPER.lerp(BOOK_GLOW, glow)
	InkDraw.rect(ci, r, 4.0, tick, pages)
	InkDraw.line(ci, Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), 3.0, tick + 1)
	for side in [-1.0, 1.0]:
		for row in 3:
			var p: Rect2 = Rect2(Vector2(c.x + (8.0 if side > 0.0 else -half.x + 8.0), r.position.y + 10 + row * 48), Vector2(half.x - 16.0, 40))
			InkDraw.rect(ci, p, 2.0, tick + 2 + row, Color.TRANSPARENT, Color(InkDraw.INK, 0.6))


## Red ink erupting from the book and reaching for `target`. `amount` 0..1.
static func red_ink(ci: CanvasItem, from: Vector2, target: Vector2, amount: float, seed_value: int) -> void:
	if amount <= 0.0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 7:
		var pts: PackedVector2Array = PackedVector2Array()
		var bend: float = rng.randf_range(-160.0, 160.0)
		var reach: float = clampf(amount * rng.randf_range(0.9, 1.3), 0.0, 1.0)
		for j in 12:
			var t: float = j / 11.0 * reach
			var p: Vector2 = from.lerp(target + Vector2(rng.randf_range(-40, 40), rng.randf_range(-80, 40)), t)
			pts.append(p + Vector2(sin(t * PI) * bend, -sin(t * PI) * 90.0))
		InkDraw.polyline(ci, pts, 7.0 - i * 0.6, seed_value + i, false, InkDraw.RED, 3.0)
		ci.draw_circle(pts[pts.size() - 1], 6.0, InkDraw.RED)
	for i in int(amount * 26.0):
		var p: Vector2 = from + Vector2(rng.randf_range(-220, 220), rng.randf_range(-260, 40)) * amount
		ci.draw_circle(p, rng.randf_range(2.0, 6.0), InkDraw.RED)
