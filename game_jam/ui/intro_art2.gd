class_name IntroArt2
extends RefCounted
## The intro's close-ups (Stage 5), scene space 1280x720, see IntroArt:
##   page_close  the comic page filling the view: ink peels off its panel
##               lines and reaches up; the reader's hand comes down, a finger
##               touches the empty panel, ink wraps it, the hand turns red
##               and is dragged in (ripples, shrinking into the page)
##   tunnel      inside the pull: panel borders zooming into the page, page
##               lines curling, speed lines, and a rush of red ink (the player)
##               whooshing in toward the light

const TOUCH: Vector2 = Vector2(668, 556)
const CENTER: Vector2 = Vector2(640, 380)
const PAGE: PackedVector2Array = [Vector2(70, 150), Vector2(1230, 128), Vector2(1262, 780), Vector2(40, 800)]


## `ink` 0..1 lifts the lines; `reach` 0..1 brings the hand down to the touch;
## `red` turns it; `drag` 0..1 pulls it into the page.
static func page_close(ci: CanvasItem, t: float, ink: float, reach: float, red: float, drag: float, tick: int) -> void:
	ci.draw_rect(Rect2(-400, -400, 2080, 1520), IntroArt.DARK)
	InkDraw.shape(ci, PAGE, 5.0, tick, InkDraw.PAPER.lerp(RealWorldArt.BOOK_GLOW, 0.6))
	InkDraw.hatch(ci, Rect2(40, 640, 1240, 160), 12.0, 1.0, tick + 1, Color(InkDraw.INK, 0.18))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	for row in 2:
		for col in 3:
			var r: Rect2 = Rect2(110 + col * 380, 190 + row * 260, 350, 230)
			InkDraw.rect(ci, r, 4.0, tick + 2 + row * 3 + col)
			_panel_bits(ci, row * 3 + col, r, tick)
			# Ink peeling off the border, reaching up toward the hand.
			if ink > 0.0 and row * 3 + col != 4:
				for n in 2:
					var base: Vector2 = Vector2(r.position.x + rng.randf_range(30, 320), r.position.y + (0.0 if n == 0 else r.size.y))
					var to: Vector2 = TOUCH + Vector2(rng.randf_range(60, 260), -rng.randf_range(140, 330))
					var tip: Vector2 = base.lerp(to, ink * rng.randf_range(0.45, 0.85))
					var pts: PackedVector2Array = PackedVector2Array()
					for j in 10:
						var k: float = j / 9.0
						pts.append(base.lerp(tip, k) + (to - base).normalized().orthogonal() * sin(j * 1.1 + t * 5.0 + col) * 18.0 * k)
					InkDraw.polyline(ci, pts, 9.0, tick + 30 + col, false, InkDraw.INK, 2.0)
					InkDraw.polyline(ci, pts.slice(5), 5.0, tick + 33 + col, false, InkDraw.INK, 2.0)
					ci.draw_circle(pts[9], 7.0, InkDraw.INK)
					ci.draw_circle(pts[9] + Vector2(10, 18), 3.0, InkDraw.INK)
	# Ripples where the finger touched.
	if red > 0.0:
		for i in 4:
			var k: float = fposmod(t * 0.9 + i * 0.25, 1.0)
			InkDraw.ellipse(ci, TOUCH, Vector2(30 + k * 220, 12 + k * 80), 3.0 * (1.0 - k) + 0.5, tick + 40 + i,
				Color.TRANSPARENT, Color(InkDraw.INK, (1.0 - k) * red))
		ci.draw_colored_polygon(InkDraw.ellipse_points(TOUCH, Vector2(40, 16) * (0.5 + drag * 2.0), 20), Color(InkDraw.INK, 0.8 * red))
	var tip: Vector2 = Vector2(1240, -200).lerp(TOUCH, smoothstep(0.0, 1.0, reach)) + Vector2(0, 20) * drag
	_hand(ci, tip, 1.0 - 0.85 * drag, red, t, tick)


## Bits of the story in each little panel (index 4 is the empty one).
static func _panel_bits(ci: CanvasItem, index: int, r: Rect2, tick: int) -> void:
	var c: Vector2 = r.get_center()
	match index:
		0:
			InkDraw.polyline(ci, PackedVector2Array([c + Vector2(-70, 80), c + Vector2(-70, -10), c + Vector2(0, -70), c + Vector2(70, -10),
				c + Vector2(70, 80)]), 3.0, tick + 60)
			ci.draw_rect(Rect2(c + Vector2(-20, 20), Vector2(26, 60)), InkDraw.INK)
		1:
			RevealArt._character(ci, &"butler", c + Vector2(-40, 100), 0.7, tick)
			BubbleArt.draw(ci, c + Vector2(60, -60), "OPEN", c + Vector2(-20, -30), tick + 61, 18)
		2:
			InkDraw.rect(ci, Rect2(c - Vector2(50, 70), Vector2(100, 120)), 3.0, tick + 62, Color(0.25, 0.25, 0.3))
			ci.draw_circle(c + Vector2(18, -36), 14.0, InkDraw.PAPER)
		3:
			for i in 6:
				InkDraw.line(ci, c + Vector2(-120 + i * 40, 80 - i * 26), c + Vector2(-80 + i * 40, 80 - i * 26), 3.0, tick + 63 + i)
		5:
			RevealArt._character(ci, &"housekeeper", c + Vector2(0, 100), 0.7, tick + 1)


## The reader's hand from the upper right, index finger out, its tip at
## `tip`; `s` shrinks it (dragged into the page). Red spreads from the
## fingertip; ink wraps the finger once it is red.
static func _hand(ci: CanvasItem, tip: Vector2, s: float, red: float, t: float, tick: int) -> void:
	var dir: Vector2 = Vector2(-0.55, 0.84).normalized()
	var side: Vector2 = dir.orthogonal()
	# A normally proportioned index finger (Stage 6b: it used to be 84 long).
	var knuckle: Vector2 = tip - dir * 46.0 * s
	var palm: Vector2 = knuckle - dir * 40.0 * s - side * 16.0 * s
	var wrist: Vector2 = palm - dir * 52.0 * s
	var hand_color: Color = IntroArt.SKIN.lerp(InkDraw.RED, clampf(red * 1.6 - 0.25, 0.0, 1.0))
	var sleeve: Vector2 = wrist - dir * 520.0
	InkDraw.shape(ci, PackedVector2Array([sleeve + side * 80 * s, wrist + side * 36 * s, wrist - side * 36 * s, sleeve - side * 80 * s]), 4.0, tick + 70,
		Color(0.33, 0.32, 0.35))
	InkDraw.hatch(ci, Rect2(wrist - dir * 300.0 - Vector2(40, 40), Vector2(80, 80)), 9.0, 1.0, tick + 69, Color(InkDraw.INK, 0.3))
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 18:
		var a: float = TAU * i / 18.0
		pts.append(palm + (dir * cos(a) * 50.0 + side * sin(a) * 40.0) * s)
	InkDraw.shape(ci, pts, 4.0, tick + 71, hand_color)
	# Three fingers curled under, the thumb, then the pointing finger.
	for i in 3:
		var base: Vector2 = palm + dir * 34 * s - side * (4 + i * 17) * s
		digit(ci, base, base + (dir * 22 - side * 10) * s, 15.0 * s, hand_color, tick + 72 + i)
	var thumb: Vector2 = palm + side * 30 * s
	digit(ci, thumb, thumb + (dir * 34 + side * 22) * s, 15.0 * s, hand_color, tick + 76)
	digit(ci, knuckle, tip, 16.0 * s, IntroArt.SKIN.lerp(InkDraw.RED, clampf(red * 2.5, 0.0, 1.0)), tick + 77)
	ci.draw_arc(tip - dir * 9.0 * s, 5.0 * s, side.angle() - 1.2, side.angle() + 1.2, 6, Color(InkDraw.INK, 0.6), 2.0)
	if red > 0.0:
		for i in 4:
			var at: Vector2 = tip.lerp(wrist, i * 0.25 * red)
			var a0: float = t * 6.0 + i
			ci.draw_arc(at, 15.0 * s, a0, a0 + 3.8, 10, InkDraw.INK, 3.5 * s + 0.5)


## A finger: an ink-outlined capsule from `a` to `b`.
static func digit(ci: CanvasItem, a: Vector2, b: Vector2, w: float, color: Color, tick: int) -> void:
	InkDraw.line(ci, a, b, w * 1.3 + 2.0, tick, InkDraw.INK, 0.6)
	ci.draw_circle(b, (w * 1.3 + 2.0) * 0.5, InkDraw.INK)
	InkDraw.line(ci, a, b, w, tick, color, 0.6)
	ci.draw_circle(b, w * 0.5, color)


## The player pulled in, as a rush of red (Stage 6b: no figure at all):
## ink ribbons spiralling in toward the light from `at`, red speed lines
## along the pull, drops and flecks peeling off outward; only the empty
## bubble (the player's sign) rides the lead streak. `sc` shrinks it all.
static func _whoosh(ci: CanvasItem, at: Vector2, sc: float, t: float, tick: int) -> void:
	var off: Vector2 = at - CENTER
	var r0: float = maxf(off.length(), 20.0)
	var a0: float = off.angle()
	var lead: Vector2 = at
	for ribbon in 6:
		var pts: PackedVector2Array = PackedVector2Array()
		var lag: float = ribbon * 0.16
		for j in 18:
			var k: float = j / 17.0
			# From behind the lead (outer, older) to the lead (inner).
			var turn: float = a0 - lag - (1.0 - k) * 1.3
			var r: float = r0 * (1.0 + (1.0 - k) * 0.55) + (ribbon - 2.5) * 16.0 * sc
			pts.append(CENTER + Vector2.from_angle(turn + sin(t * 4.0 + ribbon) * 0.04) * r)
		if ribbon == 0:
			lead = pts[17]
		_ribbon(ci, pts, (34.0 - ribbon * 4.0) * sc + 2.0, Color(InkDraw.RED, 0.95 - ribbon * 0.1))
	# Red speed lines pointing into the light.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 97
	for i in 12:
		var p: Vector2 = lead + Vector2(rng.randf_range(-160, 160), rng.randf_range(-120, 120)) * sc
		var into: Vector2 = (CENTER - p).normalized()
		var length: float = rng.randf_range(40, 120) * sc
		var phase: float = fposmod(t * 2.2 + rng.randf(), 1.0)
		var start: Vector2 = p + into * length * phase
		ci.draw_line(start, start + into * length * 0.6, Color(InkDraw.RED, 0.8 * (1.0 - phase)), maxf(1.0, 4.0 * sc))
	# Drops and flecks peeling off, flung outward.
	for i in 16:
		var age: float = fposmod(t * 1.1 + rng.randf(), 1.0)
		var away: Vector2 = (lead - CENTER).normalized().rotated(rng.randf_range(-0.9, 0.9))
		var p2: Vector2 = lead + away * age * 260.0 * sc + Vector2(0, age * age * 60.0 * sc)
		var c: Color = Color(InkDraw.RED, 1.0 - age)
		if i % 2 == 0:
			ci.draw_circle(p2, (6.0 - 4.0 * age) * sc + 0.6, c)
		else:
			ci.draw_line(p2, p2 + away * rng.randf_range(10, 26) * sc, c, maxf(1.0, 3.0 * sc * (1.0 - age)))
	var bubble: float = clampf((0.9 - sc) / 0.5, 0.0, 1.0)
	if bubble > 0.0:
		BubbleArt.draw_shell(ci, lead + Vector2(30, -40) * sc, Vector2(60, 34) * sc, BubbleArt.NO_TAIL, tick + 6, bubble, 2.5)


## A tapered red ribbon along `pts`: thin at the tail, full at the lead.
static func _ribbon(ci: CanvasItem, pts: PackedVector2Array, w: float, color: Color) -> void:
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for i in pts.size():
		var k: float = float(i) / (pts.size() - 1)
		var d: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var half: float = w * 0.5 * pow(k, 0.8) * (1.0 if k < 0.92 else (1.0 - k) / 0.08 * 0.6 + 0.4)
		left.append(pts[i] + d.orthogonal() * half)
		right.append(pts[i] - d.orthogonal() * half)
	right.reverse()
	left.append_array(right)
	InkDraw.fill(ci, left, color)


## Inside the pull. `pull` 0..1 takes the red reader from the lower right into
## the light at the centre.
static func tunnel(ci: CanvasItem, t: float, pull: float, tick: int) -> void:
	ci.draw_rect(Rect2(-400, -400, 2080, 1520), IntroArt.DARK)
	IntroArt.frames(ci, CENTER, t, 1.0, true, tick)
	IntroArt.curls(ci, CENTER, t, 0.9, tick)
	IntroArt.speed_lines(ci, CENTER, t * 1.6, 1.0, tick)
	var pulse: float = 0.5 + 0.5 * sin(t * 9.0)
	for i in 4:
		ci.draw_circle(CENTER, 40.0 + i * 26.0 + pulse * 10.0, Color(RealWorldArt.BOOK_GLOW, 0.35 - i * 0.07))
	var k: float = pow(pull, 1.4)
	var at: Vector2 = Vector2(1010, 690).lerp(CENTER, k)
	var sc: float = lerpf(2.6, 0.08, k)
	# Red drops left along the way in.
	for i in 10:
		var back: float = clampf(k - i * 0.04, 0.0, 1.0)
		ci.draw_circle(Vector2(1010, 690).lerp(CENTER, back) + Vector2(sin(i * 2.3) * 30, cos(i * 1.7) * 20), 6.0 * (1.0 - back), InkDraw.RED)
	_whoosh(ci, at, sc, t, tick)
