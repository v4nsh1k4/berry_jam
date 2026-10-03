class_name ArtistHand
extends Node2D
## The Artist's hand in the return phase (a frame lists it as the
## "artist_hand" event). It hovers at the top of the panel holding its eraser
## and tries to rub the player out:
##   HOVER -> AIM (the eraser's shadow darkens a strip of floor, a growl: the
##   warning, never under 0.6 s) -> RUB (the only moment it can catch; anyone
##   in the strip and not hidden is rubbed out and the room reloads, words and
##   returns kept) -> LIFT -> HOVER.
## Every word given back weakens it (rarer, slower, narrower; tuned in
## data/hand/hand_pressure.tres). Once the last ordinary word is home it only
## WATCHES. In the Ink Heart it takes the last word back: OFFER (eraser down,
## grip open), then WITHDRAW as the comic repairs.
## HUSH stops its attempts for a while, WAIT freezes it, hiding is always safe.

enum State { HOVER, AIM, RUB, LIFT, WATCH, OFFER, WITHDRAW }

const PRESSURE: HandPressureData = preload("res://data/hand/hand_pressure.tres")
const SIZE: float = 300.0
## Wrist height while hovering (panel y; the arm runs off the top).
const HOVER_Y: float = -30.0
## The floor band the eraser rubs (panel y).
const FLOOR: Vector2 = Vector2(398.0, 506.0)
const LIFT_TIME: float = 0.6
## How near the player must come, with ERASE selected, for it to open its grip.
const OFFER_REACH: float = 320.0
const FINAL_WORD_X: float = 860.0

var state: State = State.HOVER

var _wrist: Vector2 = Vector2(700.0, HOVER_Y)
var _timer: float = PRESSURE.first_delay
## Length of the current AIM / RUB / LIFT, for the warning's progress.
var _phase_len: float = 1.0
var _target_x: float = 0.0
var _width: float = 0.0
var _held: float = 1.0
var _blind: float = 0.0
var _frozen: float = 0.0
var _grip: float = 0.0
var _caught: bool = false
var _smudges: Array[Vector2] = []
var _glow: PointLight2D
var _near_timer: float = 0.0
var _tick: int = -1


func _ready() -> void:
	z_index = 4
	add_to_group(&"freezable")
	_glow = PointLight2D.new()
	_glow.texture = LightTextures.radial()
	_glow.color = HandArt.PALE
	_glow.energy = 0.0
	add_child(_glow)
	EventBus.bubble_returned.connect(_on_bubble_returned)
	EventBus.crawler_hushed.connect(func(duration: float) -> void: _blind = duration)
	_held = GameState.held_share()
	var p: Node2D = _player()
	if p != null:
		_wrist.x = to_local(p.global_position).x + 300.0
	if GameState.normal_words_held() == 0:
		state = State.WATCH
	if GameState.has_flag(&"comic_repaired"):
		state = State.WITHDRAW
		_wrist.y = -700.0


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## WAIT word support.
func can_freeze() -> bool:
	return state in [State.HOVER, State.AIM, State.RUB, State.LIFT] and _frozen <= 0.0


func freeze(duration: float) -> void:
	_frozen = duration


func _on_bubble_returned(bubble: BubbleData, _pos: Vector2) -> void:
	_held = GameState.held_share()
	if bubble.story_final:
		state = State.WITHDRAW
		_timer = 0.0
		EventBus.caption_requested.emit("It takes the word back. And lets go of the page.", 4.0)
	elif GameState.normal_words_held() == 0 and state != State.WATCH:
		state = State.WATCH
		EventBus.caption_requested.emit("The hand stops. It only watches now.", 3.5)


func _physics_process(delta: float) -> void:
	_blind = maxf(0.0, _blind - delta)
	if _frozen > 0.0:
		_frozen -= delta
		return
	var p: Player = _player()
	if p == null:
		return
	var px: float = to_local(p.global_position).x
	var tip: Vector2 = HandArt.tool_tip(SIZE, &"eraser")
	_timer -= delta
	match state:
		State.HOVER:
			_drift(px - tip.x, HOVER_Y, PRESSURE.speed(_held), delta)
			if _blind > 0.0:
				_timer = maxf(_timer, 0.5)
			elif _timer <= 0.0 and p.can_act() and not p.is_concealed() and not TransitionManager.is_playing:
				_aim(px)
		State.AIM:
			_drift(_target_x - tip.x, HOVER_Y + 70.0, 600.0, delta)
			if _blind > 0.0:
				_set_state(State.LIFT, LIFT_TIME)
			elif _timer <= 0.0:
				_set_state(State.RUB, PRESSURE.rub_time)
				EventBus.hand_erase.emit(get_global_transform_with_canvas() * Vector2(_target_x, FLOOR.y))
				EventBus.shake_requested.emit(0.3)
		State.RUB:
			var sweep: float = sin(_timer * 26.0) * _width * 0.3
			_drift(_target_x + sweep - tip.x, FLOOR.x + 40.0 - tip.y, 2400.0, delta)
			_check_catch(p, px)
			if _timer <= 0.0:
				_smudges.append(Vector2(_target_x, 1.0))
				_set_state(State.LIFT, LIFT_TIME)
		State.LIFT:
			_drift(_wrist.x, HOVER_Y, 500.0, delta)
			if _timer <= 0.0:
				_set_state(State.HOVER, PRESSURE.interval(_held))
		State.WATCH:
			_drift(px - tip.x * 0.5, HOVER_Y - 20.0, PRESSURE.speed_weak * 0.5, delta)
			if _wants_offer(p, px):
				state = State.OFFER
		State.OFFER:
			_drift(FINAL_WORD_X + 50.0, 0.0, 200.0, delta)
			if not _wants_offer(p, px):
				state = State.WATCH
		State.WITHDRAW:
			_drift(_wrist.x + 120.0, -700.0, 260.0, delta)
	_grip = move_toward(_grip, 1.0 if state == State.OFFER else 0.0, delta * 1.5)
	_update_glow()
	_report_nearness(p, delta)


func _aim(px: float) -> void:
	_target_x = px
	_width = PRESSURE.width(_held)
	_caught = false
	_set_state(State.AIM, PRESSURE.telegraph(_held))
	EventBus.crawler_telegraph.emit()


func _set_state(next: State, time: float) -> void:
	state = next
	_timer = time
	_phase_len = maxf(time, 0.01)


func _drift(x: float, y: float, speed: float, delta: float) -> void:
	_wrist = _wrist.move_toward(Vector2(x, y), speed * delta)


## Rubbed out: only while the eraser is down, only inside the strip, never
## while hidden.
func _check_catch(p: Player, px: float) -> void:
	if _caught or p.is_concealed() or absf(px - _target_x) > _width * 0.5:
		return
	_caught = true
	EventBus.player_caught.emit()


## In the Ink Heart, the player comes near with the last word selected.
func _wants_offer(p: Player, px: float) -> bool:
	var word: BubbleData = GameState.selected_bubble()
	return word != null and word.story_final and GameState.normal_words_held() == 0 \
		and absf(px - FINAL_WORD_X) < OFFER_REACH and p.can_act()


## A pale pool of light on the strip so the warning reads in a dark room.
func _update_glow() -> void:
	var aiming: bool = state == State.AIM or state == State.RUB
	_glow.position = Vector2(_target_x, FLOOR.x + 40.0)
	_glow.texture_scale = maxf(_width, 120.0) / LightTextures.RADIAL_RADIUS * 0.8
	_glow.energy = move_toward(_glow.energy, 0.9 if aiming else 0.0, 0.08)


## Heartbeat, rumble and the red edge, in step with the real danger: a low
## hum while it hovers, rising as the eraser comes down on the player's strip.
func _report_nearness(p: Player, delta: float) -> void:
	_near_timer -= delta
	if _near_timer > 0.0:
		return
	_near_timer = 0.125
	var in_strip: bool = absf(to_local(p.global_position).x - _target_x) <= _width * 0.5 and not p.is_concealed()
	var progress: float = 1.0 - clampf(_timer / _phase_len, 0.0, 1.0)
	var near: float = 0.0
	match state:
		State.HOVER, State.LIFT:
			near = 0.12 + 0.12 * _held
		State.AIM:
			near = 0.3 + 0.4 * progress if in_strip else 0.2
		State.RUB:
			near = 0.75 if in_strip else 0.25
	EventBus.crawler_proximity.emit(near, state == State.RUB)


func _process(delta: float) -> void:
	for i in range(_smudges.size() - 1, -1, -1):
		var smudge: Vector2 = _smudges[i]
		smudge.y -= delta * 0.12
		_smudges[i] = smudge
		if smudge.y <= 0.0:
			_smudges.remove_at(i)
	var tick: int = InkDraw.boil_tick()
	if tick != _tick or state != State.WATCH:
		_tick = tick
		queue_redraw()


func _exit_tree() -> void:
	EventBus.crawler_proximity.emit(0.0, false)


func _draw() -> void:
	var progress: float = 1.0 - clampf(_timer / _phase_len, 0.0, 1.0)
	HandFloorArt.draw(self, state == State.AIM, state == State.RUB, _target_x, _width, FLOOR, progress, _smudges, _tick)
	var tool: StringName = &"eraser" if _grip < 0.5 else &"none"
	if _grip >= 0.5:
		# The eraser set down on the floor beside the word.
		HandArt.eraser(self, Vector2(FINAL_WORD_X - 260.0, FLOOR.y - 30.0), SIZE * 0.8, 1.0, _tick)
	HandArt.draw(self, _wrist, SIZE, _tick * 7, _grip, tool)
