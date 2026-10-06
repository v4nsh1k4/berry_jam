class_name RoomDecor
extends Node2D
## Atmospheric decor from FrameData (Stage 6), black and white, panel space:
##   webs         (x, y, size, angle°) cobwebs fanned over 90° from `angle` at
##                an anchor (a corner or a furniture edge): radial threads,
##                sagging rings, a few hanging threads that sway very slightly
##                and the odd small spider on a thread; redrawn at the line
##                boil rate
##   corner_eyes  (x, y, pairs) small clusters of pale eyes in dark corners:
##                they blink now and then and their pupils follow the player
##                slowly. Not the Crawler: small, fixed in place, never red,
##                not tied to the noticed meter or any danger state. Each
##                cluster carries one tiny light so it shows faintly in the dark
##                (CanvasModulate), one small light per cluster; rooms list
##                one cluster each, because the panel background already
##                takes most of Compatibility's 8 lights per item. Webs carry
##                no light: candles, the moon and the torch find them.

const WEB: Color = Color(0.96, 0.96, 0.98, 0.85)
const EYE: Color = Color(0.92, 0.91, 0.84)
const PUPIL: Color = Color(0.08, 0.07, 0.1)

var _webs: Array[Vector4] = []
## Per eye: [centre, pupil offset, next blink time, blink left].
var _eyes: Array = []
var _t: float = 0.0
var _tick: int = -1


func setup(data: FrameData) -> void:
	_webs = data.webs
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(data.id)
	for cluster in data.corner_eyes:
		var c: Vector2 = Vector2(cluster.x, cluster.y)
		for i in int(cluster.z):
			var at: Vector2 = c + (Vector2(rng.randf_range(-22, 22), rng.randf_range(-12, 12)) if i > 0 else Vector2.ZERO)
			_eyes.append([at, Vector2.ZERO, rng.randf_range(2.0, 9.0), 0.0])
		var glow: PointLight2D = PointLight2D.new()
		glow.texture = LightTextures.radial()
		glow.texture_scale = (22.0 + cluster.z * 8.0) / LightTextures.RADIAL_RADIUS
		glow.position = c
		glow.color = EYE
		glow.energy = 1.6
		add_child(glow)
	z_index = 1


func _process(delta: float) -> void:
	_t += delta
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var target: Vector2 = to_local(player.global_position) + Vector2(0, -60) if player != null else Vector2(592, 300)
	for e in _eyes:
		var look: Vector2 = (target - (e[0] as Vector2)).normalized() * 1.6
		e[1] = (e[1] as Vector2).move_toward(look, delta * 1.2)
		e[3] = maxf(0.0, float(e[3]) - delta)
		if _t >= float(e[2]):
			e[3] = 0.18
			e[2] = _t + randf_range(5.0, 12.0)
	if not _eyes.is_empty() or InkDraw.boil_tick() != _tick:
		_tick = InkDraw.boil_tick()
		queue_redraw()


func _draw() -> void:
	for i in _webs.size():
		web(self, _webs[i], _t, _tick + i * 13, i % 2 == 0)
	for e in _eyes:
		var at: Vector2 = e[0]
		var open: float = 1.0 if float(e[3]) <= 0.0 else absf(float(e[3]) / 0.09 - 1.0)
		for dx in [-7.0, 7.0]:
			var p: Vector2 = at + Vector2(dx, 0)
			draw_colored_polygon(InkDraw.ellipse_points(p, Vector2(5.4, 3.2 * open + 0.3), 10), EYE)
			if open > 0.4:
				draw_circle(p + (e[1] as Vector2), 1.9, PUPIL)


## One cobweb. `w` = (x, y, size, angle°): fanned over 90° from `angle`.
static func web(ci: CanvasItem, w: Vector4, t: float, tick: int, spider: bool) -> void:
	var anchor: Vector2 = Vector2(w.x, w.y)
	var size: float = w.z
	var a0: float = deg_to_rad(w.w)
	var radials: int = 6
	var ends: PackedVector2Array = PackedVector2Array()
	for i in radials:
		var a: float = a0 + PI * 0.5 * i / (radials - 1)
		var length: float = size * (0.85 + 0.15 * sin(i * 2.3))
		ends.append(anchor + Vector2.from_angle(a) * length)
		InkDraw.line(ci, anchor, ends[i], 1.0, tick + i, WEB, 0.4)
	# Rings: each span between two radials sags toward the anchor.
	for ring in 5:
		var k: float = 0.22 + ring * 0.17
		for i in radials - 1:
			var p: Vector2 = anchor.lerp(ends[i], k)
			var q: Vector2 = anchor.lerp(ends[i + 1], k)
			var mid: Vector2 = p.lerp(q, 0.5).lerp(anchor, 0.08 + 0.03 * sin(t * 0.9 + ring + i))
			ci.draw_polyline(PackedVector2Array([p, mid, q]), WEB, 1.0, true)
	# Loose threads hanging from the outer ring, swaying slightly.
	for i in 2:
		var top: Vector2 = anchor.lerp(ends[1 + i * 3], 0.88)
		var length: float = size * (0.35 + 0.25 * i)
		var sway: float = sin(t * 1.1 + i * 1.7) * 3.0
		var bottom: Vector2 = top + Vector2(sway, length)
		ci.draw_line(top, bottom, Color(WEB, 0.45), 1.0, true)
		if spider and i == 0:
			var bob: Vector2 = bottom + Vector2(0, sin(t * 0.7) * 4.0)
			ci.draw_line(bottom, bob, Color(WEB, 0.45), 1.0, true)
			_spider(ci, bob, size * 0.05 + 3.0)


static func _spider(ci: CanvasItem, at: Vector2, r: float) -> void:
	for side in [-1.0, 1.0]:
		for leg in 4:
			var a: float = -0.9 + leg * 0.55
			var knee: Vector2 = at + Vector2(side * r * 1.4, -r * 0.6 + leg * r * 0.45)
			var foot: Vector2 = knee + Vector2(side * r * 0.9, r * (0.6 + leg * 0.15) + a)
			ci.draw_polyline(PackedVector2Array([at, knee, foot]), InkDraw.INK, 1.2, true)
	ci.draw_colored_polygon(InkDraw.ellipse_points(at + Vector2(0, r * 0.4), Vector2(r * 0.8, r), 10), InkDraw.INK)
	ci.draw_circle(at - Vector2(0, r * 0.6), r * 0.5, InkDraw.INK)
