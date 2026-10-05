class_name SpreadJump
extends Node
## Jumping on a spread page (SpreadController owns one). A jump is a hop of
## the drawing (Player.lift); while airborne the feet ignore floor tears. It
## is forgiving: a press up to BUFFER s before landing still jumps, and feet
## that step onto a tear get COYOTE s to jump before they drop. Space jumps;
## W / Up do too on these pages (the floor band is too thin to need depth).

const TIME: float = 0.7
const HEIGHT: float = 90.0
const BUFFER: float = 0.12
const COYOTE: float = 0.12

var airborne: bool = false
var _buffer: float = 0.0
var _coyote: float = -1.0
var _player: Player


func setup(player: Player) -> void:
	_player = player


## Call every physics frame with whether jumping is allowed right now.
func update(delta: float, can_act: bool) -> void:
	_buffer = maxf(0.0, _buffer - delta)
	if can_act and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up")):
		_buffer = BUFFER


## True once per buffered press (consumes it).
func take_press() -> bool:
	if _buffer <= 0.0:
		return false
	_buffer = 0.0
	return true


func pressed_recently() -> bool:
	return _buffer > 0.0


## Feet are over an unbridged tear this frame: true once the grace runs out.
func over_tear(delta: float) -> bool:
	if _coyote < 0.0:
		_coyote = COYOTE
	_coyote -= delta
	return _coyote <= 0.0


func on_solid_floor() -> void:
	_coyote = -1.0


func jump() -> void:
	if airborne or _player == null:
		return
	airborne = true
	_coyote = -1.0
	AudioManager.play(&"step", -4.0, 0.1)
	var tween: Tween = create_tween()
	tween.tween_method(func(k: float) -> void: _player.lift = sin(k * PI) * HEIGHT, 0.0, 1.0, TIME)
	await tween.finished
	if is_instance_valid(_player):
		_player.lift = 0.0
	airborne = false


func cancel() -> void:
	airborne = false
	_buffer = 0.0
	_coyote = -1.0
	if is_instance_valid(_player):
		_player.lift = 0.0
