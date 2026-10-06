class_name CutsceneArt4
extends RefCounted
## POV scenes for C2 and C4 (see CutsceneArt3 for the two layers).
##   dark_room  C2: a dark room only the torch cone shows (darkness is a fan
##              drawn round the cone, so no clipping is needed); `watching`:
##              the cone rests, a nib's shadow crosses it, eyes open outside it
##   stairs     C4: looking down a stair that runs on past the drawing into
##              pencil and dark; `ink`: black ink rising up the steps

const BEAM: Color = Color(1.0, 0.96, 0.82)


## [lens position (screen), aim angle] of the torch at time `t`.
static func torch_pose(watching: bool, s: Vector2, t: float) -> Array:
	# The lens sits just below the panel (Stage 6b: no hand holds it in view).
	if watching:
		return [Vector2(s.x * 0.64, s.y * 1.06) + Vector2(sin(t * 31.0), cos(t * 27.0)) * 1.5, -PI * 0.5 + 0.22 + sin(t * 0.8) * 0.03]
	var lift: float = smoothstep(0.0, 0.55, t)
	return [Vector2(s.x * 0.66, lerpf(s.y * 1.5, s.y * 1.06, lift)), -PI * 0.5 + sin(t * 1.5 - 1.2) * 0.62]


static func dark_room(ci: CanvasItem, watching: bool, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	var inv: Transform2D = RevealArt._current.affine_inverse()
	var pose: Array = torch_pose(watching, s, t)
	var apex: Vector2 = inv * (pose[0] as Vector2)
	var angle: float = float(pose[1]) - RevealArt._current.get_rotation()
	# The room, fully drawn; the darkness goes over it.
	ci.draw_rect(Rect2(Vector2(-80, -80), s + Vector2(160, 160)), Color(0.55, 0.53, 0.5))
	ci.draw_rect(Rect2(-80, s.y * 0.74, s.x + 160, s.y), Color(0.4, 0.38, 0.36))
	for i in 9:
		InkDraw.line(ci, Vector2(-60 + i * 150, s.y * 0.74), Vector2(-260 + i * 190, s.y + 60), 2.0, tick + i, Color(InkDraw.INK, 0.5))
	InkDraw.rect(ci, Rect2(s.x * 0.08, s.y * 0.12, 120 * u, 150 * u), 6.0, tick + 10, Color(0.5, 0.46, 0.4))
	ScareArt.hollow_face(ci, Vector2(s.x * 0.08 + 60 * u, s.y * 0.12 + 70 * u), 0.42 * u, 17)
	var font_size: int = int(30 * u)
	CutsceneArt.text(ci, Vector2(s.x * 0.5, s.y * 0.3), "IT SEES", font_size, Color(InkDraw.RED, 0.9))
	CutsceneArt.text(ci, Vector2(s.x * 0.5, s.y * 0.3 + 34 * u), "THE LIGHT", font_size, Color(InkDraw.RED, 0.9))
	for i in 5:
		ci.draw_circle(Vector2(s.x * 0.5 + (i - 2) * 30 * u, s.y * 0.3 + 44 * u + fmod(t * 20.0 + i * 13.0, 40.0) * u), 2.5 * u, Color(InkDraw.RED, 0.8))
	InkDraw.rect(ci, Rect2(s.x * 0.78, s.y * 0.08, 110 * u, s.y * 0.66), 5.0, tick + 11, Color(0.35, 0.3, 0.27))
	for i in 6:
		InkDraw.line(ci, Vector2(s.x * 0.97, 0), Vector2(s.x * 0.97 - (40 + i * 24) * u, (10 + i * 22) * u), 1.0, tick + 12 + i, Color(0.9, 0.9, 0.9, 0.6), 0.5)
	if watching:
		# Something huge passes between the light and the wall.
		var x: float = lerpf(-0.3, 1.1, clampf((t - 0.6) / 1.6, 0.0, 1.0)) * s.x
		var tip: Vector2 = Vector2(x, s.y * 0.66)
		ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-110, -300) * u, tip + Vector2(-30, -380) * u, tip + Vector2(70, -330) * u]),
			Color(0, 0, 0, 0.6))
	var half: float = 0.36
	ci.draw_colored_polygon(PackedVector2Array([apex, apex + Vector2.from_angle(angle - half) * 3000.0, apex + Vector2.from_angle(angle + half) * 3000.0]),
		Color(BEAM, 0.14))
	_motes(ci, apex, angle, half, s, t)
	_darkness(ci, apex, angle, half, 0.95)
	_darkness(ci, apex, angle, half * 0.8, 0.4)
	if watching:
		for e in [Vector3(0.14, 0.42, 0.0), Vector3(0.24, 0.58, 0.6), Vector3(0.9, 0.36, 1.1)]:
			var open: float = clampf((t - e.z) / 0.3, 0.0, 1.0)
			var at: Vector2 = Vector2(s.x * e.x, s.y * e.y)
			for dx in [-12.0, 12.0]:
				ci.draw_colored_polygon(InkDraw.ellipse_points(at + Vector2(dx, 0) * u, Vector2(7, 5 * open + 0.5) * u, 10), CrawlerArt.PALE)


## Darkness everywhere except the cone (`half` its half-angle) from `apex`.
static func _darkness(ci: CanvasItem, apex: Vector2, angle: float, half: float, alpha: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([apex])
	for i in 25:
		pts.append(apex + Vector2.from_angle(angle + half + (TAU - 2.0 * half) * i / 24.0) * 3000.0)
	ci.draw_colored_polygon(pts, Color(0.02, 0.02, 0.03, alpha))


## Dust drifting in the beam.
static func _motes(ci: CanvasItem, apex: Vector2, angle: float, half: float, s: Vector2, t: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12
	for i in 30:
		var r: float = fposmod(rng.randf() * 600.0 + t * 25.0, 600.0) + 60.0
		var a: float = angle + rng.randf_range(-half, half) * 0.9 + sin(t + i) * 0.02
		ci.draw_circle(apex + Vector2.from_angle(a) * r, rng.randf_range(1.0, 2.5), Color(1, 1, 1, 0.5))


## Looking down the stair. Steps narrow toward a vanishing point; past it the
## stair keeps going as pencil lines into the dark. `ink`: it rises to meet you.
static func stairs(ci: CanvasItem, ink: bool, s: Vector2, t: float, tick: int) -> void:
	var u: float = CutsceneArt.unit(s)
	var v: Vector2 = Vector2(s.x * 0.52, s.y * 0.62)
	ci.draw_rect(Rect2(Vector2(-80, -80), s + Vector2(160, 160)), Color(0.2, 0.19, 0.21))
	ci.draw_colored_polygon(InkDraw.ellipse_points(v + Vector2(0, 40 * u), Vector2(220, 120) * u, 24), Color(0, 0, 0, 0.8))
	var left: Vector2 = Vector2(-80, s.y + 60)
	var right: Vector2 = Vector2(s.x + 80, s.y + 60)
	InkDraw.shape(ci, PackedVector2Array([Vector2(-80, -80), v + Vector2(-90, -150) * u, v + Vector2(-60, 10) * u, left]), 4.0, tick, Color(0.32, 0.3, 0.3))
	InkDraw.shape(ci, PackedVector2Array([Vector2(s.x + 80, -80), v + Vector2(90, -150) * u, v + Vector2(60, 10) * u, right]), 4.0, tick + 1, Color(0.27, 0.25, 0.26))
	InkDraw.hatch(ci, Rect2(s.x * 0.8, 0, s.x * 0.2, s.y), 11.0, 1.2, tick + 2, Color(0, 0, 0, 0.4))
	var steps: int = 11
	for i in steps:
		var k0: float = pow(float(i) / steps, 0.7)
		var k1: float = pow(float(i + 1) / steps, 0.7)
		var a0: Vector2 = left.lerp(v + Vector2(-60, 10) * u, k0)
		var b0: Vector2 = right.lerp(v + Vector2(60, 10) * u, k0)
		var a1: Vector2 = left.lerp(v + Vector2(-60, 10) * u, k1)
		var b1: Vector2 = right.lerp(v + Vector2(60, 10) * u, k1)
		var mid0: float = lerpf(a0.y, a1.y, 0.55)
		InkDraw.shape(ci, PackedVector2Array([a0, b0, Vector2(b1.x, mid0), Vector2(a1.x, mid0)]), 3.0, tick + 4 + i, Color(0.6, 0.58, 0.55).darkened(k0 * 0.6))
		InkDraw.shape(ci, PackedVector2Array([Vector2(a1.x, mid0), Vector2(b1.x, mid0), b1, a1]), 2.5, tick + 20 + i, Color(0.3, 0.29, 0.3).darkened(k0 * 0.5))
	# Further than the drawing does: pencil steps on into the dark.
	InkDraw.gap_ratio = 0.55
	for i in 6:
		var w: float = (50.0 - i * 7.0) * u
		var y: float = v.y + (16 + i * 13) * u
		InkDraw.line(ci, Vector2(v.x - w, y), Vector2(v.x + w, y), 1.5, tick + 40 + i, CutsceneArt2.PENCIL, 0.6)
	InkDraw.gap_ratio = 0.0
	if ink:
		var level: float = lerpf(v.y + 30 * u, s.y * 0.72, smoothstep(0.0, 2.6, t))
		var top: PackedVector2Array = PackedVector2Array([Vector2(-80, s.y + 80)])
		for i in 15:
			var x: float = -80.0 + (s.x + 160.0) * i / 14.0
			top.append(Vector2(x, level + sin(x * 0.025 + t * 4.0) * 7.0 * u + absf(x - v.x) * 0.06))
		top.append(Vector2(s.x + 80, s.y + 80))
		ci.draw_colored_polygon(top, InkDraw.INK)
		for i in 4:
			var e: Vector2 = Vector2(s.x * (0.22 + i * 0.19), level + (40 + (i % 2) * 30) * u)
			var blink: float = 1.0 if fmod(t + i * 0.7, 2.2) > 0.18 else 0.1
			for dx in [-10.0, 10.0]:
				ci.draw_circle(e + Vector2(dx, 0) * u, 5.0 * u, Color(CrawlerArt.PALE, blink))
		for i in 6:
			ci.draw_arc(Vector2(s.x * (0.1 + i * 0.16), level - 3.0), (4.0 + (i % 3) * 3.0) * u, PI, TAU, 8, InkDraw.INK, 3.0)


## Your hand(s) on the stair rail (a bannister running up from the bottom
## left). `ink`: both hands, trembling.
static func rail_hands(ci: CanvasItem, ink: bool, s: Vector2, t: float, u: float, sway: Vector2, tick: int) -> void:
	var shake: Vector2 = Vector2(sin(t * 37.0), cos(t * 29.0)) * (4.0 if ink else 0.0)
	var r0: Vector2 = Vector2(-40, s.y * 1.05)
	var r1: Vector2 = Vector2(s.x * 0.3, s.y * 0.55)
	InkDraw.line(ci, r0, r1 + sway, 30.0 * u, tick, Color(0.42, 0.36, 0.3))
	InkDraw.line(ci, r0 + Vector2(0, 12) * u, r1 + sway + Vector2(0, 12) * u, 4.0, tick + 1, Color(0, 0, 0, 0.5))
	var along: Vector2 = (r1 + sway - r0).normalized()
	var on_rail: Vector2 = r0.lerp(r1 + sway, 0.5) + shake
	CutsceneArt3.hand(ci, on_rail + along.orthogonal() * 6.0 * u, along.rotated(-1.35), u * 1.0, 0.95, tick + 10)
	if ink:
		var tip: Vector2 = Vector2(s.x * 0.8, s.y * 0.72) + shake * 1.5 + sway
		CutsceneArt3.hand(ci, tip, Vector2(-0.3, -0.95).normalized(), u * 1.05, 0.25, tick + 20)
