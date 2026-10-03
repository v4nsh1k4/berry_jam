class_name HeartShadow
extends InkShadow
## The Ink Shadow in its lair (the Ink Heart), holding the last word out on
## its fingers. It paces its corner of the floor, beside the word, and every
## few seconds LISTENS: first a warning (it stops, its eyes open wide and
## white, a growl), then for a moment any movement in earshot sends it
## hunting. Standing still or hiding is always safe; HUSH deafens it, WAIT
## freezes it; light wakes it like any Crawler. Once it hunts it leaves its
## lair; when it loses the player it sinks and goes back. Caught = the room
## reloads, words kept. Stealing the word ends all of this: the reveal plays.

const LISTEN_EVERY: float = 4.5
## Warning before it listens (at least the 0.6 s every danger gets).
const LISTEN_WARNING: float = 0.9
const LISTEN_TIME: float = 1.8
const LISTEN_RANGE: float = 700.0
## Its lair: the stretch of floor it paces (panel x), just right of the word.
const LAIR: Vector2 = Vector2(960.0, 1110.0)
const SPEED_SCALE: float = 0.6
## Once it has heard you it comes fast.
const HUNT_SPEED_SCALE: float = 0.9

enum Ear { IDLE, WARNING, LISTENING }

## 0..1 how hard it is listening (the view opens its eyes with it).
var listening: float = 0.0

var _ear: Ear = Ear.IDLE
var _ear_time: float = LISTEN_EVERY
var _warned: bool = false
var _done: bool = false


func _init() -> void:
	draws_wall = false
	speed_scale = SPEED_SCALE
	relentless = false
	patrol_span = LAIR


func _ready() -> void:
	super._ready()
	EventBus.reveal_started.connect(_on_reveal_started)


## It only scribbles out hiding places once it is after someone.
func _erases() -> bool:
	return state in [State.STALKING, State.HUNTING, State.SEARCHING]


func _on_reveal_started() -> void:
	_done = true
	listening = 0.0
	freeze(3600.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _done:
		return
	var calm: bool = state in [State.PATROL, State.DORMANT]
	if is_frozen() or _blind > 0.0 or not calm:
		_set_ear(Ear.IDLE, LISTEN_EVERY)
	else:
		_ear_time -= delta
		match _ear:
			Ear.IDLE:
				if _ear_time <= 0.0:
					_set_ear(Ear.WARNING, LISTEN_WARNING)
					EventBus.crawler_telegraph.emit()
					if not _warned:
						_warned = true
						EventBus.caption_requested.emit("It's listening. Don't move.", 2.5)
			Ear.WARNING:
				if _ear_time <= 0.0:
					_set_ear(Ear.LISTENING, LISTEN_TIME)
			Ear.LISTENING:
				if _hears_player():
					_set_ear(Ear.IDLE, LISTEN_EVERY)
					wake_to(true, 4.0)
				elif _ear_time <= 0.0:
					_set_ear(Ear.IDLE, LISTEN_EVERY)
	var target: float = 1.0 if _ear != Ear.IDLE else 0.0
	listening = move_toward(listening, target, delta * 4.0)
	if _ear == Ear.IDLE:
		speed_scale = SPEED_SCALE if calm else HUNT_SPEED_SCALE


func _set_ear(next: Ear, time: float) -> void:
	if next == _ear and next == Ear.IDLE:
		return
	_ear = next
	_ear_time = time
	# It holds still while it listens.
	speed_scale = 0.0 if next != Ear.IDLE else SPEED_SCALE


func _hears_player() -> bool:
	var p: Player = _player()
	return p != null and p.is_moving() and not p.is_concealed() and _pos.distance_to(_player_pos()) < LISTEN_RANGE
