extends Node2D
## The awakening mirror (Stage 6): pressing E on it, a pale, translucent
## ghoul slithers a little way out of the glass, slumps, and sinks back. It
## is dejected, not a threat (no catching, no danger state, never blocks
## movement or input): faceless, sunken sockets, sagging shoulders, long
## dripping fingers. Greyscale only. The mirror's own caption says what it
## means ("...You are not written here."); a soft moan goes with it.
## The first look plays the full version, later looks a shorter one.

const MIRROR: Vector2 = Vector2(640, 214)
const MIRROR_RADII: Vector2 = Vector2(54, 84)
const FULL: float = 2.8
const SHORT: float = 1.4
const SEEN: StringName = &"mirror_ghoul"
const PALE: Color = Color(0.86, 0.87, 0.9)
const GREY: Color = Color(0.42, 0.43, 0.47)

var _t: float = -1.0
var _length: float = FULL
var _glow: PointLight2D


func _ready() -> void:
	z_index = 2
	_glow = PointLight2D.new()
	_glow.texture = LightTextures.radial()
	_glow.texture_scale = 340.0 / LightTextures.RADIAL_RADIUS
	_glow.position = MIRROR + Vector2(0, 90)
	_glow.color = PALE
	_glow.energy = 0.0
	add_child(_glow)
	EventBus.inspected.connect(_on_inspected)


func _on_inspected(id: StringName) -> void:
	if id != &"mirror" or _t >= 0.0:
		return
	var first: bool = not GameState.seen.has(SEEN)
	if first:
		GameState.seen.append(SEEN)
	_length = FULL if first else SHORT
	_t = 0.0
	AudioManager.play(&"moan", -15.0 if first else -18.0, 0.04)


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t >= _length:
		_t = -1.0
		_glow.energy = 0.0
	else:
		_glow.energy = 1.1 * _alpha(_t / _length)
	queue_redraw()


static func _alpha(k: float) -> float:
	return 0.72 * smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.82, 1.0, k))


func _draw() -> void:
	if _t < 0.0:
		return
	var k: float = _t / _length
	var a: float = _alpha(k)
	var out: float = smoothstep(0.0, 0.35, k) * (1.0 - smoothstep(0.62, 1.0, k))
	var slump: float = smoothstep(0.3, 0.62, k)
	draw_figure(self, MIRROR, out, slump, a, _t)


## The ghoul at `mirror` (the glass's centre): `out` 0..1 how far it has come
## out of the glass, `slump` 0..1 how far it has sagged, `a` its opacity.
static func draw_figure(ci: CanvasItem, mirror: Vector2, out: float, slump: float, a: float, t: float) -> void:
	var tick: int = InkDraw.boil_tick()
	# Ripples on the glass where it pushes through.
	for i in 3:
		var r: float = fposmod(t * 0.7 + i / 3.0, 1.0)
		ci.draw_arc(mirror, MIRROR_RADII.x * (0.3 + 0.7 * r), 0.0, TAU, 28, Color(PALE, a * 0.5 * (1.0 - r)), 1.5)
	var sc: float = 1.0 + 0.55 * out
	var head: Vector2 = mirror + Vector2(6 * out, -26 + 58 * out + 22 * slump) * sc
	var neck: Vector2 = head + Vector2(6 * slump, 34) * sc
	var drop: float = 18.0 + 26.0 * slump
	var shoulder_l: Vector2 = neck + Vector2(-44, drop) * sc
	var shoulder_r: Vector2 = neck + Vector2(44, drop) * sc
	var waist: float = 150.0 + 40.0 * out
	var body: PackedVector2Array = PackedVector2Array([neck + Vector2(-12, 0) * sc, shoulder_l, shoulder_l + Vector2(8, 60) * sc,
		mirror + Vector2(-30, waist), mirror + Vector2(30, waist), shoulder_r + Vector2(-8, 60) * sc, shoulder_r, neck + Vector2(12, 0) * sc])
	InkDraw.fill(ci, body, Color(PALE, a * 0.75))
	InkDraw.gap_ratio = 0.25
	InkDraw.polyline(ci, body, 2.0, tick, true, Color(GREY, a), 1.6)
	InkDraw.gap_ratio = 0.0
	# Arms hanging long from the sagging shoulders, fingers dripping.
	for side in [-1.0, 1.0]:
		var sh: Vector2 = shoulder_l if side < 0.0 else shoulder_r
		var hand: Vector2 = sh + Vector2(side * (10 - 6 * slump), 120 + 40 * slump + 30 * out) * sc
		InkDraw.line(ci, sh, hand, 7.0 * sc, tick + 1 + int(side), Color(PALE, a * 0.8), 1.4)
		for f in 4:
			var spread: float = (f - 1.5) * 5.0
			var tip: Vector2 = hand + Vector2(spread * sc, (46 + f % 2 * 14 + 16 * slump) * sc)
			InkDraw.line(ci, hand + Vector2(spread * 0.5, 0), tip, 2.0, tick + 4 + f, Color(GREY, a), 1.0)
			# Drops falling from each fingertip.
			var fall: float = fposmod(t * 1.3 + f * 0.27 + side * 0.4, 1.0)
			ci.draw_circle(tip + Vector2(0, fall * 70.0 * sc), 2.6 * sc * (1.0 - fall * 0.5), Color(GREY, a * (1.0 - fall)))
	# The head: long, faceless, two sunken hollows sliding down as it slumps.
	InkDraw.ellipse(ci, head, Vector2(24, 34) * sc, 2.0, tick + 12, Color(PALE, a * 0.85), Color(GREY, a))
	for side in [-1.0, 1.0]:
		var eye: Vector2 = head + Vector2(side * 9, -2 + 8 * slump) * sc
		ci.draw_colored_polygon(InkDraw.ellipse_points(eye, Vector2(5, 7 + 4 * slump) * sc, 10), Color(0.18, 0.18, 0.21, a * 0.85))
		InkDraw.line(ci, eye + Vector2(0, 7 + 4 * slump) * sc, eye + Vector2(side, 20 + 10 * slump) * sc, 1.2, tick + 14, Color(GREY, a * 0.6), 0.6)
	# Where a mouth would be: only a faint, slack smear.
	InkDraw.line(ci, head + Vector2(-5, 18 + 4 * slump) * sc, head + Vector2(5, 20 + 6 * slump) * sc, 1.5, tick + 16, Color(GREY, a * 0.4), 0.5)
