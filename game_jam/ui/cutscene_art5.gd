class_name CutsceneArt5
extends RefCounted
## C1, the first steal, in third person (Stage 6; it replaces Stage 5's
## first-person hands). A comic page seen from outside, like C3 and C5:
##   c1_steal   the landing: the red unperson (empty bubble) reaches up, a red
##              thread pulls Arthur's OPEN bubble off him, it tears ("RRIP")
##   c1_tear    close-up: the bubble peeling away from its tail like a scab,
##              ink strands stretching and snapping, a raw hole left behind
##   c1_thin    the page shudders: the landing's ink goes thin and broken,
##              the faint pencil line under it shows through, Arthur's
##              bubble only "..."
##   c1_alone   the red figure alone with the torn word, its own bubble empty,
##              a hairline crack across the panel

const TEAR_AT: float = 0.9
const WALL: Color = Color(0.84, 0.82, 0.77)
const PENCIL: Color = Color(0.55, 0.62, 0.72, 0.75)


static func draw(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	match id:
		"c1_steal":
			_steal(ci, s, t, tick)
		"c1_tear":
			_tear(ci, s, t, tick)
		"c1_thin":
			_thin(ci, s, t, tick)
		"c1_alone":
			_alone(ci, s, t, tick)


## The landing's wall, wainscot and floor; `faint` 0..1 thins the ink.
static func _room(ci: CanvasItem, s: Vector2, faint: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	ci.draw_rect(Rect2(Vector2(-60, -60), s + Vector2(120, 120)), WALL)
	InkDraw.gap_ratio = 0.05 + 0.5 * faint
	var line_c: Color = Color(0.6, 0.58, 0.54, 1.0 - faint * 0.6)
	for i in 12:
		var x: float = -30.0 + i * s.x / 10.0
		InkDraw.line(ci, Vector2(x, -40), Vector2(x, s.y * 0.6), 1.5, tick + i, line_c, 0.6)
	InkDraw.rect(ci, Rect2(-40, s.y * 0.6, s.x + 80, s.y * 0.2), 4.0, tick + 20, Color(0.7, 0.68, 0.63), Color(InkDraw.INK, 1.0 - faint * 0.5))
	InkDraw.line(ci, Vector2(-20, s.y * 0.8), Vector2(s.x + 20, s.y * 0.81), 4.0, tick + 21, Color(InkDraw.INK, 1.0 - faint * 0.5))
	for i in 7:
		InkDraw.line(ci, Vector2(-40 + i * s.x * 0.18, s.y * 0.8), Vector2(-120 + i * s.x * 0.2, s.y + 30), 1.5, tick + 22 + i, Color(InkDraw.INK, 0.35 - faint * 0.2))
	# A picture frame and the study door.
	InkDraw.rect(ci, Rect2(s.x * 0.08, s.y * 0.12, 80 * u, 100 * u), 5.0, tick + 30, Color(0.5, 0.47, 0.42), Color(InkDraw.INK, 1.0 - faint * 0.5))
	InkDraw.hatch(ci, Rect2(s.x * 0.08 + 8 * u, s.y * 0.12 + 8 * u, 64 * u, 84 * u), 8.0, 1.0, tick + 31, Color(InkDraw.INK, 0.35 * (1.0 - faint)))
	InkDraw.rect(ci, Rect2(s.x * 0.88, s.y * 0.06, 110 * u, s.y * 0.74), 5.0, tick + 32, Color(0.45, 0.4, 0.36), Color(InkDraw.INK, 1.0 - faint * 0.5))
	ci.draw_circle(Vector2(s.x * 0.9, s.y * 0.46), 5.0 * u, Color(0.75, 0.7, 0.5))
	InkDraw.gap_ratio = 0.0


## C1 beat 1, wide: the theft from outside.
static func _steal(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	_room(ci, s, 0.0, tick)
	var floor_y: float = s.y * 0.86
	var torn: bool = t >= TEAR_AT
	var recoil: float = smoothstep(TEAR_AT, TEAR_AT + 0.3, t)
	var arthur: Vector2 = Vector2(s.x * (0.7 + 0.02 * recoil), floor_y)
	var sc: float = u * 1.05
	RevealArt._character(ci, &"butler", arthur, sc, tick)
	var mouth: Vector2 = arthur + NpcArt.mouth(&"butler") * sc
	var home: Vector2 = Vector2(s.x * 0.52, s.y * 0.2)
	var feet: Vector2 = Vector2(s.x * 0.24, floor_y)
	var fig: float = u * 1.25
	var reach: float = smoothstep(0.0, 0.6, t)
	var shoulder: Vector2 = feet + Vector2(8, -78) * fig
	var hand: Vector2 = shoulder + Vector2(lerpf(10.0, 62.0, reach * (1.0 - 0.4 * recoil)), lerpf(4.0, -10.0, reach)) * fig
	RevealArt.red_figure(ci, feet, fig, tick + 41)
	# The red arm stretched out toward the word; a red thread pulls it.
	InkDraw.line(ci, shoulder, hand, 4.5 * fig, tick + 40, InkDraw.RED)
	ci.draw_circle(hand, 5.0 * fig, InkDraw.RED)
	var fly: float = smoothstep(TEAR_AT, TEAR_AT + 0.8, t)
	var word: Vector2 = home.lerp(hand + Vector2(24, 54) * u, fly)
	if not torn:
		var tug: Vector2 = Vector2(-sin(t * 30.0) * 3.0, 0) * smoothstep(0.4, TEAR_AT, t)
		BubbleArt.draw(ci, home + tug, "OPEN", mouth, tick + 50, int(24 * u), 1.0, 3.5)
		InkDraw.polyline(ci, PackedVector2Array([hand, hand.lerp(home, 0.5) + Vector2(0, 14) * u, home + tug + Vector2(-34, 10) * u]),
			2.0, tick + 51, false, InkDraw.RED, 2.5)
		return
	# Torn: half the bubble and its tail stay at Arthur's mouth; the word flies.
	_stump(ci, home, mouth, u, tick + 52)
	InkDraw.line(ci, hand, word + Vector2(-20, 0) * u, 2.0, tick + 55, InkDraw.RED, 2.0)
	_scrap(ci, word, u * lerpf(1.0, 0.7, fly), fly, tick + 56)
	if t < TEAR_AT + 0.8:
		var pop: float = smoothstep(TEAR_AT, TEAR_AT + 0.15, t)
		ci.draw_set_transform_matrix(RevealArt._current * Transform2D(-0.15, Vector2(pop, pop), 0.0, Vector2(s.x * 0.6, s.y * 0.42)))
		sfx(ci, "RRIP!", int(30 * u))
		CutsceneArt.unplace(ci)
	# Arthur's hand flies to his mouth.
	if recoil > 0.0:
		InkDraw.line(ci, arthur + Vector2(-18, -110) * sc, mouth + Vector2(-4, 10) * sc, 4.0 * sc, tick + 60)
		for i in 3:
			var a: float = -2.4 + i * 0.4
			var p: Vector2 = arthur + Vector2(0, -200) * sc
			InkDraw.line(ci, p + Vector2.from_angle(a) * 14 * u, p + Vector2.from_angle(a) * 30 * u, 2.5, tick + 61 + i)


## Comic sound lettering at the origin: ink with a thick white outline.
static func sfx(ci: CanvasItem, words: String, size: int) -> void:
	var font: Font = ThemeDB.fallback_font
	var at: Vector2 = Vector2(-font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, size * 0.35)
	ci.draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, InkDraw.WHITE)
	ci.draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, InkDraw.INK)
	ci.draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, InkDraw.INK)


## What is left at the speaker: the tail and the half of the bubble nearest
## it, torn off along a ragged edge, ink dripping from the tear.
static func _stump(ci: CanvasItem, at: Vector2, mouth: Vector2, u: float, tick: int) -> void:
	var radii: Vector2 = BubbleArt.size_for("OPEN", int(24 * u)) * Vector2(0.56, 0.5)
	var dir: Vector2 = (mouth - at).normalized()
	var base: Vector2 = at + dir * minf(radii.x, radii.y) * 0.7
	ci.draw_colored_polygon(PackedVector2Array([base + dir.orthogonal() * 9.0, base - dir.orthogonal() * 9.0, mouth]), InkDraw.WHITE)
	InkDraw.line(ci, base + dir.orthogonal() * 9.0, mouth, 3.0, tick)
	InkDraw.line(ci, base - dir.orthogonal() * 9.0, mouth, 3.0, tick + 1)
	var shell: PackedVector2Array = PackedVector2Array()
	for i in 9:
		var a: float = dir.angle() - 1.5 + 3.0 * i / 8.0
		shell.append(at + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	var tear: PackedVector2Array = PackedVector2Array()
	for i in 7:
		var k: float = i / 6.0
		tear.append(shell[8].lerp(shell[0], k) + dir * (10.0 if i % 2 == 0 else -2.0) * u)
	var piece: PackedVector2Array = shell.duplicate()
	piece.append_array(tear)
	InkDraw.fill(ci, piece, InkDraw.WHITE)
	InkDraw.polyline(ci, shell, 3.0, tick + 2)
	InkDraw.polyline(ci, tear, 2.0, tick + 3)
	for i in 3:
		var drop: Vector2 = tear[1 + i * 2]
		InkDraw.line(ci, drop, drop + Vector2(0, (10 + i * 6) * u), 2.0, tick + 4 + i)
		ci.draw_circle(drop + Vector2(0, (12 + i * 6) * u), 2.5 * u, InkDraw.INK)


## The torn-off word: a crumpling bubble scrap with ragged edges.
static func _scrap(ci: CanvasItem, at: Vector2, k: float, crumple: float, tick: int) -> void:
	var size: Vector2 = Vector2(96, 50) * k
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 16:
		var a: float = TAU * i / 16.0
		pts.append(at + Vector2(cos(a) * size.x * 0.5, sin(a) * size.y * 0.5) * (1.0 - 0.2 * crumple * float(i % 2)))
	InkDraw.shape(ci, pts, 3.0, tick, InkDraw.WHITE)
	CutsceneArt.text(ci, at + Vector2(0, 8 * k), "OPEN", int(22 * k))


## C1 beat 1, close-up: the bubble peeling off its tail, strands snapping.
static func _tear(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	ci.draw_rect(Rect2(Vector2(-60, -60), s + Vector2(120, 120)), WALL.darkened(0.08))
	InkDraw.hatch(ci, Rect2(-20, -20, s.x + 40, s.y + 40), 14.0, 1.0, tick, Color(InkDraw.INK, 0.12))
	var root: Vector2 = Vector2(s.x * 0.66, s.y * 0.72)
	var peel: float = smoothstep(0.2, TEAR_AT + 0.4, t)
	var c: Vector2 = Vector2(s.x * 0.52, s.y * 0.44) + Vector2(-s.x * 0.16, -s.y * 0.1) * peel
	# The tail, fixed to the bottom right where Arthur is.
	var mouth: Vector2 = Vector2(s.x * 0.95, s.y * 1.05)
	InkDraw.line(ci, root + Vector2(-12, 0), mouth, 3.5, tick + 1)
	InkDraw.line(ci, root + Vector2(12, 0), mouth, 3.5, tick + 2)
	ci.draw_colored_polygon(PackedVector2Array([root + Vector2(-12, 0), root + Vector2(12, 0), mouth]), InkDraw.WHITE)
	# Strands of ink stretching between the bubble and the tail; they snap at TEAR_AT.
	var snap: float = clampf((t - TEAR_AT) / 0.25, 0.0, 1.0)
	for i in 5:
		var a: Vector2 = root + Vector2(-20 + i * 10, -4)
		var b: Vector2 = c + Vector2(-30 + i * 15, 46 * u)
		if snap <= 0.0:
			var mid: Vector2 = a.lerp(b, 0.5) + Vector2(sin(t * 9.0 + i) * 6.0, 0)
			InkDraw.polyline(ci, PackedVector2Array([a, mid, b]), lerpf(5.0, 1.2, peel), tick + 3 + i)
		else:
			InkDraw.line(ci, a, a.lerp(b, 0.3 * (1.0 - snap * 0.5)), 2.0, tick + 3 + i)
			ci.draw_circle(a.lerp(b, 0.3) + Vector2(0, snap * 30.0), 3.0, InkDraw.INK)
	var size: Vector2 = BubbleArt.size_for("OPEN", int(40 * u)) * 1.1
	BubbleArt.draw(ci, c, "OPEN", BubbleArt.NO_TAIL, tick + 10, int(40 * u), 1.0, 4.0)
	# The raw torn underside of the bubble.
	var edge: PackedVector2Array = PackedVector2Array()
	for i in 11:
		var x: float = lerpf(-size.x * 0.45, size.x * 0.45, i / 10.0)
		edge.append(c + Vector2(x, size.y * 0.42 + (6.0 if i % 2 == 0 else -2.0) * u))
	InkDraw.polyline(ci, edge, 2.5, tick + 11)
	# A red thread pulls it off the panel to the left (toward the player).
	InkDraw.polyline(ci, PackedVector2Array([c + Vector2(-size.x * 0.5, 0), c + Vector2(-size.x * 0.8, 10 * u), Vector2(-20, c.y + 30 * u)]),
		2.5, tick + 12, false, InkDraw.RED, 2.0)
	if t > TEAR_AT:
		for i in 6:
			var k: float = clampf((t - TEAR_AT) * 1.4 - i * 0.08, 0.0, 1.0)
			var d: Vector2 = Vector2.from_angle(-PI * 0.5 + (i - 2.5) * 0.45)
			InkDraw.line(ci, root + d * (20 + 50 * k) * u, root + d * (34 + 80 * k) * u, 3.0 * (1.0 - k) + 0.5, tick + 20 + i)


## C1 beat 2: the page shudders; the ink goes thin, the pencil shows under it.
static func _thin(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	var faint: float = clampf(0.25 + t / 2.0, 0.0, 1.0)
	_room(ci, s, faint, tick)
	var arthur: Vector2 = Vector2(s.x * 0.62, s.y * 0.86)
	var sc: float = u * 1.05
	# The pencil under the ink: Arthur's outline and the floor, slightly off.
	var off: Vector2 = Vector2(5, -4) * u
	InkDraw.gap_ratio = 0.3
	InkDraw.polyline(ci, PackedVector2Array([arthur + Vector2(-22, -150) * sc + off, arthur + Vector2(-24, -60) * sc + off,
		arthur + Vector2(-12, 0) * sc + off]), 1.2, tick + 70, false, PENCIL, 0.5)
	InkDraw.polyline(ci, PackedVector2Array([arthur + Vector2(24, -150) * sc + off, arthur + Vector2(36, -44) * sc + off,
		arthur + Vector2(8, 0) * sc + off]), 1.2, tick + 71, false, PENCIL, 0.5)
	InkDraw.ellipse(ci, arthur + Vector2(0, -174) * sc + off, Vector2(16, 22) * sc, 1.2, tick + 72, Color.TRANSPARENT, PENCIL, 0.5)
	InkDraw.line(ci, Vector2(-20, s.y * 0.8) + off * 2.0, Vector2(s.x + 20, s.y * 0.81) + off * 2.0, 1.2, tick + 73, PENCIL, 0.5)
	for i in 5:
		var y: float = s.y * (0.15 + i * 0.13)
		ci.draw_line(Vector2(0, y), Vector2(s.x, y + 3.0), Color(PENCIL, 0.35), 1.0)
	InkDraw.gap_ratio = 0.2 + 0.5 * faint
	RevealArt._character(ci, &"butler", arthur, sc, tick)
	InkDraw.gap_ratio = 0.0
	var mouth: Vector2 = arthur + NpcArt.mouth(&"butler") * sc
	var c: Vector2 = Vector2(s.x * 0.44, s.y * 0.22)
	BubbleArt.draw_shell(ci, c, Vector2(150, 72) * u * 0.8, mouth, tick + 80, 0.85, 3.0)
	CutsceneArt.text(ci, c + Vector2(0, 10 * u), "...", int(30 * u))
	# Shudder marks at the panel edges.
	var shake: float = maxf(0.0, 1.0 - t * 0.9)
	for i in 4:
		var x: float = s.x * (0.08 if i < 2 else 0.92)
		var y2: float = s.y * (0.3 + (i % 2) * 0.35)
		for j in 3:
			InkDraw.line(ci, Vector2(x + (1.0 if i > 1 else -1.0) * j * 8.0 * u, y2 - 18 * u), Vector2(x + (1.0 if i > 1 else -1.0) * j * 8.0 * u, y2 + 18 * u), 2.0, tick + 90 + i * 3 + j,
				Color(InkDraw.INK, 0.7 * shake))


## C1 beat 2: the red figure alone with the stolen word, a crack across the page.
static func _alone(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	ci.draw_rect(Rect2(Vector2(-60, -60), s + Vector2(120, 120)), InkDraw.PAPER.darkened(0.06))
	InkDraw.line(ci, Vector2(-20, s.y * 0.84), Vector2(s.x + 20, s.y * 0.85), 4.0, tick)
	ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(s.x * 0.5, s.y * 0.85), Vector2(70, 10) * u, 16), Color(0, 0, 0, 0.2))
	var feet: Vector2 = Vector2(s.x * 0.5, s.y * 0.84)
	var fig: float = u * 1.5
	RevealArt.red_figure(ci, feet, fig, tick + 1)
	var hold: Vector2 = feet + Vector2(-30, -70) * fig + Vector2(0, sin(t * 2.0) * 2.0)
	InkDraw.line(ci, feet + Vector2(-8, -78) * fig, hold, 4.5 * fig, tick + 2, InkDraw.RED)
	_scrap(ci, hold + Vector2(-26, -14) * u, u * 0.75, 1.0, tick + 3)
	# The crack: a hairline across the page, growing in from the edge (damage).
	var grow: float = clampf(t / 1.6, 0.0, 1.0)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 9:
		var k: float = i / 8.0
		if k > grow:
			break
		pts.append(Vector2(s.x * k, s.y * 0.3 + sin(i * 2.7) * 20.0 * u + k * s.y * 0.1))
	if pts.size() >= 2:
		InkDraw.polyline(ci, pts, 2.0, tick + 4, false, InkDraw.RED, 1.5)
	for i in 3:
		var a: float = t * 0.6 + i * 2.1
		ci.draw_arc(feet + Vector2(0, -120) * fig, (60.0 + i * 22.0) * u, a, a + 1.4, 12, Color(InkDraw.INK, 0.25), 1.5)
