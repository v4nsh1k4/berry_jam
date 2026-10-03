class_name Player
extends CharacterBody2D
## The unperson. Side view: left/right walks, up/down moves within the floor
## band for depth, Shift runs (loud). Origin is at the feet. Drawn in red: the
## only coloured thing in the comic's world.

const RUN_SPEED: float = 340.0
const AURA_ENERGY: float = 0.42
const AURA_HIDDEN_ENERGY: float = 0.03

@export var speed: float = 230.0
@export var depth_speed: float = 140.0

var controls_enabled: bool = false
## Global-space rect the feet are clamped to; set by FrameManager.
var walk_area: Rect2 = Rect2()
var facing: float = 1.0
var running: bool = false

var _hiding: bool = false
var _hide_time: float = 0.0
var _concealed: bool = false
var _reaction: String = ""
var _reaction_time: float = 0.0
var _walk_phase: float = 0.0
var _moving: bool = false
var _tick: int = -1

@onready var flashlight: Flashlight = $Flashlight
@onready var _aura: PointLight2D = $Aura


func _ready() -> void:
	add_to_group(&"player")
	_aura.color = Color(1.0, 0.32, 0.32)
	EventBus.player_reaction.connect(_on_player_reaction)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.ability_failed.connect(_on_ability_failed)
	EventBus.hiding_spot_used.connect(_on_hiding_spot_used)
	EventBus.player_hide_requested.connect(_on_hide_requested)
	EventBus.frame_changed.connect(_on_frame_changed)


func _on_ability_used(bubble: BubbleData, _target_id: StringName) -> void:
	_on_player_reaction(bubble.text)


func _on_ability_failed(_bubble: BubbleData, _target_id: StringName) -> void:
	_on_player_reaction("?")


## Briefly fills the empty bubble: a spoken word, or "?" when nothing works.
func _on_player_reaction(text: String) -> void:
	_reaction = text
	_reaction_time = 1.3
	queue_redraw()


## Movement and interaction are allowed: in play, no menu or dial open.
func can_act() -> bool:
	return controls_enabled and GameState.is_playing and not GameState.modal_open


## True while the Crawler cannot find the player: in a hiding spot, or HIDE.
func is_concealed() -> bool:
	return _concealed


func is_moving() -> bool:
	return _moving


func _on_frame_changed(_data: FrameData) -> void:
	_hiding = false
	_hide_time = 0.0


## E at a hiding spot steps into it (snapping to it) or back out.
func _on_hiding_spot_used(_spot_id: StringName, screen_point: Vector2) -> void:
	_hiding = not _hiding
	if _hiding:
		global_position.x = (get_viewport().get_canvas_transform().affine_inverse() * screen_point).x
		LightingSystem.set_light(false)


func _on_hide_requested(duration: float) -> void:
	_hide_time = duration


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if can_act() and not _hiding:
		input = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	running = input.x != 0.0 and Input.is_action_pressed("sprint")
	velocity = Vector2(input.x * (RUN_SPEED if running else speed), input.y * depth_speed)
	move_and_slide()
	if walk_area.has_area():
		global_position = global_position.clamp(walk_area.position, walk_area.end)

	_moving = input != Vector2.ZERO
	if _moving:
		var step_before: int = int(_walk_phase / PI)
		_walk_phase += delta * (15.0 if running else 11.0)
		if int(_walk_phase / PI) != step_before:
			EventBus.footstep.emit(running)
	if input.x != 0.0:
		facing = signf(input.x)
	elif LightingSystem.is_light_on:
		var to_mouse: float = get_global_mouse_position().x - global_position.x
		if absf(to_mouse) > 8.0:
			facing = signf(to_mouse)
	flashlight.position = Vector2(18.0 * facing, -60.0)


func _process(delta: float) -> void:
	if _reaction_time > 0.0:
		_reaction_time -= delta
		if _reaction_time <= 0.0:
			_reaction = ""
	_hide_time = maxf(0.0, _hide_time - delta)
	var concealed: bool = _hiding or _hide_time > 0.0
	if concealed != _concealed:
		_concealed = concealed
		EventBus.player_concealed_changed.emit(concealed)
	var target: float = AURA_HIDDEN_ENERGY if concealed else AURA_ENERGY
	_aura.energy = move_toward(_aura.energy, target, delta * 2.0)
	modulate.a = move_toward(modulate.a, 0.35 if _hiding else (0.6 if concealed else 1.0), delta * 3.0)
	var tick: int = InkDraw.boil_tick()
	if tick != _tick or _moving:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	var f: float = facing
	var s: int = _tick * 13
	var red: Color = InkDraw.RED
	var swing: float = sin(_walk_phase) * (14.0 if running else 11.0) if _moving else 0.0
	var bob: float = absf(sin(_walk_phase)) * -2.0 if _moving else 0.0
	var hip: Vector2 = Vector2(0, -42 + bob)

	# Legs.
	InkDraw.polyline(self, PackedVector2Array([hip, Vector2(-4 + swing, -20), Vector2(-6 + swing, 0), Vector2(-6 + swing + 9 * f, 0)]), 4.0, s + 1, false, red)
	InkDraw.polyline(self, PackedVector2Array([hip, Vector2(4 - swing, -20), Vector2(6 - swing, 0), Vector2(6 - swing + 9 * f, 0)]), 4.0, s + 2, false, red)

	# Back arm, torso, front arm (holding the torch once found).
	var shoulder: Vector2 = Vector2(0, -78 + bob)
	InkDraw.line(self, shoulder, Vector2(-8 * f - swing * 0.6, -50 + bob), 3.5, s + 3, red)
	var torso: PackedVector2Array = PackedVector2Array([
		Vector2(-11, -82 + bob), Vector2(11, -82 + bob), Vector2(9, -40 + bob), Vector2(-9, -40 + bob)])
	InkDraw.shape(self, torso, 3.0, s + 4, red, red)
	var hand: Vector2 = Vector2(16 * f, -60)
	InkDraw.polyline(self, PackedVector2Array([shoulder, Vector2(8 * f, -66 + bob), hand]), 3.5, s + 5, false, red)
	if LightingSystem.has_flashlight():
		InkDraw.rect(self, Rect2(hand + Vector2(-5, -4), Vector2(12, 8)), 2.0, s + 6, InkDraw.INK)

	# Faceless head: blank paper, red ink edge.
	InkDraw.ellipse(self, Vector2(2 * f, -96 + bob), Vector2(12, 13), 3.0, s + 7, InkDraw.PAPER, red)

	# Empty speech bubble: the unperson has no words of their own. Bubbles
	# stay black and white like every other bubble in the comic.
	var bubble_center: Vector2 = Vector2(26 * f, -142 + bob)
	if _reaction != "":
		BubbleArt.draw(self, bubble_center + Vector2(10 * f, -6), _reaction, Vector2(8 * f, -114 + bob), s + 8)
		return
	InkDraw.ellipse(self, bubble_center, Vector2(30, 17), 2.5, s + 8, InkDraw.WHITE)
	var tail: PackedVector2Array = PackedVector2Array([
		bubble_center + Vector2(-12 * f, 10), bubble_center + Vector2(-2 * f, 12), Vector2(8 * f, -114 + bob)])
	draw_colored_polygon(tail, InkDraw.WHITE)
	InkDraw.line(self, tail[0], tail[2], 2.5, s + 9)
	InkDraw.line(self, tail[1], tail[2], 2.5, s + 10)
