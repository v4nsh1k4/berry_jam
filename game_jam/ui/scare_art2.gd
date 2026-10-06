class_name ScareArt2
extends RefCounted
## More full-screen scare drawings (Stage 6b), same conventions as ScareArt:
##   closet  the bedchamber wardrobe's doors burst open and a pale, stretched,
##           hollow-eyed face lunges out to fill the panel
##   panel_escape (general helper, any scare can use it with only data:
##           `figure` + `caption` in the scare's entry) a vintage horror comic
##           page of small, ordinary panels; in one, the border is broken and
##           its character has stepped out into the white gutter, leaning out
##           at the reader with ink dripping off it, while the camera creeps
##           in. Black and white only; hand-inked, halftone, cross-hatching.

const PALE: Color = Color(0.9, 0.89, 0.84)
## The page's 3 x 3 grid; the panel at ESCAPE_PANEL is the one left empty.
const COLS: int = 3
const ROWS: int = 3


## The closet: doors flung wide, the face rushing out (grows over `t`).
static func closet(ci: CanvasItem, screen: Vector2, t: float, seed_value: int) -> void:
	var tick: int = InkDraw.boil_tick()
	ci.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.03, 0.03, 0.04))
	var c: Vector2 = screen * 0.5
	var open: float = smoothstep(0.0, 0.08, t)
	# The doors, swung out toward the camera on both sides.
	for side in [-1.0, 1.0]:
		var hinge: float = c.x + side * 300.0
		var edge: float = hinge + side * lerpf(-280.0, 360.0, open)
		InkDraw.shape(ci, PackedVector2Array([Vector2(hinge, 40), Vector2(edge, -40), Vector2(edge, screen.y + 40), Vector2(hinge, screen.y - 40)]),
			6.0, tick + int(side), HandArt.ERASER.darkened(0.55))
		InkDraw.hatch(ci, Rect2(minf(hinge, edge), 60, absf(edge - hinge), screen.y - 120), 9.0, 1.4, tick + 3, Color(InkDraw.INK, 0.5))
	var grow: float = lerpf(0.55, 1.35, smoothstep(0.0, 0.32, t))
	stretched_face(ci, c + Vector2(0, 20), grow, seed_value, tick)


## A pale face pulled long: hollow, sagging sockets, a black slack mouth,
## hatched shadow down one side. `grow` 1 = about the panel's height.
static func stretched_face(ci: CanvasItem, c: Vector2, grow: float, seed_value: int, tick: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var head: PackedVector2Array = PackedVector2Array()
	for i in 24:
		var a: float = TAU * i / 24.0
		head.append(c + Vector2(cos(a) * 170.0, sin(a) * 290.0) * grow * rng.randf_range(0.94, 1.05))
	InkDraw.shape(ci, head, 5.0, tick, PALE)
	InkDraw.hatch(ci, Rect2(c.x + 60 * grow, c.y - 260 * grow, 120 * grow, 520 * grow), 7.0, 1.3, tick + 1, Color(InkDraw.INK, 0.4))
	for side in [-1.0, 1.0]:
		var eye: Vector2 = c + Vector2(side * 62.0, -70.0) * grow
		ci.draw_colored_polygon(InkDraw.ellipse_points(eye, Vector2(34, 62) * grow, 16), InkDraw.INK)
		ci.draw_circle(eye + Vector2(0, 30) * grow, 4.0 * grow, PALE)
		InkDraw.line(ci, eye + Vector2(0, 60) * grow, eye + Vector2(side * 8, 150) * grow, 5.0 * grow, tick + 4, InkDraw.INK)
	ci.draw_colored_polygon(InkDraw.ellipse_points(c + Vector2(0, 140) * grow, Vector2(42, 92) * grow, 16), InkDraw.INK)


## The panel escape. `t` seconds into a ~1.2 s scare; `figure` is a
## character style (NpcArt: butler / housekeeper) or &"faceless"; `panel` is
## the grid cell (0..8) it has stepped out of.
static func panel_escape(ci: CanvasItem, screen: Vector2, t: float, seed_value: int, figure: StringName, caption: String,
		panel: int = 4) -> void:
	var tick: int = InkDraw.boil_tick()
	ci.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.06, 0.055, 0.07))
	# The slow creep toward the camera, centred on the escaped figure.
	var zoom: float = lerpf(1.0, 1.45, smoothstep(0.0, 1.2, t))
	var page: Rect2 = Rect2(Vector2(140, 20), Vector2(1000, 680))
	var cell: Vector2 = (page.size - Vector2(40, 40)) / Vector2(COLS, ROWS)
	var held: Rect2 = Rect2(page.position + Vector2(20, 20) + Vector2(panel % COLS, floori(panel / float(COLS))) * cell, cell)
	var focus: Vector2 = held.get_center() + Vector2(0, cell.y * 0.35)
	var view: Transform2D = Transform2D(0.0, Vector2(zoom, zoom), 0.0, screen * 0.5 - focus * zoom + (focus - screen * 0.5) * 0.25)
	RevealArt.set_view(ci, view)
	ci.draw_rect(page, InkDraw.PAPER)
	for i in COLS * ROWS:
		var r: Rect2 = Rect2(page.position + Vector2(20, 20) + Vector2(i % COLS, floori(i / float(COLS))) * cell, cell).grow(-9)
		if i == panel:
			_broken_panel(ci, r, tick)
		else:
			_ordinary_panel(ci, r, i, tick)
	_escapee(ci, held.grow(-9), figure, t, seed_value, tick)
	RevealArt.set_view(ci, Transform2D.IDENTITY)
	if caption != "" and t > 0.45:
		CreditsArt.caption(ci, Vector2(screen.x * 0.5 - 120, screen.y - 86), caption, 30, tick)


## An ordinary panel: a little room, one of the household, a halftone corner.
static func _ordinary_panel(ci: CanvasItem, r: Rect2, i: int, tick: int) -> void:
	ci.draw_rect(r, Color(0.97, 0.95, 0.9))
	InkDraw.line(ci, Vector2(r.position.x, r.end.y - r.size.y * 0.22), Vector2(r.end.x, r.end.y - r.size.y * 0.2), 2.5, tick + i)
	for k in 4:
		InkDraw.line(ci, r.position + Vector2(r.size.x * (0.15 + k * 0.22), 6), r.position + Vector2(r.size.x * (0.15 + k * 0.22), r.size.y * 0.78),
			1.0, tick + 20 + i * 4 + k, Color(InkDraw.INK, 0.25))
	var who: StringName = [&"butler", &"housekeeper", &"butler", &"housekeeper"][i % 4]
	RevealArt._character(ci, who, Vector2(r.position.x + r.size.x * (0.3 + 0.4 * float(i % 2)), r.end.y - r.size.y * 0.2), r.size.y / 300.0, tick + i)
	CreditsArt.halftone(ci, r, r.end)
	InkDraw.rect(ci, r, 4.0, tick + 40 + i, Color.TRANSPARENT, InkDraw.INK, 1.4)


## The empty panel: only its floor line left, the border snapped open on the
## near side, ink running from the break.
static func _broken_panel(ci: CanvasItem, r: Rect2, tick: int) -> void:
	ci.draw_rect(r, Color(0.97, 0.95, 0.9))
	InkDraw.line(ci, Vector2(r.position.x, r.end.y - r.size.y * 0.22), Vector2(r.end.x, r.end.y - r.size.y * 0.2), 2.5, tick)
	InkDraw.hatch(ci, Rect2(r.position + Vector2(8, 8), Vector2(r.size.x * 0.4, r.size.y * 0.5)), 6.0, 1.0, tick + 1, Color(InkDraw.INK, 0.35))
	var gap0: float = r.position.x + r.size.x * 0.32
	var gap1: float = r.position.x + r.size.x * 0.74
	InkDraw.polyline(ci, PackedVector2Array([Vector2(gap0, r.end.y), r.end - Vector2(r.size.x, 0), r.position, Vector2(r.end.x, r.position.y),
		r.end, Vector2(gap1, r.end.y)]), 4.0, tick + 2)
	for x in [gap0, gap1]:
		InkDraw.polyline(ci, PackedVector2Array([Vector2(x, r.end.y), Vector2(x + 8, r.end.y + 10), Vector2(x - 4, r.end.y + 22)]), 3.0, tick + 3)


## The one who stepped out: standing in the gutter below its panel, leaning
## out at the reader, hollow-faced, ink dripping from it. Never red.
static func _escapee(ci: CanvasItem, r: Rect2, figure: StringName, t: float, seed_value: int, tick: int) -> void:
	# Out in the gutter, overlapping the panel below: too big for its frame.
	var feet: Vector2 = Vector2(r.get_center().x + 10.0, r.end.y + 70)
	var lean: float = smoothstep(0.1, 0.9, t)
	var sc: float = r.size.y / 150.0 * (1.0 + 0.3 * lean)
	ci.draw_set_transform_matrix(RevealArt._current * Transform2D(-0.08 * lean, Vector2(sc, sc), 0.0, feet))
	if figure == &"faceless":
		InkDraw.shape(ci, PackedVector2Array([Vector2(-26, 0), Vector2(-34, -150), Vector2(34, -150), Vector2(26, 0)]), 3.0, tick, Color(0.2, 0.19, 0.22))
	else:
		NpcArt.draw(ci, figure, tick)
	# The face wiped hollow: a pale oval with sunken sockets, staring at you.
	InkDraw.ellipse(ci, Vector2(0, -174), Vector2(17, 23), 3.0, tick + 1, PALE)
	for side in [-1.0, 1.0]:
		ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(side * 6.5, -176), Vector2(4.2, 6.5), 10), InkDraw.INK)
		ci.draw_circle(Vector2(side * 6.5, -175), 1.0, PALE)
	# Ink running off it into the gutter.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 9:
		var x: float = rng.randf_range(-28, 28)
		var top: float = rng.randf_range(-150, -20)
		var run: float = fposmod(t * rng.randf_range(60, 120) + rng.randf() * 60.0, 90.0)
		ci.draw_line(Vector2(x, top), Vector2(x, top + run), InkDraw.INK, rng.randf_range(1.5, 3.5))
		ci.draw_circle(Vector2(x, top + run), 2.6, InkDraw.INK)
	ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(0, 4), Vector2(46, 8), 16), InkDraw.INK)
	ci.draw_set_transform_matrix(RevealArt._current)
