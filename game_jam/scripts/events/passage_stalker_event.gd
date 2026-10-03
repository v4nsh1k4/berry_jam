extends Node2D
## Servant's Passage: teaches hiding. Shortly after you enter, a growl and a
## caption warn you; then the Crawler rises behind you and hunts. Hide (E at
## a hiding spot) or run for the far door. Done once it gives up.

const FLAG: StringName = &"survived_passage"
const WARN_AFTER: float = 2.0
const RISE_AFTER: float = 1.6

var _t: float = 0.0
var _stage: int = 0


func _ready() -> void:
	if GameState.has_flag(FLAG):
		queue_free()
		return
	EventBus.crawler_state_changed.connect(_on_crawler_state)


func _process(delta: float) -> void:
	_t += delta
	if _stage == 0 and _t > WARN_AFTER:
		_stage = 1
		EventBus.crawler_telegraph.emit()
		EventBus.caption_requested.emit("Something is coming. HIDE: press E at the wardrobe or the curtain.", 5.0)
	elif _stage == 1 and _t > WARN_AFTER + RISE_AFTER:
		_stage = 2
		var crawler: Node = get_tree().get_first_node_in_group(&"crawler")
		if crawler != null:
			crawler.call("wake_to", true, 2.5)


func _on_crawler_state(state: StringName) -> void:
	if _stage == 2 and state == &"DORMANT":
		GameState.set_flag(FLAG)
		EventBus.caption_requested.emit("It sank back into the floor. Keep going.", 3.5)
		queue_free()
