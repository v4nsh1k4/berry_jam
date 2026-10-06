extends Node2D
## A huge shadow of a hand holding a pen sweeps across the panel once, then
## is gone. Nothing explains it.
## (It is the Comic Artist's hand; the Chapter 3 reveal shows it plainly.)

const FLAG: StringName = &"seen_ink_hand"
## Fires when the player passes this share of the panel width.
const TRIGGER_AT: float = 0.4
const DURATION: float = 2.4
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.8)

var _playing: bool = false
var _t: float = 0.0


func _ready() -> void:
	z_index = 20
	if GameState.has_flag(FLAG):
		queue_free()


func _process(delta: float) -> void:
	if not _playing:
		var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and to_local(player.global_position).x > Frame.PANEL_RECT.size.x * TRIGGER_AT:
			_playing = true
			GameState.set_flag(FLAG)
			EventBus.shake_requested.emit(0.35)
		return
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		queue_free()


func _draw() -> void:
	if not _playing:
		return
	var p: float = smoothstep(0.0, 1.0, _t / DURATION)
	var center: Vector2 = Vector2(1650, -320).lerp(Vector2(-520, 260), p)
	draw_set_transform(center, lerpf(-0.5, 0.25, p), Vector2(2.6, 2.6))
	# Palm, four long fingers reaching left, a thumb, and the pen.
	draw_colored_polygon(InkDraw.ellipse_points(Vector2.ZERO, Vector2(78, 92), 24), SHADOW)
	for i in 4:
		var y: float = -54.0 + i * 34.0
		draw_colored_polygon(_capsule(Vector2(-40, y), Vector2(-175 + absf(i - 1.5) * 22.0, y + 8.0), 15.0), SHADOW)
	draw_colored_polygon(_capsule(Vector2(-10, 70), Vector2(-96, 120), 17.0), SHADOW)
	draw_colored_polygon(_capsule(Vector2(-230, 150), Vector2(70, -10), 7.0), SHADOW)
	draw_colored_polygon(PackedVector2Array([Vector2(-230, 143), Vector2(-262, 168), Vector2(-226, 158)]), SHADOW)


func _capsule(a: Vector2, b: Vector2, radius: float) -> PackedVector2Array:
	var dir: Vector2 = (b - a).normalized()
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 9:
		pts.append(b + dir.rotated(-PI * 0.5 + PI * i / 8.0) * radius)
	for i in 9:
		pts.append(a + (-dir).rotated(-PI * 0.5 + PI * i / 8.0) * radius)
	return pts
