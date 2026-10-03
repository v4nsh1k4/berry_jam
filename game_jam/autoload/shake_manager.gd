extends Node
## Trauma-based screen shake. Anything can add trauma (EventBus.shake_requested
## or add_trauma); shake strength is trauma squared and decays over time. It
## moves the world canvas; layers with follow_viewport (the page) move too.

const MAX_OFFSET: float = 16.0
const MAX_ROTATION: float = 0.01
const DECAY: float = 1.7

var trauma: float = 0.0

var _shaking: bool = false


func _ready() -> void:
	EventBus.shake_requested.connect(add_trauma)
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.ability_failed.connect(_on_ability_failed)
	EventBus.interactable_resolved.connect(_on_interactable_resolved)
	EventBus.player_caught.connect(add_trauma.bind(0.7))


func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func _process(delta: float) -> void:
	if trauma <= 0.0:
		if _shaking:
			_shaking = false
			get_viewport().canvas_transform = Transform2D.IDENTITY
		return
	_shaking = true
	trauma = maxf(0.0, trauma - DECAY * delta)
	var strength: float = trauma * trauma
	var offset: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * MAX_OFFSET * strength
	get_viewport().canvas_transform = Transform2D(randf_range(-1, 1) * MAX_ROTATION * strength, offset)


func _on_bubble_stolen(_bubble: BubbleData, _from: Vector2) -> void:
	add_trauma(0.3)


func _on_ability_failed(_bubble: BubbleData, _target_id: StringName) -> void:
	add_trauma(0.2)


func _on_interactable_resolved(_id: StringName, kind: StringName, _pos: Vector2) -> void:
	if kind != &"inspect":
		add_trauma(0.35 if kind == &"pushable" else 0.25)
