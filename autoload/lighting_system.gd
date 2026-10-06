extends Node
## Owns the flashlight state. Other systems read `is_light_on` and
## `light_intensity`, or listen to EventBus.light_toggled. The flashlight only
## works once GameState has the `has_flashlight` flag (end of Chapter 1).

const FLASHLIGHT_FLAG: StringName = &"has_flashlight"

var is_light_on: bool = false
var light_intensity: float = 1.0
## The current frame swallows light (FrameData.light_disabled).
var light_blocked: bool = false


func _ready() -> void:
	EventBus.player_caught.connect(set_light.bind(false))
	EventBus.game_reset.connect(set_light.bind(false))
	EventBus.returned_to_menu.connect(set_light.bind(false))
	EventBus.frame_changed.connect(_on_frame_changed)


func _on_frame_changed(data: FrameData) -> void:
	light_blocked = data.light_disabled
	if light_blocked:
		set_light(false)


func has_flashlight() -> bool:
	return GameState.has_flag(FLASHLIGHT_FLAG)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_light"):
		return
	if not GameState.is_playing or GameState.modal_open or TransitionManager.is_playing:
		return
	if has_flashlight() and light_blocked:
		EventBus.caption_requested.emit("The ink drinks the light.", 2.5)
		AudioManager.play(&"click", -10.0)
	elif has_flashlight():
		set_light(not is_light_on)
		get_viewport().set_input_as_handled()


func set_light(on: bool) -> void:
	if not has_flashlight() or light_blocked:
		on = false
	if on == is_light_on:
		return
	is_light_on = on
	EventBus.light_toggled.emit(on)
