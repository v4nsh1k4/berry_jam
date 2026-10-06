class_name CutsceneFill
extends RefCounted
## Fills the cutscene panels' empty paper (Stage 6, "less white space"):
## slowly turning concentric spirals, rings, tiny drifting ink drops, small
## watching eyes, nib-tip marks, hatching swirls, Ben-Day dot fields and
## little page doodles. Seeded per drawing so they stay put; they move only
## in steps of the line boil (InkDraw.BOIL_INTERVAL_MS), like the ink.
## Denser toward the edges and corners, none over the beat's subject (FOCUS,
## panel fractions). Black and white (pale on the dark panels); never red.

const COUNT: int = 84
## Where each drawing's subject is (kept clear), as a fraction of the panel
## (a Rect2, or an Array of them for a panel with several subjects). Built at
## runtime: nested constant arrays read back empty in web exports.
static func focus_of(id: String) -> Variant:
	return {
	"c1_steal": Rect2(0.14, 0.12, 0.66, 0.86), "c1_tear": Rect2(0.2, 0.18, 0.62, 0.8), "c1_thin": Rect2(0.3, 0.08, 0.42, 0.9),
	"c1_alone": Rect2(0.28, 0.18, 0.44, 0.8), "pov_torch": Rect2(0.3, 0.12, 0.6, 0.8), "pov_watch": Rect2(0.3, 0.12, 0.6, 0.8),
	"story_tea": Rect2(0.2, 0.3, 0.62, 0.6), "story_family": Rect2(0.15, 0.12, 0.7, 0.8), "story_door": Rect2(0.3, 0.12, 0.4, 0.8),
	"story_gap": Rect2(0.15, 0.25, 0.7, 0.7), "pov_stairs": Rect2(0.28, 0.3, 0.46, 0.6), "pov_ink_rise": Rect2(0.25, 0.3, 0.5, 0.6),
	"sketch_through": Rect2(0.32, 0.26, 0.36, 0.5), "torn_panels": Rect2(0.12, 0.12, 0.76, 0.76),
	"shadow_hang": Rect2(0.2, 0.05, 0.7, 0.9), "eraser_dust": Rect2(0.25, 0.05, 0.55, 0.9), "repair_panel": Rect2(0.1, 0.15, 0.8, 0.7),
	"whole_cast": [Rect2(0.1, 0.04, 0.2, 0.92), Rect2(0.42, 0.44, 0.16, 0.36), Rect2(0.7, 0.04, 0.2, 0.92)],
	"border_gap": Rect2(0.32, 0.3, 0.68, 0.6),
	}.get(id, Rect2(0.2, 0.2, 0.6, 0.6))
## Drawings on a dark ground: no white space to fill, so only faint pale
## corner spirals (marks there would light up the dark).
const DARK: Array[String] = ["pov_torch", "pov_watch", "pov_stairs", "pov_ink_rise", "torn_panels", "shadow_hang"]
const PALE: Color = Color(0.88, 0.87, 0.84)


static func draw(ci: CanvasItem, id: String, s: Vector2, tick: int) -> void:
	if id == "":
		return
	var u: float = CutsceneArt.unit(s)
	var spec: Variant = focus_of(id)
	var focus: Array[Rect2] = []
	for f in (spec if spec is Array else [spec]):
		focus.append(Rect2((f as Rect2).position * s, (f as Rect2).size * s).grow(12.0 * u))
	var dark: bool = id in DARK
	var ink: Color = Color(PALE, 0.3) if dark else Color(InkDraw.INK, 0.7)
	# Time advances only with the boil (stepped, like the line wobble).
	var tq: float = tick * InkDraw.BOIL_INTERVAL_MS / 1000.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = id.hash()
	var centre: Vector2 = focus[0].get_center()
	# A big concentric spiral turning in every free corner.
	for corner in [Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]:
		var r: float = minf(s.x, s.y) * 0.22
		if not _hits(focus, Rect2(corner - Vector2(r, r) * 0.6, Vector2(r, r) * 1.2)):
			_spiral(ci, corner, r, tq * 0.35 * (1.0 if corner.x == 0.0 else -1.0), Color(ink, ink.a * 0.75))
	if dark:
		return
	for i in COUNT:
		var p: Vector2 = Vector2(rng.randf(), rng.randf()) * s
		var kind: int = rng.randi() % 8
		var size: float = rng.randf_range(14.0, 38.0) * u
		var phase: float = rng.randf() * TAU
		# Toward the edges and corners: keep a mark the further out it is.
		var edge: float = maxf(absf(p.x / s.x - 0.5), absf(p.y / s.y - 0.5)) * 2.0
		if _hits(focus, Rect2(p - Vector2(size, size), Vector2(size, size) * 2.0)) or rng.randf() > 0.45 + edge:
			continue
		_mark(ci, kind, p, size, tq + phase, ink, centre, tick + i)


static func _hits(focus: Array[Rect2], r: Rect2) -> bool:
	for f in focus:
		if f.intersects(r):
			return true
	return false


## Concentric turns (three interleaved arms) round `c`, rotated by `turn`.
static func _spiral(ci: CanvasItem, c: Vector2, r: float, turn: float, ink: Color) -> void:
	for arm in 3:
		var pts: PackedVector2Array = PackedVector2Array()
		for j in 40:
			var k: float = j / 39.0
			pts.append(c + Vector2.from_angle(k * TAU * 2.0 + turn + arm * TAU / 3.0) * r * (0.12 + 0.88 * k))
		ci.draw_polyline(pts, ink, 1.6)


static func _mark(ci: CanvasItem, kind: int, p: Vector2, r: float, t: float, ink: Color, look_at: Vector2, tick: int) -> void:
	match kind:
		0:
			# A slowly turning spiral.
			var pts: PackedVector2Array = PackedVector2Array()
			for j in 26:
				var k: float = j / 25.0
				pts.append(p + Vector2.from_angle(k * TAU * 2.4 + t * 0.6) * r * k)
			ci.draw_polyline(pts, ink, 1.8)
		1:
			# Concentric rings, breathing a little.
			for j in 3:
				ci.draw_arc(p, r * (0.35 + j * 0.3) * (1.0 + 0.06 * sin(t * 1.5 + j)), 0.0, TAU, 18, ink, 1.6)
		2:
			# Ink drops drifting down.
			for j in 3:
				var d: Vector2 = p + Vector2((j - 1) * r * 0.5, fposmod(t * 6.0 + j * r * 0.7, r * 2.0) - r)
				ci.draw_colored_polygon(PackedVector2Array([d + Vector2(0, -r * 0.3), d + Vector2(r * 0.16, r * 0.05), d + Vector2(0, r * 0.18),
					d + Vector2(-r * 0.16, r * 0.05)]), ink)
		3:
			# A small eye, watching the subject; it blinks now and then.
			var open: float = 0.15 if fposmod(t, 6.0) < 0.2 else 1.0
			InkDraw.ellipse(ci, p, Vector2(r * 0.55, r * 0.28 * open + 0.5), 1.2, tick, Color(1, 1, 1, ink.a * 0.9), ink, 0.4)
			if open > 0.5:
				ci.draw_circle(p + (look_at - p).normalized() * r * 0.18, r * 0.14, ink)
		4:
			# A nib-tip mark and its scratch.
			var a: float = t * 0.2 + r
			CrawlerArt.nib(ci, p, a, r * 0.18)
			ci.draw_line(p - Vector2.from_angle(a) * r * 0.2, p - Vector2.from_angle(a) * r * 1.1 + Vector2(0, r * 0.2), ink, 1.4)
		5:
			# A hatching swirl: short strokes turning round a point.
			for j in 6:
				var a2: float = j * TAU / 6.0 + t * 0.4
				var at: Vector2 = p + Vector2.from_angle(a2) * r * 0.6
				var d2: Vector2 = Vector2.from_angle(a2 + PI * 0.5) * r * 0.35
				ci.draw_line(at - d2, at + d2, ink, 1.5)
		6:
			# A small Ben-Day dot field.
			for gy in 4:
				for gx in 4:
					var q: Vector2 = p + Vector2(gx - 1.5 + (0.5 if gy % 2 == 1 else 0.0), gy - 1.5) * r * 0.45
					ci.draw_circle(q, r * 0.06 * (1.0 + 0.5 * sin(t + gx + gy)), ink)
		_:
			# A little page doodle: a star scribble.
			var pts2: PackedVector2Array = PackedVector2Array()
			for j in 11:
				pts2.append(p + Vector2.from_angle(j * TAU * 2.0 / 5.0 + t * 0.15) * r * 0.55)
			ci.draw_polyline(pts2, ink, 1.6)
