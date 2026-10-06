class_name TitleArt
extends SubViewport
## The title page and main menu backdrop (Stage 6): a ring of large black
## crows in dense cross-hatched ink (feathers as hatched masses, beaks
## inward) round a bright white centre. Drawn ONCE into this SubViewport, a
## few hatched shapes per frame from start-up (never on the first click; the
## page shows the build inking in), then frozen. The live layer on top
## (TitleLive) adds the turning spiral, blinking eyes, feather shivers and the
## tiny red figure. StartScreen owns it; MainMenu draws the same texture.

const SIZE: Vector2i = Vector2i(1280, 720)
const CENTRE: Vector2 = Vector2(640, 330)
const RING: Vector2 = Vector2(480, 262)
const CROWS: int = 9
const BUDGET_MS: int = 3
const PAPER: Color = Color(0.95, 0.93, 0.88)

## The shared, finished (or still inking) backdrop.
static var texture: ViewportTexture
## Crow placements for the live layer: [transform, flipped] each.
static var crows: Array = []
static var done: bool = false

var _jobs: Array = []
var _painter: Node2D
var _rendered: bool = true


func _ready() -> void:
	size = SIZE
	transparent_bg = false
	render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	render_target_update_mode = SubViewport.UPDATE_ONCE
	_painter = Node2D.new()
	_painter.draw.connect(_paint)
	add_child(_painter)
	texture = get_texture()
	crows.clear()
	_plan()
	RenderingServer.frame_post_draw.connect(func() -> void: _rendered = true)


## Every hatched shape becomes one job: [polygon (screen), hatch angles, spacing].
func _plan() -> void:
	_jobs.append([&"ground"])
	for i in CROWS:
		var a: float = -PI * 0.5 + TAU * (i + 0.5) / CROWS
		var at: Vector2 = CENTRE + Vector2(cos(a) * RING.x, sin(a) * RING.y)
		var facing: Vector2 = (CENTRE - at).normalized()
		var flip: bool = facing.x < 0.0
		var sc: float = 0.68 + 0.12 * sin(i * 2.1)
		var xf: Transform2D = Transform2D(facing.angle(), Vector2(sc, -sc if flip else sc), 0.0, at)
		crows.append([xf, flip])
		for shape in CrowShapes.parts(i % 3 != 1):
			var poly: PackedVector2Array = xf * (shape[0] as PackedVector2Array)
			_jobs.append([&"hatch", poly, shape[1], xf.get_rotation(), float(shape[2])])


func _process(_delta: float) -> void:
	if done or not _rendered:
		return
	_rendered = false
	queue_redraw_painter()


func queue_redraw_painter() -> void:
	_painter.queue_redraw()
	render_target_update_mode = SubViewport.UPDATE_ONCE


## Draws only this frame's jobs (the target is never cleared after the first).
func _paint() -> void:
	var t0: int = Time.get_ticks_msec()
	while not _jobs.is_empty() and Time.get_ticks_msec() - t0 < BUDGET_MS:
		var job: Array = _jobs.pop_front()
		if job[0] == &"ground":
			_ground()
		else:
			_hatch(job[1], job[2], job[3], job[4])
	if _jobs.is_empty():
		done = true


## Paper, dark cross-hatched corners, a soft white well in the middle.
func _ground() -> void:
	_painter.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), PAPER)
	for c in [Vector2.ZERO, Vector2(SIZE.x, 0), Vector2(SIZE), Vector2(0, SIZE.y)]:
		var tri: PackedVector2Array = PackedVector2Array([c, c + Vector2(0, (SIZE.y * 0.62) * (1.0 if c.y == 0.0 else -1.0)),
			c + Vector2(SIZE.x * 0.4 * (1.0 if c.x == 0.0 else -1.0), 0)])
		_hatch(tri, [0.6, -0.6], 0.0, 5.0)
	for i in 6:
		var k: float = 1.0 - i / 6.0
		_painter.draw_colored_polygon(InkDraw.ellipse_points(CENTRE, Vector2(260, 190) * (0.4 + 0.6 * k), 40), Color(1, 1, 1, 0.18))


## Fills `poly` with paper, then crossed pen strokes (one set per angle,
## relative to the crow's own rotation), clipped to the shape; ink outline.
func _hatch(poly: PackedVector2Array, angles: Array, rot: float, spacing: float) -> void:
	if poly.size() < 3:
		return
	InkDraw.fill(_painter, poly, Color(0.6, 0.59, 0.57))
	var bounds: Rect2 = Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		bounds = bounds.expand(p)
	var c: Vector2 = bounds.get_center()
	var reach: float = bounds.size.length() * 0.5 + 4.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(c.x * 31.0 + c.y)
	for a in angles:
		var d: Vector2 = Vector2.from_angle(float(a) + rot)
		var n: Vector2 = d.orthogonal()
		var off: float = -reach
		while off < reach:
			var o: Vector2 = c + n * off
			var line: PackedVector2Array = PackedVector2Array([o - d * reach + n * rng.randf_range(-0.8, 0.8), o + d * reach])
			for seg in Geometry2D.intersect_polyline_with_polygon(line, poly):
				if seg.size() >= 2:
					_painter.draw_line(seg[0], seg[seg.size() - 1], Color(InkDraw.INK, rng.randf_range(0.85, 1.0)), rng.randf_range(1.0, 1.6))
			off += spacing * rng.randf_range(0.8, 1.2)
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	_painter.draw_polyline(closed, InkDraw.INK, 1.6)
