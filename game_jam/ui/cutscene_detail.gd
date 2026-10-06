class_name CutsceneDetail
extends RefCounted
## More detail in the cutscene panels (Stage 5), inside the same beats:
##   texture()  every panel, after the camera: halftone shading toward one
##              corner and a couple of ink splatters, seeded per drawing so
##              they stay put (the line boil is the only motion)
##   extra()    per drawing id, under the camera: background props, texture
##              and small secondary motion (curtains, a pendulum, dust, drips,
##              pulse rings, paper flakes). Black and white plus the red player.

const SEPIA_INK: Color = Color(0.35, 0.3, 0.26)


## Halftone dots per (seed, panel size), built once: [indices, points, colors].
static var _dots: Dictionary = {}


static func texture(ci: CanvasItem, s: Vector2, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var corner: Vector2 = Vector2(s.x if rng.randf() < 0.5 else 0.0, s.y if rng.randf() < 0.7 else 0.0)
	# The ~900 dots go down as ONE cached triangle array (Stage 6: was a
	# draw_rect each, the panels' biggest per-frame cost).
	var key: String = "%d_%d_%d" % [seed_value, int(s.x), int(s.y)]
	if not _dots.has(key):
		_dots[key] = _dot_field(s, corner)
	var d: Array = _dots[key]
	if not (d[1] as PackedVector2Array).is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), d[0], d[1], d[2])
	for i in 2:
		var at: Vector2 = Vector2(rng.randf_range(0.05, 0.95) * s.x, (0.06 if rng.randf() < 0.5 else 0.92) * s.y)
		splatter(ci, at, rng.randf_range(6.0, 12.0), rng.randi(), Color(InkDraw.INK, 0.8))


static func _dot_field(s: Vector2, corner: Vector2) -> Array:
	var reach: float = minf(s.x, s.y) * 0.7
	var step: float = 12.0
	var count: int = int(reach / step)
	var dir: Vector2 = Vector2(-1.0 if corner.x > 0.0 else 1.0, -1.0 if corner.y > 0.0 else 1.0)
	var indices: PackedInt32Array = PackedInt32Array()
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for gy in count:
		for gx in count:
			var p: Vector2 = corner + Vector2(gx * step + (step * 0.5 if gy % 2 == 1 else 0.0), gy * step) * dir
			var dist: float = p.distance_to(corner) / reach
			if dist < 1.0:
				var h: float = (1.0 - dist) * 2.0
				var n: int = points.size()
				points.append_array([p + Vector2(-h, -h), p + Vector2(h, -h), p + Vector2(h, h), p + Vector2(-h, h)])
				for c in 4:
					colors.append(Color(0, 0, 0, 0.2))
				indices.append_array([n, n + 1, n + 2, n, n + 2, n + 3])
	return [indices, points, colors]


## An ink splat: a ragged blob, flecks and a couple of streaks.
static func splatter(ci: CanvasItem, at: Vector2, size: float, seed_value: int, color: Color) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 12:
		pts.append(at + Vector2.from_angle(TAU * i / 12.0) * size * rng.randf_range(0.6, 1.3))
	InkDraw.fill(ci, pts, color)
	for i in 7:
		var a: float = rng.randf() * TAU
		ci.draw_circle(at + Vector2.from_angle(a) * size * rng.randf_range(1.6, 3.4), rng.randf_range(1.0, 2.8), color)
	for i in 2:
		var a2: float = rng.randf() * TAU
		ci.draw_line(at + Vector2.from_angle(a2) * size, at + Vector2.from_angle(a2) * size * rng.randf_range(2.5, 4.0), color, 2.0)


static func extra(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	match id:
		"story_tea":
			_tea_room(ci, s, t, u, tick)
		"story_family", "story_gap":
			_old_photo(ci, s, t, u, tick)
		"story_door":
			_boarded(ci, s, t, u, tick)
		"sketch_through":
			_construction(ci, s, t, u, tick)
		"torn_panels":
			_flakes(ci, s, t, u, Color(0.8, 0.78, 0.74), 18)
		"shadow_hang":
			_drips(ci, Vector2(s.x * 0.62, s.y * 0.36), s, t, u)
			InkDraw.hatch(ci, Rect2(0, s.y * 0.88, s.x, s.y * 0.12), 9.0, 1.0, tick + 5, Color(0.8, 0.78, 0.74, 0.25))
		"eraser_dust":
			_rubbed_floor(ci, s, t, u, tick)
		"repair_panel":
			_redrawn_props(ci, s, t, u, tick)
		"whole_cast":
			_rays(ci, s, t, Vector2(s.x * 0.95, -20))
			for x in [0.2, 0.8]:
				ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(s.x * x, s.y * 0.93), Vector2(46, 9) * u, 14), Color(0, 0, 0, 0.18))
			_flakes(ci, s, t, u, Color(1, 1, 1, 0.7), 10)
		"border_gap":
			_rays(ci, s, t, Vector2(s.x + 10, s.y * 0.7))
			_flakes(ci, s, t, u, Color(1, 0.97, 0.86, 0.8), 12)


## C3 tea: a wall clock with a swinging pendulum, a curtained window, floorboards.
static func _tea_room(ci: CanvasItem, s: Vector2, t: float, u: float, tick: int) -> void:
	var clock: Vector2 = Vector2(s.x * 0.14, s.y * 0.2)
	InkDraw.rect(ci, Rect2(clock - Vector2(22, 26) * u, Vector2(44, 110) * u), 3.0, tick + 70, Color(0.7, 0.62, 0.5), SEPIA_INK)
	InkDraw.ellipse(ci, clock, Vector2(17, 17) * u, 2.5, tick + 71, Color(0.95, 0.92, 0.84), SEPIA_INK)
	InkDraw.line(ci, clock, clock + Vector2(0, -12) * u, 2.0, tick + 72, SEPIA_INK)
	InkDraw.line(ci, clock, clock + Vector2(9, 3) * u, 2.0, tick + 73, SEPIA_INK)
	var bob: Vector2 = clock + Vector2(sin(t * 3.2) * 12.0, 70.0) * u
	InkDraw.line(ci, clock + Vector2(0, 22) * u, bob, 2.0, tick + 74, SEPIA_INK)
	ci.draw_circle(bob, 6.0 * u, SEPIA_INK)
	var win: Rect2 = Rect2(s.x * 0.74, s.y * 0.1, 90 * u, 110 * u)
	InkDraw.rect(ci, win, 3.0, tick + 75, Color(0.98, 0.96, 0.9), SEPIA_INK)
	for side in [0.0, 1.0]:
		var top: Vector2 = Vector2(win.position.x + side * win.size.x, win.position.y)
		var sway: float = sin(t * 1.4 + side) * 6.0 * u
		InkDraw.shape(ci, PackedVector2Array([top, top + Vector2(28 * u * (1.0 - side * 2.0), 0), top + Vector2(18 * u * (1.0 - side * 2.0) + sway, win.size.y + 12 * u),
			top + Vector2(sway, win.size.y + 12 * u)]), 2.0, tick + 76, Color(0.82, 0.74, 0.62), SEPIA_INK)
	for i in 6:
		InkDraw.line(ci, Vector2(-20 + i * s.x * 0.2, s.y * 0.84), Vector2(-60 + i * s.x * 0.22, s.y + 20), 1.5, tick + 77 + i, Color(SEPIA_INK, 0.5))


## C3 portraits: photo corners, foxing stains, scratches and floating dust.
static func _old_photo(ci: CanvasItem, s: Vector2, t: float, u: float, tick: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 33
	for i in 5:
		ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(rng.randf() * s.x, rng.randf() * s.y), Vector2(rng.randf_range(14, 34), rng.randf_range(10, 24)) * u, 12),
			Color(0.6, 0.45, 0.3, 0.12))
	for i in 4:
		var a: Vector2 = Vector2(rng.randf() * s.x, rng.randf() * s.y * 0.5)
		ci.draw_line(a, a + Vector2(rng.randf_range(-20, 20), rng.randf_range(60, 160)) * u, Color(1, 1, 1, 0.35), 1.0)
	for corner in [Vector2(0.08, 0.08), Vector2(0.92, 0.08), Vector2(0.92, 0.92), Vector2(0.08, 0.92)]:
		var c: Vector2 = corner * s
		var d: Vector2 = Vector2(-1.0 if corner.x > 0.5 else 1.0, -1.0 if corner.y > 0.5 else 1.0) * 26.0 * u
		InkDraw.shape(ci, PackedVector2Array([c, c + Vector2(d.x, 0), c + Vector2(0, d.y)]), 2.0, tick + 80, SEPIA_INK, SEPIA_INK)
	_flakes(ci, s, t, u, Color(0.4, 0.35, 0.3, 0.5), 10)


## C3 cellar door: boards nailed across it, cracks round the frame, ink seeping under.
static func _boarded(ci: CanvasItem, s: Vector2, t: float, u: float, tick: int) -> void:
	var door: Rect2 = Rect2(s.x * 0.5 - 70 * u, s.y * 0.88 - 220 * u, 140 * u, 220 * u)
	for i in 2:
		var y: float = door.position.y + (60 + i * 100) * u
		var plank: PackedVector2Array = PackedVector2Array([Vector2(door.position.x - 14 * u, y - 18 * u), Vector2(door.end.x + 14 * u, y + 6 * u),
			Vector2(door.end.x + 14 * u, y + 24 * u), Vector2(door.position.x - 14 * u, y)])
		InkDraw.shape(ci, plank, 3.0, tick + 90 + i, Color(0.6, 0.5, 0.4), SEPIA_INK)
		for x in [door.position.x - 4 * u, door.end.x + 4 * u]:
			ci.draw_circle(Vector2(x, y + (2.0 if x < door.get_center().x else 14.0) * u), 3.0 * u, InkDraw.INK)
	for i in 4:
		var a: Vector2 = door.position + Vector2(-4 * u if i < 2 else door.size.x + 4 * u, door.size.y * (0.2 + i % 2 * 0.4))
		InkDraw.polyline(ci, PackedVector2Array([a, a + Vector2(-12 if i < 2 else 12, 16) * u, a + Vector2(-6 if i < 2 else 6, 34) * u]), 1.5, tick + 95 + i, false, SEPIA_INK)
	var seep: float = clampf(t / 2.5, 0.0, 1.0)
	ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(door.get_center().x, door.end.y + 4 * u), Vector2(60 * seep + 4, 7 * seep + 1) * u, 16), InkDraw.INK)


## C5: pencil construction marks round the drawing, and pulse rings from the Heart.
static func _construction(ci: CanvasItem, s: Vector2, t: float, u: float, tick: int) -> void:
	for i in 3:
		ci.draw_arc(s * 0.5, (90.0 + i * 70.0) * u, -0.4 + i, 1.9 + i, 24, CutsceneArt2.PENCIL, 1.0)
	for i in 20:
		var x: float = s.x * i / 19.0
		ci.draw_line(Vector2(x, 0), Vector2(x, 16.0 if i % 5 == 0 else 8.0), CutsceneArt2.PENCIL, 1.0)
	ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(s.x * 0.22, s.y * 0.72), Vector2(60, 18) * u, 14), Color(0.7, 0.7, 0.72, 0.25))
	for i in 3:
		var k: float = fposmod(t * 0.8 + i / 3.0, 1.0)
		ci.draw_arc(s * 0.5, (60.0 + k * 200.0) * u, 0.0, TAU, 40, Color(InkDraw.INK, 0.5 * (1.0 - k)), 2.0)
	InkDraw.line(ci, Vector2(s.x * 0.86, s.y * 0.1), Vector2(s.x * 0.94, s.y * 0.3), 4.0 * u, tick + 100, CutsceneArt2.PENCIL)


## Bits of paper / dust drifting slowly down.
static func _flakes(ci: CanvasItem, s: Vector2, t: float, u: float, color: Color, count: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	for i in count:
		var x: float = rng.randf() * s.x + sin(t * 1.3 + i) * 10.0
		var y: float = fposmod(rng.randf() * s.y + t * rng.randf_range(12.0, 30.0) * u, s.y)
		var size: float = rng.randf_range(2.0, 5.0) * u
		ci.draw_set_transform_matrix(RevealArt._current * Transform2D(t * rng.randf_range(-2.0, 2.0), Vector2(x, y)))
		ci.draw_rect(Rect2(-size, -size * 0.6, size * 2.0, size * 1.2), color)
	ci.draw_set_transform_matrix(RevealArt._current)


## C5: ink dripping off the hand's fingers.
static func _drips(ci: CanvasItem, from: Vector2, s: Vector2, t: float, u: float) -> void:
	for i in 5:
		var x: float = from.x + (i - 2) * 26.0 * u
		var y: float = from.y + fposmod(t * 140.0 + i * 47.0, s.y * 0.55)
		ci.draw_circle(Vector2(x, y), 3.5 * u, InkDraw.INK)
		ci.draw_line(Vector2(x, y - 12 * u), Vector2(x, y), InkDraw.INK, 2.0 * u)


## C6: rubbed streaks on the floor, crumbs bouncing.
static func _rubbed_floor(ci: CanvasItem, s: Vector2, t: float, u: float, tick: int) -> void:
	for i in 4:
		var c: Vector2 = Vector2(s.x * (0.3 + i * 0.13), s.y * 0.84)
		ci.draw_colored_polygon(InkDraw.ellipse_points(c, Vector2(50, 8) * u, 14), Color(0.7, 0.68, 0.66, 0.5))
	for i in 8:
		var hop: float = absf(sin(t * 5.0 + i)) * 14.0 * u * maxf(0.0, 1.0 - t * 0.3)
		ci.draw_rect(Rect2(s.x * (0.28 + i * 0.06), s.y * 0.85 - hop, 4 * u, 3 * u), Color(0.55, 0.53, 0.5))
	InkDraw.hatch(ci, Rect2(0, s.y * 0.87, s.x, s.y * 0.13), 10.0, 1.0, tick + 110, Color(InkDraw.INK, 0.2))


## C6: the room's furniture redrawing in after its walls.
static func _redrawn_props(ci: CanvasItem, s: Vector2, t: float, u: float, tick: int) -> void:
	var k: float = clampf((t - 1.6) / 0.6, 0.0, 1.0)
	if k <= 0.0:
		return
	var ink: Color = Color(InkDraw.INK, k)
	InkDraw.rect(ci, Rect2(s.x * 0.24, s.y * 0.4, 70 * u, 50 * u), 3.0, tick + 120, Color(1, 1, 1, 0.0), ink)
	InkDraw.line(ci, Vector2(s.x * 0.3, s.y * 0.82), Vector2(s.x * 0.3, s.y * 0.6), 3.0, tick + 121, ink)
	InkDraw.shape(ci, PackedVector2Array([Vector2(s.x * 0.27, s.y * 0.6), Vector2(s.x * 0.33, s.y * 0.6), Vector2(s.x * 0.35, s.y * 0.52),
		Vector2(s.x * 0.25, s.y * 0.52)]), 2.5, tick + 122, Color(1, 1, 1, 0.0), ink)
	ci.draw_colored_polygon(InkDraw.ellipse_points(Vector2(s.x * 0.3, s.y * 0.56), Vector2(60, 40) * u, 16), Color(1, 0.97, 0.86, 0.3 * k))


## Soft light rays from `from` across the panel.
static func _rays(ci: CanvasItem, s: Vector2, t: float, from: Vector2) -> void:
	for i in 4:
		var a: float = PI * 0.62 + i * 0.12 + sin(t * 0.6 + i) * 0.02
		var d: Vector2 = Vector2.from_angle(a)
		ci.draw_colored_polygon(PackedVector2Array([from, from + d.rotated(-0.03) * s.x * 1.4, from + d.rotated(0.03) * s.x * 1.4]),
			Color(1, 0.97, 0.86, 0.12))
