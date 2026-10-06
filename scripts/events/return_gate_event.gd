extends Node2D
## Return phase: the way to the Ink Heart opens once every ordinary word has
## gone back to its owner (ERASE goes back last, at the Heart). Owners the
## player never robbed are already whole, so the gate adapts to any run.

const FLAG: StringName = &"all_returned"


func _ready() -> void:
	EventBus.bubble_returned.connect(_on_bubble_returned)
	_check.call_deferred()


func _on_bubble_returned(_bubble: BubbleData, _pos: Vector2) -> void:
	_check.call_deferred()


func _check() -> void:
	if GameState.has_flag(FLAG) or GameState.normal_words_held() > 0:
		return
	GameState.set_flag(FLAG)
	EventBus.caption_requested.emit("Everyone is whole. Only the last word is left. Go to the Heart.", 4.0)
	# Lets exits and doors waiting on the flag open now.
	EventBus.interactable_resolved.emit(&"return_gate", &"gate", get_global_transform_with_canvas().origin)
