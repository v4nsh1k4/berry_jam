extends Node2D
## The bedchamber wardrobe (Stage 6b, scare_closet): a few seconds after the
## player comes in (time to look round), it settles open a crack with a faint
## creak (the fair warning). Once that has sat a moment, walking near it sets
## `closet_near`; JumpscareOverlay fires the scare when it is fair (the doors
## burst open on a face), and afterwards the doors swing calmly shut.
## Once per run (GameState.seen). No Crawler, no catching.

const WARDROBE: Rect2 = Rect2(860, 110, 150, 280)
const LOOK_TIME: float = 4.0
const ARMED_AFTER: float = 2.5
const NEAR: float = 190.0

var _t: float = 0.0
var _cracked_at: float = -1.0
var _burst: float = -1.0
var _tick: int = -1


func _ready() -> void:
	z_index = 1
	EventBus.scare.connect(func(kind: StringName, _i: float) -> void:
		if kind == &"scare_closet":
			_burst = 0.0)
	if GameState.seen.has(&"scare_closet"):
		set_process(false)


func _process(delta: float) -> void:
	_t += delta
	if _burst >= 0.0:
		_burst += delta
		if _burst > 2.6:
			_burst = -1.0
			_cracked_at = -1.0
			AudioManager.play_door_creak(-16.0)
			set_process(false)
		queue_redraw()
		return
	if _cracked_at < 0.0 and _t >= LOOK_TIME and GameState.is_playing and not GameState.modal_open:
		_cracked_at = _t
		AudioManager.play_door_creak(-20.0)
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if _cracked_at >= 0.0 and _t - _cracked_at > ARMED_AFTER and player != null \
			and absf(to_local(player.global_position).x - WARDROBE.get_center().x) < NEAR:
		GameState.set_flag(&"closet_near")
	if InkDraw.boil_tick() != _tick or _cracked_at >= 0.0 and _t - _cracked_at < 1.0:
		_tick = InkDraw.boil_tick()
		queue_redraw()


func _draw() -> void:
	var mid: float = WARDROBE.get_center().x
	if _burst >= 0.0:
		# Flung wide, then easing shut again.
		var open: float = 1.0 - smoothstep(0.7, 2.5, _burst)
		draw_rect(Rect2(WARDROBE.position + Vector2(6, 6), WARDROBE.size - Vector2(12, 12)), Color(0.02, 0.02, 0.03))
		for side in [-1.0, 1.0]:
			var hinge: float = WARDROBE.position.x if side < 0.0 else WARDROBE.end.x
			var edge: float = lerpf(mid, hinge + side * 40.0, open)
			InkDraw.shape(self, PackedVector2Array([Vector2(hinge, WARDROBE.position.y), Vector2(edge, WARDROBE.position.y - 14.0 * open),
				Vector2(edge, WARDROBE.end.y + 14.0 * open), Vector2(hinge, WARDROBE.end.y)]), 3.0, _tick + int(side), Color(0.42, 0.33, 0.25))
		return
	if _cracked_at < 0.0:
		return
	# The crack: a dark gap between the doors, settling a little wider.
	var k: float = smoothstep(0.0, 0.9, _t - _cracked_at)
	var gap: float = 3.0 + 9.0 * k
	draw_rect(Rect2(mid - gap * 0.5, WARDROBE.position.y + 8, gap, WARDROBE.size.y - 16), Color(0.01, 0.01, 0.02))
	InkDraw.line(self, Vector2(mid + gap * 0.5, WARDROBE.position.y + 6), Vector2(mid + gap * 0.5 + 2.0, WARDROBE.end.y - 6), 2.0, _tick)
