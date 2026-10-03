class_name CrawlerArt
extends RefCounted
## Drawing for the Ink Crawler, shared by the enemy and scripted scares.
## Origin = where it stands. Its limbs are long jointed fingers with pen-nib
## tips: it is the Artist's hand (HandArt draws the same shapes for the reveal).

const HEIGHT: float = 240.0
const LINE: float = 6.5
const JITTER: float = 3.2
const PALE: Color = Color(0.92, 0.9, 0.82)


## `rise` 0..1 (puddle .. standing), `facing` -1 / 1, `reach` 0..1 how far the
## front fingers stretch (1 = lunge), `coil` 0..1 crouch before a lunge,
## `mouth` 0..1 how torn-open the mouth is, `drip_t` seconds for the drips.
static func draw(ci: CanvasItem, rise: float, seed_value: int, facing: float, reach: float, coil: float,
		mouth: float, drip_t: float, eye_color: Color, with_puddle: bool = true) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	if with_puddle:
		_puddle(ci, rng, 70.0 - 20.0 * rise)
	if rise <= 0.08:
		return
	var h: float = HEIGHT * rise * (1.0 - coil * 0.3)
	var f: float = facing
	# Bent spine: too long, leaning toward its prey.
	var hip: Vector2 = Vector2(-6 * f, -h * 0.22)
	var chest: Vector2 = Vector2(10 * f + rng.randf_range(-6, 6), -h * 0.62)
	var head: Vector2 = Vector2((22 + 30 * coil) * f + rng.randf_range(-5, 5), -h)
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(-24, 0), hip + Vector2(-20, 0), chest + Vector2(-14, 0), head + Vector2(-10, 12),
		head + Vector2(10, 12), chest + Vector2(14, 4), hip + Vector2(18, 0), Vector2(26, 0)])
	InkDraw.fill(ci, body, InkDraw.INK)
	InkDraw.polyline(ci, body, LINE, seed_value, true, InkDraw.INK, JITTER)
	# Legs: two fingers splayed onto the floor.
	finger(ci, hip, Vector2(-1.0 * f, 0.7).angle(), h * 0.5, 4, rng.randi(), LINE - 1.5, -0.35 * f)
	finger(ci, hip, Vector2(0.9 * f, 0.8).angle(), h * 0.48, 4, rng.randi(), LINE - 1.5, 0.3 * f)
	# Arms: two long fingers reaching ahead, straighter when lunging.
	var bend: float = lerpf(0.55, 0.08, reach)
	for i in 2:
		var dir: Vector2 = Vector2(f, lerpf(0.45, 0.05, reach) + 0.25 * i)
		finger(ci, chest, dir.angle(), h * lerpf(0.7, 1.05, reach), 6, rng.randi(), LINE - 2.0, bend * f * (1.0 if i == 0 else -0.6))
	_head(ci, rng, head, f, mouth, eye_color)
	_drips(ci, rng, h, drip_t)


## Where the head sits for a pose (without the per-frame jitter), so the eye
## glow can follow it.
static func head_position(rise: float, facing: float, coil: float) -> Vector2:
	return Vector2((22.0 + 30.0 * coil) * facing, -HEIGHT * rise * (1.0 - coil * 0.3))


## One jointed finger from `base`: `joints` segments bending alternately by
## `bend` radians, ending in a split pen nib. Returns the tip.
static func finger(ci: CanvasItem, base: Vector2, angle: float, length: float, joints: int, seed_value: int,
		width: float, bend: float) -> Vector2:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts: PackedVector2Array = PackedVector2Array([base])
	var a: float = angle
	var p: Vector2 = base
	for j in joints:
		a += bend * (1.0 if j % 2 == 0 else -0.55) + rng.randf_range(-0.18, 0.18)
		p += Vector2(cos(a), sin(a)) * length / joints
		pts.append(p)
	InkDraw.polyline(ci, pts, width, seed_value, false, InkDraw.INK, JITTER * 0.7)
	for j in range(1, pts.size() - 1):
		ci.draw_circle(pts[j], width * 0.75, InkDraw.INK)
	nib(ci, p, a, width)
	return p


## A split pen nib at `tip` pointing along `angle` (also the Artist's fingertips).
static func nib(ci: CanvasItem, tip: Vector2, angle: float, width: float) -> void:
	var d: Vector2 = Vector2(cos(angle), sin(angle))
	var side: Vector2 = Vector2(-d.y, d.x)
	var points: PackedVector2Array = PackedVector2Array([
		tip - side * width * 1.3, tip + d * width * 3.6, tip + side * width * 1.3, tip - d * width * 0.6])
	InkDraw.fill(ci, points, InkDraw.INK)
	ci.draw_line(tip + d * width * 0.4, tip + d * width * 2.8, PALE, 1.2, true)


## Smeared head, 2-4 uneven eyes, and a thin torn mouth when close.
static func _head(ci: CanvasItem, rng: RandomNumberGenerator, at: Vector2, f: float, mouth: float, eye_color: Color) -> void:
	var smear: PackedVector2Array = PackedVector2Array()
	for i in 14:
		var t: float = TAU * i / 14.0
		var r: Vector2 = Vector2(24 + rng.randf_range(-4, 4), 30 + rng.randf_range(-5, 5))
		var trail: float = 18.0 if sin(t) > 0.3 else 0.0
		smear.append(at + Vector2(cos(t) * r.x - f * trail, sin(t) * r.y + trail * 0.6))
	InkDraw.fill(ci, smear, InkDraw.INK)
	InkDraw.polyline(ci, smear, LINE - 1.0, rng.randi(), true, InkDraw.INK, JITTER)
	var eyes: Array[Vector3] = [Vector3(-9, -8, 4.5), Vector3(7, -10, 2.6), Vector3(1, 3, 3.4), Vector3(13, 1, 1.8)]
	for i in 2 + rng.randi() % 3:
		var e: Vector3 = eyes[i]
		ci.draw_circle(at + Vector2(e.x * f, e.y), e.z, eye_color)
	if mouth > 0.05:
		var m: PackedVector2Array = PackedVector2Array()
		for i in 7:
			m.append(at + Vector2((-14 + i * 4.5) * f, 15.0))
		for i in range(6, -1, -1):
			m.append(at + Vector2((-14 + i * 4.5) * f, 17.0 + mouth * rng.randf_range(3, 8)))
		InkDraw.fill(ci, m, Color(PALE, 0.85))


static func _puddle(ci: CanvasItem, rng: RandomNumberGenerator, radius: float) -> void:
	var pts: PackedVector2Array = InkDraw.ellipse_points(Vector2.ZERO, Vector2(radius, 12), 20)
	for i in pts.size():
		pts[i] *= rng.randf_range(0.88, 1.1)
	InkDraw.fill(ci, pts, InkDraw.INK)


## Ink constantly dripping off it, stepped with the stop-motion poses.
static func _drips(ci: CanvasItem, rng: RandomNumberGenerator, h: float, t: float) -> void:
	for i in 7:
		var x: float = rng.randf_range(-26, 34)
		var start: float = -h * rng.randf_range(0.2, 0.85)
		var fall: float = fmod(t * (60.0 + i * 13.0) + i * 41.0, -start + 10.0)
		ci.draw_circle(Vector2(x, start + fall), 2.5 + (i % 3), InkDraw.INK)
		ci.draw_line(Vector2(x, start), Vector2(x, start + fall * 0.6), InkDraw.INK, 2.0, true)
