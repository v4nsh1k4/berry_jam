class_name Pendulum
extends Node2D
## The grandfather clock's pendulum. A WAIT target: it can be frozen mid-swing.

var _t: float = 0.0
var _frozen: float = 0.0


func _ready() -> void:
	add_to_group(&"freezable")


func can_freeze() -> bool:
	return _frozen <= 0.0


func freeze(duration: float) -> void:
	_frozen = duration


func _process(delta: float) -> void:
	if _frozen > 0.0:
		_frozen -= delta
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var angle: float = sin(_t * 2.6) * 0.32
	var bob: Vector2 = Vector2(sin(angle), cos(angle)) * 110.0
	InkDraw.line(self, Vector2.ZERO, bob, 3.0, int(_t * 7.0))
	InkDraw.ellipse(self, bob, Vector2(16, 16), 3.0, int(_t * 7.0) + 1, Color(0.78, 0.75, 0.68))
