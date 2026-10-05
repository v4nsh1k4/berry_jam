class_name CutsceneArt3
extends RefCounted
## First-person (POV) cutscene panels (Stage 5): C1 the first steal, C2 the
## torch, C4 the descent, seen through the player's eyes. Two layers:
##   draw()     the scene, under CutsceneView's camera (pov_* camera modes
##              look around, breathe and step)
##   overlay()  fixed to the viewer (no camera): the player's red hands and
##              forearms at the bottom, the empty bubble hanging at the edge of
##              view, a soft dark vignette (never red)
## Ids: pov_reach / pov_thin (C1), pov_torch / pov_watch (C2), pov_stairs /
## pov_ink_rise (C4). Stairs and the dark room are in CutsceneArt4.

const TEAR_AT: float = 1.05
const WALL: Color = Color(0.84, 0.82, 0.77)


static func draw(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	match id:
		"pov_reach", "pov_thin":
			_landing(ci, s, t, tick, id == "pov_thin")
		"pov_torch", "pov_watch":
			CutsceneArt4.dark_room(ci, id == "pov_watch", s, t, tick)
		"pov_stairs", "pov_ink_rise":
			CutsceneArt4.stairs(ci, id == "pov_ink_rise", s, t, tick)


static func is_pov(id: String) -> bool:
	return id.begins_with("pov_")


## The viewer-fixed layer. `cam` is the beat's camera (to reach scene points).
static func overlay(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int, cam: Transform2D) -> void:
	var u: float = CutsceneArt.unit(s)
	var sway: Vector2 = Vector2(sin(t * 1.7) * 5.0, sin(t * 3.4) * 3.0)
	match id:
		"pov_reach":
			var target: Vector2 = cam * bubble_at(s)
			var up: float = smoothstep(0.0, 0.85, t)
			var back: float = smoothstep(TEAR_AT, 2.1, t)
			var tip: Vector2 = Vector2(s.x * 0.78, s.y * 1.25).lerp(target + Vector2(30, 20) * u, up).lerp(Vector2(s.x * 0.7, s.y * 0.8), back)
			var grip: float = smoothstep(0.8, TEAR_AT, t)
			hand(ci, tip + sway, (tip - Vector2(s.x * 0.95, s.y * 1.4)).normalized(), u * 1.15, grip, tick)
			if t >= TEAR_AT:
				_scrap(ci, tip + sway + Vector2(-10, -16) * u, u, back, tick)
		"pov_thin":
			var tip2: Vector2 = Vector2(s.x * 0.26, s.y * 0.62) + sway * 1.6 + Vector2(sin(t * 23.0), cos(t * 19.0)) * 2.0
			hand(ci, tip2, Vector2(0.35, -0.94), u * 1.0, 0.85, tick)
			_scrap(ci, tip2 + Vector2(12, 26) * u, u, 1.0, tick)
		"pov_torch", "pov_watch":
			var pose: Array = CutsceneArt4.torch_pose(id == "pov_watch", s, t)
			torch_hand(ci, pose[0] + sway * 0.5, pose[1], u, tick)
		"pov_stairs", "pov_ink_rise":
			CutsceneArt4.rail_hands(ci, id == "pov_ink_rise", s, t, u, sway, tick)
	vignette(ci, s, 0.75)
	BubbleArt.draw_shell(ci, Vector2(s.x * 0.06, s.y * 0.1) + sway * 1.4, Vector2(170, 92) * u * 0.6, Vector2(s.x * 0.01, s.y * 0.36),
		tick + 90, 0.92, 3.0)


## Arthur's bubble in the landing scene (scene space).
static func bubble_at(s: Vector2) -> Vector2:
	return Vector2(s.x * 0.44, s.y * 0.22)


## C1: the landing at eye level. Arthur close, his bubble between you; after
## the tear, a hole where the word was. `thin`: his lines and the room's go
## faint and broken, his bubble only "...".
static func _landing(ci: CanvasItem, s: Vector2, t: float, tick: int, thin: bool) -> void:
	var u: float = CutsceneArt.unit(s)
	var fade: float = clampf(t / 2.4, 0.0, 1.0) if thin else 0.0
	ci.draw_rect(Rect2(Vector2(-60, -60), s + Vector2(120, 120)), WALL)
	InkDraw.gap_ratio = 0.1 + 0.45 * fade
	for i in 16:
		var x: float = -40.0 + i * 76.0
		InkDraw.line(ci, Vector2(x, -40), Vector2(x, s.y * 0.66), 1.5, tick + i, Color(0.62, 0.6, 0.56, 1.0 - fade * 0.6), 0.6)
		ci.draw_circle(Vector2(x + 38, s.y * 0.2 + (i % 2) * 60), 4.0, Color(0.62, 0.6, 0.56, 0.6))
	InkDraw.rect(ci, Rect2(-40, s.y * 0.66, s.x + 80, s.y * 0.14), 4.0, tick + 20, Color(0.7, 0.68, 0.63))
	CutsceneArt.floor_line(ci, s, s.y * 0.8, tick + 21)
	InkDraw.rect(ci, Rect2(s.x * 0.06, s.y * 0.14, 150 * u * 0.6, 190 * u * 0.6), 7.0, tick + 22, Color(0.5, 0.47, 0.42))
	InkDraw.hatch(ci, Rect2(s.x * 0.08, s.y * 0.18, 110 * u * 0.6, 150 * u * 0.6), 9.0, 1.0, tick + 23, Color(InkDraw.INK, 0.4))
	InkDraw.rect(ci, Rect2(s.x * 0.86, s.y * 0.05, 200 * u * 0.6, s.y), 6.0, tick + 24, Color(0.45, 0.4, 0.36))
	ci.draw_circle(Vector2(s.x * 0.885, s.y * 0.5), 7.0 * u, Color(0.75, 0.7, 0.5))
	RevealArt._character(ci, &"butler", Vector2(s.x * (0.6 if not thin else 0.5), s.y * 1.1), u * 1.55, tick)
	InkDraw.gap_ratio = 0.0
	var c: Vector2 = bubble_at(s) + (Vector2(-s.x * 0.06, 0) if thin else Vector2.ZERO)
	var mouth: Vector2 = Vector2(s.x * (0.6 if not thin else 0.5), s.y * 0.36)
	if not thin and t < TEAR_AT:
		BubbleArt.draw(ci, c, "OPEN", mouth, tick + 30, int(30 * u), 1.0, 4.0)
		return
	BubbleArt.draw_shell(ci, c, Vector2(200, 100) * u * 0.62, mouth, tick + 30, 1.0, 4.0)
	if thin:
		CutsceneArt.text(ci, c + Vector2(0, 10 * u), "...", int(30 * u))
		return
	var hole: PackedVector2Array = PackedVector2Array()
	for i in 12:
		var a: float = TAU * i / 12.0
		hole.append(c + Vector2(cos(a) * 1.8, sin(a) * 0.8) * (24.0 + (i % 2) * 10.0) * u)
	InkDraw.fill(ci, hole, Color(0.9, 0.88, 0.82))
	InkDraw.polyline(ci, hole, 2.5 * u, tick + 31, true)
	for i in 6:
		ci.draw_circle(c + Vector2(-30 + i * 12, 30 + fmod((t - TEAR_AT) * 120.0 + i * 23.0, 160.0)) * u, 3.0 * u, InkDraw.INK)


## The torn-off word in your fingers, crumpling as `k` goes 0..1.
static func _scrap(ci: CanvasItem, at: Vector2, u: float, k: float, tick: int) -> void:
	var size: Vector2 = Vector2(lerpf(150.0, 96.0, k), lerpf(70.0, 52.0, k)) * u * 0.6
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 14:
		var a: float = TAU * i / 14.0
		pts.append(at + Vector2(cos(a) * size.x * 0.5, sin(a) * size.y * 0.5) * (1.0 - 0.18 * k * float(i % 2)))
	InkDraw.shape(ci, pts, 3.0, tick + 40, InkDraw.WHITE)
	CutsceneArt.text(ci, at + Vector2(0, 9 * u), "OPEN", int(lerpf(26.0, 19.0, k) * u))


## The player's red hand from below: forearm off the bottom edge, fingers
## toward `dir`; `grip` 0 open .. 1 pinched (thumb meets the index).
static func hand(ci: CanvasItem, tip: Vector2, dir: Vector2, k: float, grip: float, tick: int) -> void:
	var side: Vector2 = dir.orthogonal()
	var knuckles: Vector2 = tip - dir * 58.0 * k
	var palm: Vector2 = knuckles - dir * 34.0 * k
	var wrist: Vector2 = palm - dir * 44.0 * k
	var elbow: Vector2 = wrist - dir * 520.0 * k
	var red: Color = InkDraw.RED
	InkDraw.shape(ci, PackedVector2Array([elbow + side * 64 * k, wrist + side * 30 * k, wrist - side * 30 * k, elbow - side * 64 * k]), 4.0, tick, red)
	InkDraw.line(ci, wrist - dir * 140.0 * k - side * 20 * k, elbow - side * 40 * k, 2.0, tick + 1, Color(0, 0, 0, 0.35))
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 16:
		var a: float = TAU * i / 16.0
		pts.append(palm + (dir * cos(a) * 46.0 + side * sin(a) * 40.0) * k)
	InkDraw.shape(ci, pts, 4.0, tick + 2, red)
	for i in 4:
		var base: Vector2 = knuckles - dir * 8.0 * k + side * (-27.0 + i * 18.0) * k
		var length: float = [50.0, 56.0, 52.0, 40.0][i] * k * (1.0 - 0.5 * grip * (0.0 if i == 0 else 1.0))
		var bend: Vector2 = dir.rotated(-0.12 * (i - 1.5) + grip * 0.5 * (0.0 if i == 0 else 1.0))
		IntroArt2.digit(ci, base, base + bend * length, 14.0 * k, red, tick + 3 + i)
	var index_tip: Vector2 = knuckles - dir * 8.0 * k - side * 27.0 * k + dir.rotated(0.18) * 50.0 * k
	var thumb_base: Vector2 = palm - side * 38.0 * k
	var thumb_tip: Vector2 = (thumb_base + dir.rotated(-0.8) * 46.0 * k).lerp(index_tip + side * 6.0 * k, grip)
	IntroArt2.digit(ci, thumb_base, thumb_tip, 15.0 * k, red, tick + 8)


## Your hand holding the torch at `lens`, pointing along `angle`: a fist
## round the barrel, the forearm running on behind it out of view.
static func torch_hand(ci: CanvasItem, lens: Vector2, angle: float, u: float, tick: int) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var side: Vector2 = dir.orthogonal()
	var back: Vector2 = lens - dir * 170.0 * u
	InkDraw.shape(ci, PackedVector2Array([lens + side * 22 * u, lens - side * 22 * u, back - side * 17 * u, back + side * 17 * u]), 4.0, tick,
		Color(0.25, 0.24, 0.27))
	InkDraw.line(ci, lens - dir * 20.0 * u + side * 12.0 * u, back + side * 10.0 * u, 2.0, tick + 2, Color(1, 1, 1, 0.25))
	hand(ci, lens - dir * 40.0 * u, dir, u * 0.8, 1.0, tick + 10)
	InkDraw.ellipse(ci, lens, Vector2(24, 10) * u, 3.0, tick + 1, Color(1.0, 0.97, 0.85))


## A soft dark edge round the view (never red): gradient trapezoids.
static func vignette(ci: CanvasItem, s: Vector2, strength: float) -> void:
	var d: float = minf(s.x, s.y) * 0.22
	var dark: Color = Color(0.02, 0.02, 0.03, strength)
	var clear: Color = Color(0.02, 0.02, 0.03, 0.0)
	var outer: Array[Vector2] = [Vector2(0, 0), Vector2(s.x, 0), s, Vector2(0, s.y)]
	var inner: Array[Vector2] = [Vector2(d, d), Vector2(s.x - d, d), s - Vector2(d, d), Vector2(d, s.y - d)]
	for i in 4:
		var j: int = (i + 1) % 4
		ci.draw_polygon(PackedVector2Array([outer[i], outer[j], inner[j], inner[i]]), PackedColorArray([dark, dark, clear, clear]))
