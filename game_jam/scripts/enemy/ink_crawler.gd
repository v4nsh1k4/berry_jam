class_name InkCrawler
extends Node2D
## The Ink Crawler. Light is its trigger: the flashlight raises the noticed
## meter and shows it where you are; darkness hides you; standing still in the
## dark is always safe; running is loud. It only catches while HUNTING or
## lunging, and every lunge is telegraphed (a freeze, a growl, eyes flare).
## This node is the brain; its CrawlerView child draws it in stop-motion.

enum State { DORMANT, PATROL, STALKING, HUNTING, TELEGRAPH, LUNGE, SEARCHING, RETREATING }

const WALK_SPEED: float = 150.0
const STALK_SPEED: float = 95.0
const SEARCH_SPEED: float = 110.0
const PATROL_SPEED: float = 70.0
const LUNGE_SPEED: float = 470.0
const LUNGE_TIME: float = 0.6
const TELEGRAPH_TIME: float = 0.6
const LUNGE_RANGE: float = 200.0
const LUNGE_COOLDOWN: float = 2.6
const SIGHT: float = 560.0
const HEARING: float = 430.0
const TOUCH: float = 70.0
const CATCH_RADIUS: float = 42.0
const LOSE_AFTER: float = 1.2
const SEARCH_TIME: float = 5.5
const STALK_AT_NOTICE: float = 0.35

## Panel-space rect it can move in (the room's floor band); set by Frame.
var walk_area: Rect2 = Rect2(40, 400, 1104, 104)
var patrol: bool = false
var patrol_span: Vector2 = Vector2.INF ## Patrolled panel-x range (INF = whole walk area).
# Tuning a bigger subclass (InkShadow) can change.
var speed_scale: float = 1.0
var catch_radius: float = CATCH_RADIUS
var lunge_range: float = LUNGE_RANGE
## Never sinks back: after searching it goes straight back to stalking.
var relentless: bool = false
var state: State = State.DORMANT
## 0 = puddle, 1 = standing. Read by the view.
var rise: float = 0.0
var facing: float = -1.0
## True on frames it actually moved (skitter sounds).
var moved: bool = false

var _pos: Vector2
var _last_known: Vector2
var _state_time: float = 0.0
var _lost_time: float = 0.0
var _blind: float = 0.0
## Scripted chases: it knows where you are for this long, light or not.
var _scent: float = 0.0
var _frozen: float = 0.0
var _lunge_cd: float = 0.0
var _lunge_dir: Vector2 = Vector2.RIGHT
var _patrol_dir: float = 1.0


func _ready() -> void:
	_pos = position
	_last_known = _pos
	add_child(_make_view())
	EventBus.notice_changed.connect(_on_notice_changed)
	EventBus.player_noticed.connect(_on_player_noticed)
	EventBus.player_lost.connect(_on_player_lost)
	EventBus.footstep.connect(_on_footstep)
	EventBus.crawler_hushed.connect(_on_hushed)
	add_to_group(&"crawler")
	add_to_group(&"freezable")
	if patrol:
		_set_state(State.PATROL)


## The look; InkShadow swaps in its own.
func _make_view() -> Node2D:
	return CrawlerView.new()


# --- Perception --------------------------------------------------------------

func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func is_hunting() -> bool:
	return state in [State.HUNTING, State.TELEGRAPH, State.LUNGE]


func is_frozen() -> bool:
	return _frozen > 0.0


func player_pos() -> Vector2:
	return _player_pos()


func _player_pos() -> Vector2:
	var p: Player = _player()
	return get_parent().to_local(p.global_position) if p != null else _pos


func _can_see() -> bool:
	var p: Player = _player()
	if p == null or _blind > 0.0 or p.is_concealed():
		return false
	var d: float = _pos.distance_to(_player_pos())
	return _scent > 0.0 or (LightingSystem.is_light_on and d < SIGHT) or (d < TOUCH and p.is_moving())


func _on_notice_changed(amount: float) -> void:
	if amount >= STALK_AT_NOTICE and _blind <= 0.0 and state in [State.DORMANT, State.PATROL, State.RETREATING]:
		_last_known = _player_pos()
		_set_state(State.STALKING)


func _on_player_noticed() -> void:
	if _blind > 0.0 or state in [State.TELEGRAPH, State.LUNGE]:
		return
	_last_known = _player_pos()
	_set_state(State.HUNTING if not _player().is_concealed() else State.SEARCHING)


func _on_player_lost() -> void:
	if state == State.HUNTING and not _can_see():
		_set_state(State.SEARCHING)


func _on_footstep(loud: bool) -> void:
	if not loud or _blind > 0.0 or _pos.distance_to(_player_pos()) > HEARING:
		return
	_last_known = _player_pos()
	if state in [State.DORMANT, State.PATROL, State.SEARCHING, State.RETREATING, State.STALKING]:
		_set_state(State.STALKING)


func _on_hushed(duration: float) -> void:
	_blind = duration
	_scent = 0.0
	if state != State.DORMANT and state != State.PATROL:
		_set_state(State.SEARCHING)


## For scripted moments: rise and go after the player right away, knowing
## where they are for `scent` seconds even in the dark.
func wake_to(hunting: bool, scent: float = 0.0) -> void:
	_scent = scent
	# It has to close in before its first lunge: no lunge straight off a rise.
	_lunge_cd = 2.0
	_last_known = _player_pos()
	_set_state(State.HUNTING if hunting else State.STALKING)


## WAIT word support: risen Crawlers can be frozen in place.
func can_freeze() -> bool:
	return state != State.DORMANT and _frozen <= 0.0


func freeze(duration: float) -> void:
	_frozen = duration


# --- Behaviour -------------------------------------------------------------

func _set_state(next: State) -> void:
	if next == state:
		return
	state = next
	_state_time = 0.0
	_lost_time = 0.0
	if next == State.TELEGRAPH:
		EventBus.crawler_telegraph.emit()
	EventBus.crawler_state_changed.emit(StringName(State.keys()[next]))


func _move_toward(target: Vector2, speed: float, delta: float) -> bool:
	var before: Vector2 = _pos
	_pos = _pos.move_toward(target, speed * speed_scale * delta)
	_pos = _pos.clamp(walk_area.position, walk_area.end)
	if absf(_pos.x - before.x) > 0.01:
		facing = signf(_pos.x - before.x)
	moved = moved or _pos != before
	return _pos.distance_to(target) < 6.0


func _physics_process(delta: float) -> void:
	moved = false
	if _frozen > 0.0:
		_frozen -= delta
		return
	_blind = maxf(0.0, _blind - delta)
	_scent = maxf(0.0, _scent - delta)
	_lunge_cd = maxf(0.0, _lunge_cd - delta)
	_state_time += delta
	var risen_target: float = 0.0 if state in [State.DORMANT, State.RETREATING] else 1.0
	rise = move_toward(rise, risen_target, delta * (1.6 if risen_target > 0.0 else 0.9))
	var up: bool = rise > 0.7
	match state:
		State.PATROL:
			if up:
				var span: Vector2 = patrol_span if patrol_span != Vector2.INF else Vector2(walk_area.position.x, walk_area.end.x)
				var end_x: float = span.y if _patrol_dir > 0.0 else span.x
				if _move_toward(Vector2(end_x, _pos.y), PATROL_SPEED, delta):
					_patrol_dir = -_patrol_dir
			if _can_see():
				_set_state(State.HUNTING)
		State.STALKING:
			if _can_see():
				_set_state(State.HUNTING)
			elif up and _move_toward(_last_known, STALK_SPEED, delta):
				_set_state(State.SEARCHING)
		State.HUNTING:
			if _can_see():
				_last_known = _player_pos()
				_lost_time = 0.0
				if _pos.distance_to(_last_known) < lunge_range and _lunge_cd <= 0.0:
					_set_state(State.TELEGRAPH)
			else:
				_lost_time += delta
				if _lost_time > LOSE_AFTER:
					_set_state(State.SEARCHING)
			if state == State.HUNTING and up:
				_move_toward(_last_known, WALK_SPEED, delta)
		State.TELEGRAPH:
			facing = signf(_player_pos().x - _pos.x) if _player_pos().x != _pos.x else facing
			if _state_time >= TELEGRAPH_TIME:
				_lunge_dir = (_player_pos() - _pos).normalized()
				_set_state(State.LUNGE)
		State.LUNGE:
			_move_toward(_pos + _lunge_dir * 100.0, LUNGE_SPEED, delta)
			if _state_time >= LUNGE_TIME:
				_lunge_cd = LUNGE_COOLDOWN
				_set_state(State.HUNTING if _can_see() else State.SEARCHING)
		State.SEARCHING:
			if _can_see():
				_set_state(State.HUNTING)
			elif up:
				# Go to where it last knew you were, then sweep around it.
				var sweep: Vector2 = _last_known + Vector2(sin(_state_time * 1.3) * 150.0, 0)
				_move_toward(sweep, SEARCH_SPEED, delta)
				if _state_time > SEARCH_TIME:
					_set_state(State.STALKING if relentless else State.RETREATING)
		State.RETREATING:
			if rise <= 0.0:
				_set_state(State.PATROL if patrol else State.DORMANT)
	position = _pos
	_check_catch()


func _check_catch() -> void:
	if not state in [State.HUNTING, State.LUNGE]:
		return
	var p: Player = _player()
	if p != null and not p.is_concealed() and _pos.distance_to(_player_pos()) < catch_radius:
		_set_state(State.RETREATING)
		EventBus.player_caught.emit()
