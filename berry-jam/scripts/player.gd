class_name Player
extends CharacterBody2D

## Signals for modular communication
signal flashlight_toggled(is_enabled: bool)
signal ability_activated(ability_name: String)
signal interaction_triggered(interactable: Node2D)

## Movement configuration
@export_group("Movement")
@export var speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

## Flashlight configuration
@export_group("Flashlight")
@export var flashlight: PointLight2D
@export var flashlight_enabled: bool = true
@export var flashlight_smooth_speed: float = 14.0

## Ability state
@export_group("State")
@export var known_words: Array[String] = []

## Direction tracking
var facing_direction: Vector2 = Vector2.DOWN
var aim_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	# Automatically wire PointLight2D child if not explicitly assigned in inspector
	if not flashlight:
		flashlight = get_node_or_null("PointLight2D")

	if flashlight:
		flashlight.enabled = flashlight_enabled


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_flashlight_rotation(delta)


func _unhandled_input(event: InputEvent) -> void:
	# Toggle flashlight via F key, Right Mouse Button, or custom action
	if event.is_action_pressed("toggle_flashlight"):
		toggle_flashlight()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		toggle_flashlight()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		toggle_flashlight()

	# Interaction input (E key or custom action)
	if event.is_action_pressed("interact"):
		trigger_interaction()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		trigger_interaction()


## --- MOVEMENT SUBSYSTEM ---

func _handle_movement(delta: float) -> void:
	var input_vector: Vector2 = _get_movement_input()

	if input_vector != Vector2.ZERO:
		facing_direction = input_vector
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _get_movement_input() -> Vector2:
	var input_dir: Vector2 = Vector2.ZERO

	# Supports WASD directly as well as standard ui actions and custom actions
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		input_dir.y -= 1.0

	return input_dir.normalized()


## --- FLASHLIGHT SUBSYSTEM ---

func _update_flashlight_rotation(delta: float) -> void:
	if not flashlight or not is_instance_valid(flashlight):
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = mouse_pos - global_position

	if to_mouse.length_squared() > 1.0:
		aim_direction = to_mouse.normalized()
		var target_angle: float = to_mouse.angle()
		flashlight.rotation = lerp_angle(flashlight.rotation, target_angle, clampf(flashlight_smooth_speed * delta, 0.0, 1.0))


func toggle_flashlight() -> void:
	flashlight_enabled = !flashlight_enabled
	if flashlight and is_instance_valid(flashlight):
		flashlight.enabled = flashlight_enabled
	flashlight_toggled.emit(flashlight_enabled)


## --- INTERACTION HOOK ---

func trigger_interaction() -> void:
	# Future update: query RayCast2D or Area2D in aim_direction/facing_direction to steal speech bubbles
	interaction_triggered.emit(null)


## --- WORD ABILITIES HOOK (e.g., OPEN, HIDE) ---

func acquire_word(word: String) -> void:
	var clean_word: String = word.strip_edges().to_upper()
	if not known_words.has(clean_word):
		known_words.append(clean_word)


func use_word_ability(word: String) -> bool:
	var clean_word: String = word.strip_edges().to_upper()
	if not known_words.has(clean_word):
		return false

	ability_activated.emit(clean_word)
	match clean_word:
		"OPEN":
			return _execute_ability_open()
		"HIDE":
			return _execute_ability_hide()
		_:
			return false


func _execute_ability_open() -> bool:
	# Future update: unlock cursed panels, doors, or speech locks
	return true


func _execute_ability_hide() -> bool:
	# Future update: blend into comic margins/shadows to evade ink entities
	return true
