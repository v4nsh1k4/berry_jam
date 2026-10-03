extends Node2D
## Gallery of Words: the way on opens once every portrait in the room is lit,
## i.e. every owner here is whole. Owners the player never robbed start lit,
## so the path adapts to whatever was (or wasn't) stolen.

const FLAG: StringName = &"gallery_open"


func _ready() -> void:
	EventBus.bubble_returned.connect(_on_bubble_returned)
	_check.call_deferred()


func _on_bubble_returned(_bubble: BubbleData, _pos: Vector2) -> void:
	_check.call_deferred()


func _check() -> void:
	if GameState.has_flag(FLAG):
		return
	for node in get_tree().get_nodes_in_group(&"return_spot"):
		if not (node as Interactable).resolved:
			return
	GameState.set_flag(FLAG)
	EventBus.caption_requested.emit("Every portrait is whole. Something gives way.", 3.5)
	# Lets doors waiting on the flag (secret_door) open now.
	EventBus.interactable_resolved.emit(&"gallery_gate", &"gate", get_global_transform_with_canvas().origin)
