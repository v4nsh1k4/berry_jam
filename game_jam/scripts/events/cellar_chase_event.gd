extends Node2D
## Cellar Stair: the final beat of Chapter 2. When the cellar door opens, a
## growl and a red warning come first, then the Crawler surges from the far
## side of the room. The open door is right beside you: run.

const DOOR_FLAG: StringName = &"cellar_open"
const FLAG: StringName = &"escaped_cellar"
const WARNING: float = 1.2

var _countdown: float = -1.0


func _ready() -> void:
	if GameState.has_flag(FLAG):
		queue_free()
		return
	EventBus.interactable_resolved.connect(_on_resolved)
	EventBus.exit_entered.connect(_on_exit_entered)
	if GameState.has_flag(DOOR_FLAG):
		_start()


func _on_resolved(id: StringName, _kind: StringName, _pos: Vector2) -> void:
	if id == &"cellar_door":
		_start()


func _start() -> void:
	_countdown = WARNING
	EventBus.crawler_telegraph.emit()
	EventBus.shake_requested.emit(0.3)
	EventBus.caption_requested.emit("RUN.", 2.0)


func _process(delta: float) -> void:
	if _countdown < 0.0:
		return
	_countdown -= delta
	if _countdown <= 0.0:
		_countdown = -1.0
		var crawler: Node = get_tree().get_first_node_in_group(&"crawler")
		if crawler != null:
			crawler.call("wake_to", true, 8.0)


func _on_exit_entered(exit: ExitData) -> void:
	if GameState.has_flag(DOOR_FLAG) and exit.required_flag == DOOR_FLAG:
		GameState.set_flag(FLAG)
