class_name HandArt
extends RefCounted
## The Comic Artist's hand: a black ink silhouette reaching down-left from the
## top right, its long jointed fingers ending in pen nibs, the same shapes as
## the Crawler's limbs, the Ink Shadow and the ink-hand shadow of Chapter 1.
## Used by the reveal, the return phase (ArtistHand) and the epilogue.
## `at` is the wrist; `size` is the wrist-to-fingertip length in pixels.

const PALE: Color = Color(0.92, 0.9, 0.82)
const ERASER: Color = Color(0.82, 0.8, 0.76)
## Down-left: the way a writing hand points at the page.
const DIR: Vector2 = Vector2(-0.6, 0.8)

## Finger lengths (index .. little), as a share of `size`.
const FINGERS: PackedFloat32Array = [0.44, 0.48, 0.44, 0.35]


static func _side() -> Vector2:
	return Vector2(DIR.y, -DIR.x) * -1.0


## Where the held tool touches the page (pen nib or eraser edge), relative to
## the wrist. ArtistHand uses it to bring the eraser down on a spot.
static func tool_tip(size: float, tool: StringName) -> Vector2:
	if tool == &"pen":
		return (DIR * 0.9 - _side() * 0.08) * size
	return (DIR * 0.72 + _side() * 0.02) * size


## `grip` 0 = closed round the tool, 1 = open and empty. `tool` is &"pen",
## &"eraser" or &"none". `shadow` 0..1 adds the Ink Shadow's look (pale eyes,
## drips, a rougher line) for the moment it resolves into a hand.
static func draw(ci: CanvasItem, at: Vector2, size: float, seed_value: int, grip: float = 0.0,
		tool: StringName = &"pen", shadow: float = 0.0, alpha: float = 1.0) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var d: Vector2 = DIR
	var n: Vector2 = _side()
	var ink: Color = Color(InkDraw.INK, alpha)
	var pale: Color = Color(PALE, alpha * 0.9)
	var jitter: float = 1.5 + shadow * 4.0
	# Forearm, running off the top right.
	var arm: PackedVector2Array = PackedVector2Array([
		at - d * size * 1.6 + n * size * 0.2, at + d * size * 0.12 + n * size * 0.15, at + d * size * 0.12 - n * size * 0.15, at - d * size * 1.6 - n * size * 0.22])
	InkDraw.fill(ci, arm, ink)
	ci.draw_line(at - d * size * 1.4 + n * size * 0.05, at + n * size * 0.03, pale, maxf(1.5, size * 0.006), true)
	# Palm.
	var palm_c: Vector2 = at + d * size * 0.24
	var palm: PackedVector2Array = PackedVector2Array()
	for i in 14:
		var t: float = TAU * i / 14.0
		var p: Vector2 = d * cos(t) * size * 0.2 + n * sin(t) * size * (0.17 + 0.03 * grip)
		palm.append(palm_c + p * rng.randf_range(0.94, 1.06))
	InkDraw.fill(ci, palm, ink)
	InkDraw.polyline(ci, palm, size * 0.012, seed_value, true, ink, jitter)
	if tool == &"pen":
		_pen(ci, at, size, d, n, ink, pale)
	# Thumb and four fingers; a closed grip curls them round the tool.
	var curl: float = -lerpf(0.42, 0.05, grip)
	var width: float = size * 0.065
	var thumb_base: Vector2 = palm_c - n * size * 0.15 - d * size * 0.02
	_finger(ci, thumb_base, d.rotated(lerpf(-0.5, -0.9, grip)).angle(), size * 0.3, 2, -curl * 0.8, width * 1.1, ink, pale, rng.randi())
	for i in FINGERS.size():
		var base: Vector2 = palm_c + d * size * 0.17 + n * size * (-0.11 + i * 0.075)
		var spread: float = (i - 1.2) * lerpf(0.05, 0.2, grip)
		_finger(ci, base, d.rotated(spread).angle(), size * FINGERS[i] * lerpf(0.82, 1.0, grip), 3, curl, width * (1.0 - i * 0.08), ink, pale, rng.randi())
	# Knuckle creases so the silhouette reads as a hand.
	for i in 4:
		var k: Vector2 = palm_c + d * size * 0.12 + n * size * (-0.11 + i * 0.075)
		ci.draw_arc(k, size * 0.025, d.angle() + PI * 0.6, d.angle() + PI * 1.4, 6, pale, maxf(1.0, size * 0.005), true)
	if tool == &"eraser":
		eraser(ci, at + tool_tip(size, &"eraser"), size, alpha, seed_value)
	if shadow > 0.01:
		_shadow_marks(ci, rng, palm_c, size, shadow * alpha)


## One finger: jointed segments curling the same way, pale joint marks, and a
## pen nib for a nail.
static func _finger(ci: CanvasItem, base: Vector2, angle: float, length: float, joints: int, curl: float,
		width: float, ink: Color, pale: Color, seed_value: int) -> void:
	var pts: PackedVector2Array = PackedVector2Array([base])
	var a: float = angle
	var p: Vector2 = base
	for j in joints:
		p += Vector2(cos(a), sin(a)) * length / joints
		pts.append(p)
		a += curl
	InkDraw.polyline(ci, pts, width, seed_value, false, ink, 1.5)
	for j in range(1, pts.size() - 1):
		ci.draw_circle(pts[j], width * 0.62, ink)
		var across: Vector2 = Vector2(cos(a), sin(a)).orthogonal() * width * 0.4
		ci.draw_line(pts[j] - across, pts[j] + across, pale, maxf(1.0, width * 0.08), true)
	var tip_angle: float = (pts[pts.size() - 1] - pts[pts.size() - 2]).angle()
	CrawlerArt.nib(ci, pts[pts.size() - 1], tip_angle, width * 0.55)


## A long dip pen held between thumb and index, nib to the page.
static func _pen(ci: CanvasItem, at: Vector2, size: float, d: Vector2, n: Vector2, ink: Color, pale: Color) -> void:
	var back: Vector2 = at - d * size * 0.15 + n * size * 0.22
	var tip: Vector2 = at + tool_tip(size, &"pen")
	ci.draw_line(back, tip - d * size * 0.06, ink, size * 0.05, true)
	ci.draw_line(back + n * size * 0.008, tip - d * size * 0.08, pale, maxf(1.0, size * 0.006), true)
	CrawlerArt.nib(ci, tip - d * size * 0.07, d.angle(), size * 0.022)


## A rubber eraser block, its working edge greyed with rubbed-off ink.
static func eraser(ci: CanvasItem, c: Vector2, size: float, alpha: float, seed_value: int) -> void:
	var d: Vector2 = DIR
	var n: Vector2 = _side()
	var half_l: Vector2 = n * size * 0.2
	var half_w: Vector2 = d * size * 0.09
	var block: PackedVector2Array = PackedVector2Array([c - half_l - half_w, c + half_l - half_w, c + half_l + half_w, c - half_l + half_w])
	InkDraw.shape(ci, block, maxf(2.0, size * 0.01), seed_value, Color(ERASER, alpha), Color(InkDraw.INK, alpha))
	ci.draw_line(c - half_l * 0.9 + half_w * 0.8, c + half_l * 0.9 + half_w * 0.8, Color(0.45, 0.44, 0.44, alpha), size * 0.025, true)


## Leftovers of the Shadow: pale eyes on the back of the hand, ink dripping.
static func _shadow_marks(ci: CanvasItem, rng: RandomNumberGenerator, palm_c: Vector2, size: float, amount: float) -> void:
	for i in 9:
		var p: Vector2 = palm_c + Vector2(rng.randf_range(-0.18, 0.18), rng.randf_range(-0.18, 0.18)) * size
		ci.draw_circle(p, size * rng.randf_range(0.006, 0.016), Color(PALE, amount))
	for i in 6:
		var x: Vector2 = palm_c + Vector2(rng.randf_range(-0.2, 0.2), 0.12) * size
		var drop: float = size * rng.randf_range(0.08, 0.3) * amount
		ci.draw_line(x, x + Vector2(0, drop), Color(InkDraw.INK, amount), size * 0.012, true)
		ci.draw_circle(x + Vector2(0, drop), size * 0.012, Color(InkDraw.INK, amount))
