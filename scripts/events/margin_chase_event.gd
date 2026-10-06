extends Node2D
## The Margin: the Ink Shadow rises at the left edge after a warning and
## comes for the player across the page. Run for the door; hide only to dodge.

const WARNING: float = 1.4

var _t: float = 0.0
var _started: bool = false


func _ready() -> void:
	EventBus.crawler_telegraph.emit()
	EventBus.shake_requested.emit(0.3)


func _process(delta: float) -> void:
	if _started:
		return
	_t += delta
	if _t >= WARNING:
		_started = true
		var shadow: Node = get_tree().get_first_node_in_group(&"crawler")
		if shadow != null:
			shadow.call("wake_to", true, 9999.0)
