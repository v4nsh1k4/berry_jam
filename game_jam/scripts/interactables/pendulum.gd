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


## 1 while frozen; otherwise high only as the bob passes the middle of its
## swing (the clock face holds still then).
func steadiness() -> float:
	if _frozen > 0.0:
		return 1.0
	return clampf(1.0 - absf(_angle()) / 0.22, 0.0, 1.0)


func is_frozen() -> bool:
	return _frozen > 0.0


func _angle() -> float:
	return sin(_t * 2.6) * 0.32


func _process(delta: float) -> void:
	if _frozen > 0.0:
		_frozen -= delta
		queue_redraw()
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var angle: float = _angle()
	var bob: Vector2 = Vector2(sin(angle), cos(angle)) * 110.0
	InkDraw.line(self, Vector2.ZERO, bob, 3.0, int(_t * 7.0))
	InkDraw.ellipse(self, bob, Vector2(16, 16), 3.0, int(_t * 7.0) + 1, Color(0.78, 0.75, 0.68))
	if _frozen > 0.0:
		FrostArt.draw(self, bob, 24.0, InkDraw.boil_tick(), minf(_frozen, 1.0))
