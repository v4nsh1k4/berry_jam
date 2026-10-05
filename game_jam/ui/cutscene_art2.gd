class_name CutsceneArt2
extends RefCounted
## Cutscene panel drawings for the Ink Heart and the repair
## (see CutsceneArt for the conventions).

const DARK: Color = Color(0.07, 0.065, 0.08)
const GREY: Color = Color(0.62, 0.6, 0.57)
const PENCIL: Color = Color(0.55, 0.62, 0.72, 0.7)


static func draw(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	match id:
		"sketch_through":
			_sketch_through(ci, s, t, tick)
		"torn_panels":
			_torn_panels(ci, s, t, tick)
		"shadow_hang":
			_shadow_hang(ci, s, t, tick)
		"eraser_dust":
			_eraser_dust(ci, s, t, tick)
		"repair_panel":
			_repair_panel(ci, s, t, tick)
		"whole_cast":
			_whole_cast(ci, s, t, tick)
		"border_gap":
			_border_gap(ci, s, t, tick)


static func _dark(ci: CanvasItem, s: Vector2, color: Color = DARK) -> void:
	ci.draw_rect(Rect2(Vector2(-40, -40), s + Vector2(80, 80)), color)


## C5: the room is only construction lines; something beats in the middle.
static func _sketch_through(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	for i in 10:
		var x: float = s.x * i / 9.0
		ci.draw_line(Vector2(x, 0), Vector2(x, s.y), PENCIL, 1.0)
	for i in 7:
		var y: float = s.y * i / 6.0
		ci.draw_line(Vector2(0, y), Vector2(s.x, y), PENCIL, 1.0)
	InkDraw.gap_ratio = 0.5
	InkDraw.rect(ci, Rect2(s.x * 0.1, s.y * 0.15, s.x * 0.8, s.y * 0.7), 2.0, tick, Color.TRANSPARENT, GREY)
	InkDraw.line(ci, Vector2(s.x * 0.1, s.y * 0.85), Vector2(s.x * 0.5, s.y * 0.5), 2.0, tick + 1, GREY)
	InkDraw.line(ci, Vector2(s.x * 0.9, s.y * 0.85), Vector2(s.x * 0.5, s.y * 0.5), 2.0, tick + 2, GREY)
	InkDraw.gap_ratio = 0.0
	var beat: float = pow(maxf(sin(t * 5.0), 0.0), 6.0)
	var r: float = (46.0 + 12.0 * beat) * u
	ci.draw_colored_polygon(InkDraw.ellipse_points(s * 0.5, Vector2(r, r * 1.1), 24), InkDraw.INK)
	for i in 8:
		var a: float = TAU * i / 8.0
		InkDraw.line(ci, s * 0.5 + Vector2(cos(a), sin(a)) * r, s * 0.5 + Vector2(cos(a), sin(a)) * (r + 60 * u), 3.0, tick + 4 + i)


## C5 / C6: the page torn into floating pieces with darkness between.
static func _torn_panels(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	_dark(ci, s)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 404
	for i in 5:
		var w: float = rng.randf_range(0.22, 0.34) * s.x
		var h: float = rng.randf_range(0.3, 0.45) * s.y
		var drift: Vector2 = Vector2(sin(t * 0.7 + i), cos(t * 0.5 + i * 2.0)) * 6.0
		var p: Vector2 = Vector2(rng.randf_range(0.0, s.x - w), rng.randf_range(0.0, s.y - h)) + drift
		# Torn edges: points walked round the rectangle, nudged outward.
		var corners: Array[Vector2] = [Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]
		var pts: PackedVector2Array = PackedVector2Array()
		for e in 4:
			var a: Vector2 = corners[e]
			var b: Vector2 = corners[(e + 1) % 4]
			var out: Vector2 = (b - a).normalized().orthogonal() * -1.0
			for j in 4:
				pts.append(p + a.lerp(b, j / 4.0) + out * rng.randf_range(0.0, 9.0))
		InkDraw.shape(ci, pts, 3.0, tick + i, InkDraw.PAPER)
		InkDraw.hatch(ci, Rect2(p + Vector2(14, 14), Vector2(w * 0.5, h * 0.4)), 10.0, 1.5, tick + 9 + i, GREY)


## C5: the hand hanging over the last word and the small red figure.
static func _shadow_hang(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	_dark(ci, s, Color(0.16, 0.15, 0.17))
	CutsceneArt.floor_line(ci, s, s.y * 0.88, tick)
	var bob: float = sin(t * 1.2) * 8.0 * u
	HandArt.draw(ci, Vector2(s.x * 0.62, s.y * 0.2 + bob), 300.0 * u, tick, 0.2, &"none", 1.0)
	BubbleArt.draw(ci, Vector2(s.x * 0.5, s.y * 0.5 + bob), "ERASE", Vector2(s.x * 0.56, s.y * 0.36 + bob), tick + 3,
		int(28 * u), 1.0, 3.0 * u)
	RevealArt.red_figure(ci, Vector2(s.x * 0.3, s.y * 0.88), u * 0.9, tick)


## C6: the eraser lifting away, crumbs falling.
static func _eraser_dust(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	var lift: float = clampf(t / 2.0, 0.0, 1.0)
	HandArt.draw(ci, Vector2(s.x * 0.55, s.y * (0.35 - 0.3 * lift)), 260.0 * u, tick, 0.0, &"eraser")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	for i in 24:
		var x: float = rng.randf_range(0.2, 0.8) * s.x
		var y: float = fmod(rng.randf() * s.y + t * rng.randf_range(40.0, 90.0) * u, s.y)
		ci.draw_rect(Rect2(x, y, 4 * u, 3 * u), Color(0.6, 0.58, 0.56))
	CutsceneArt.floor_line(ci, s, s.y * 0.86, tick + 1)


## C6: a room redrawing itself, line by line.
static func _repair_panel(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	var lines: Array = [
		[Vector2(0.0, 0.82), Vector2(1.0, 0.83)], [Vector2(0.12, 0.82), Vector2(0.12, 0.2)],
		[Vector2(0.12, 0.2), Vector2(0.88, 0.2)], [Vector2(0.88, 0.2), Vector2(0.88, 0.82)],
		[Vector2(0.62, 0.82), Vector2(0.62, 0.42)], [Vector2(0.62, 0.42), Vector2(0.76, 0.42)],
		[Vector2(0.76, 0.42), Vector2(0.76, 0.82)], [Vector2(0.2, 0.36), Vector2(0.42, 0.36)],
		[Vector2(0.2, 0.36), Vector2(0.2, 0.56)], [Vector2(0.42, 0.36), Vector2(0.42, 0.56)],
	]
	var drawn: float = t * 4.0
	for i in lines.size():
		var k: float = clampf(drawn - i, 0.0, 1.0)
		if k <= 0.0:
			break
		var a: Vector2 = lines[i][0] * s
		var b: Vector2 = a.lerp(lines[i][1] * s, k)
		InkDraw.line(ci, a, b, 4.0, tick + i)
		if k < 1.0:
			ci.draw_circle(b, 5.0 * u, InkDraw.INK)


## C6: everyone whole, with their bubbles back.
static func _whole_cast(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	var feet_y: float = s.y * 0.92
	RevealArt._character(ci, &"butler", Vector2(s.x * 0.2, feet_y), u, tick)
	RevealArt._character(ci, &"portrait", Vector2(s.x * 0.5, s.y * 0.62), u * 0.8, tick + 1)
	RevealArt._character(ci, &"housekeeper", Vector2(s.x * 0.8, feet_y), u, tick + 2)
	var pop: float = clampf(t / 0.6, 0.0, 1.0)
	var size: int = int(18 * u)
	BubbleArt.draw(ci, Vector2(s.x * 0.2, s.y * 0.14), "THANK YOU", Vector2(s.x * 0.2, s.y * 0.3), tick + 3, size, pop)
	BubbleArt.draw(ci, Vector2(s.x * 0.8, s.y * 0.14), "WHOLE AGAIN", Vector2(s.x * 0.8, s.y * 0.3), tick + 4, size, clampf(pop * 2.0 - 0.6, 0.0, 1.0))


## C6: a gap opening in the panel border, light past it, the figure turning to it.
static func _border_gap(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	CutsceneArt.floor_line(ci, s, s.y * 0.84, tick)
	var open: float = clampf(t / 2.0, 0.0, 1.0)
	var gap: Rect2 = Rect2(s.x - 30 * u, s.y * 0.84 - 150 * u * open, 40 * u, 150 * u * open)
	ci.draw_rect(Rect2(s.x - 8 * u, 0, 12 * u, s.y), InkDraw.INK)
	ci.draw_rect(gap, Color(1.0, 0.97, 0.86))
	ci.draw_colored_polygon(PackedVector2Array([gap.position, gap.position + Vector2(0, gap.size.y),
		gap.position + Vector2(-200 * u * open, gap.size.y + 20 * u), gap.position + Vector2(-200 * u * open, -10 * u)]),
		Color(1.0, 0.97, 0.86, 0.45))
	RevealArt.red_figure(ci, Vector2(s.x * lerpf(0.4, 0.6, open), s.y * 0.84), u, tick)
