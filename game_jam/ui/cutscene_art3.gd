class_name CutsceneArt3
extends RefCounted
## First-person (POV) cutscene panels (Stage 5): C2 the torch and C4 the
## descent, seen through the player's eyes (C1 went third person in Stage 6,
## see CutsceneArt5). Two layers:
##   draw()     the scene, under CutsceneView's camera (pov_* camera modes
##              look around, breathe and step)
##   overlay()  fixed to the viewer (no camera): the player's red hands and
##              forearms at the bottom, the empty bubble hanging at the edge of
##              view, a soft dark vignette (never red)
## Ids: pov_torch / pov_watch (C2), pov_stairs / pov_ink_rise (C4). Stairs and the dark room are in CutsceneArt4.


static func draw(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	match id:
		"pov_torch", "pov_watch":
			CutsceneArt4.dark_room(ci, id == "pov_watch", s, t, tick)
		"pov_stairs", "pov_ink_rise":
			CutsceneArt4.stairs(ci, id == "pov_ink_rise", s, t, tick)


static func is_pov(id: String) -> bool:
	return id.begins_with("pov_")


## The viewer-fixed layer (`_cam`: the beat's camera, unused since C1 left).
static func overlay(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int, _cam: Transform2D) -> void:
	var u: float = CutsceneArt.unit(s)
	var sway: Vector2 = Vector2(sin(t * 1.7) * 5.0, sin(t * 3.4) * 3.0)
	match id:
		"pov_torch", "pov_watch":
			var pose: Array = CutsceneArt4.torch_pose(id == "pov_watch", s, t)
			torch_hand(ci, pose[0] + sway * 0.5, pose[1], u, tick)
		"pov_stairs", "pov_ink_rise":
			CutsceneArt4.rail_hands(ci, id == "pov_ink_rise", s, t, u, sway, tick)
	vignette(ci, s, 0.75)
	BubbleArt.draw_shell(ci, Vector2(s.x * 0.06, s.y * 0.1) + sway * 1.4, Vector2(170, 92) * u * 0.6, Vector2(s.x * 0.01, s.y * 0.36),
		tick + 90, 0.92, 3.0)


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
