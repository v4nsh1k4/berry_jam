class_name SpreadFingers
extends Node2D
## The gutter hazard on a spread page: keep the torch on too long and ink
## fingers poke up through the gutter under the player, after a fair 0.8 s
## telegraph (they peek and a growl sounds). A hit knocks the player back to
## the panel's entry; never a death. Torch off and the meter drains.

const FILL_TIME: float = 4.0
const TELEGRAPH: float = 0.8
const STAB_TIME: float = 0.35
const REACH: float = 75.0

var controller: SpreadController
var enabled: bool = true
var meter: float = 0.0

var _phase: int = 0
var _t: float = 0.0
var _x: float = 0.0
var _base_y: float = 0.0


func _process(delta: float) -> void:
	if not enabled or controller.current == null:
		return
	if _phase == 0:
		var lit: bool = LightingSystem.is_light_on and GameState.is_playing and not GameState.modal_open
		meter = clampf(meter + (delta / FILL_TIME if lit else -delta * 0.4), 0.0, 1.0)
		if meter >= 1.0:
			_start()
		return
	_t += delta
	queue_redraw()
	if _phase == 1 and _t >= TELEGRAPH:
		_phase = 2
		_t = 0.0
		_hit_check()
	elif _phase == 2 and _t >= STAB_TIME:
		_phase = 0
		meter = 0.3
		queue_redraw()


func _start() -> void:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	_phase = 1
	_t = 0.0
	_x = to_local(player.global_position).x
	_base_y = controller.current.rect.end.y + 8.0
	EventBus.crawler_telegraph.emit()


func _hit_check() -> void:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	EventBus.shake_requested.emit(0.2)
	AudioManager.play(&"nib", -3.0, 0.1)
	if player == null or controller.hopping:
		return
	var p: Vector2 = to_local(player.global_position)
	if absf(p.x - _x) < REACH and controller.current.rect.has_point(p + Vector2(0, -4)) and not controller.airborne:
		controller.knock_back("The fingers in the gutter hate the light.")


func _draw() -> void:
	if _phase == 0:
		return
	var reach: float = (_t / TELEGRAPH) * 50.0 if _phase == 1 else 50.0 + 100.0 * sin(clampf(_t / STAB_TIME, 0.0, 1.0) * PI)
	for i in 3:
		var base: Vector2 = Vector2(_x + (i - 1) * 22.0, _base_y)
		CrawlerArt.finger(self, base, -PI * 0.5 + (i - 1) * 0.15, reach, 3, InkDraw.boil_tick() + i, 9.0, 0.2)
