class_name ExitZone
extends Area2D
## Walk-in area that reports an ExitData through EventBus. Draws a small
## ink arrow on the floor, which only shows up under the flashlight.

var exit_data: ExitData

## Seconds to wait after a locked exit opens while the player stands in it,
## so they see the door open before the page turns.
const UNLOCK_GRACE: float = 1.5

var _player: Player
var _unlocked_last: bool = true
var _grace_left: float = 0.0
var _player_inside: bool = false
var _sent: bool = false
## Seconds before the "it won't open" caption may show again.
var _locked_note: float = 0.0
var _tick: int = -1


func setup(data: ExitData) -> void:
	exit_data = data
	position = data.area.get_center()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = data.area.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_unlocked_last = _is_unlocked()


func _is_unlocked() -> bool:
	return exit_data.required_flag == &"" or GameState.has_flag(exit_data.required_flag)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body as Player
		_player_inside = true
		if not _is_unlocked() and _locked_note <= 0.0:
			_locked_note = 6.0
			EventBus.caption_requested.emit("The way on is shut. Not yet.", 1.8)
		_try_leave()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
		_sent = false
		_grace_left = 0.0


## Also fires when a locked exit opens while the player is already standing
## in it (e.g. right after saying OPEN at the door).
func _physics_process(delta: float) -> void:
	# Opened while the player stands here: let them watch it open first.
	var unlocked: bool = _is_unlocked()
	if unlocked and not _unlocked_last and _player_inside:
		_grace_left = UNLOCK_GRACE
	_unlocked_last = unlocked
	_locked_note = maxf(0.0, _locked_note - delta)
	if _grace_left > 0.0:
		_grace_left -= delta
		return
	if _player_inside and not _sent:
		_try_leave()


func _try_leave() -> void:
	if not _is_unlocked() or _grace_left > 0.0:
		return
	if _player != null and not _player.can_act():
		return
	_sent = true
	EventBus.exit_entered.emit(exit_data)


func _process(_delta: float) -> void:
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	if exit_data == null:
		return
	var dir: float = 1.0 if exit_data.area.get_center().x > Frame.PANEL_RECT.size.x * 0.5 else -1.0
	var tip: Vector2 = Vector2(18.0 * dir, 30.0)
	var tail: Vector2 = Vector2(-18.0 * dir, 30.0)
	InkDraw.line(self, tail, tip, 3.0, _tick * 3)
	InkDraw.polyline(self, PackedVector2Array([tip + Vector2(-9.0 * dir, -8), tip, tip + Vector2(-9.0 * dir, 8)]), 3.0, _tick * 3 + 1)
