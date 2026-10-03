class_name HidingSpot
extends Interactable
## A wardrobe, curtain or table (data.text) to hide in: E steps in and out.
## The Ink Shadow can scribble one out: a visible scribble and a sound first
## (the warning), then it is gone and anyone inside is pushed out.

## A hiding spot the player is inside.
var occupied: bool = false
## 0..1 how far the scribble-out has got; 1 = erased for good (this visit).
var erase_progress: float = 0.0
var erased: bool = false


func get_prompt(_bubble: BubbleData) -> String:
	return "E: come out" if occupied else "E: hide"


func interact_plain() -> void:
	if erased:
		return
	occupied = not occupied
	EventBus.hiding_spot_used.emit(data.id, get_global_transform_with_canvas() * Vector2(data.size.x * 0.5, data.size.y))
	queue_redraw()


## Telegraphed erase: scribbles over it for `warning` seconds, then removes it.
func scribble_out(warning: float) -> void:
	if erased or erase_progress > 0.0:
		return
	EventBus.crawler_telegraph.emit()
	var tween: Tween = create_tween()
	tween.tween_property(self, "erase_progress", 1.0, warning)
	tween.tween_callback(_erase)


func _erase() -> void:
	erased = true
	remove_from_group(&"interactable")
	if occupied:
		occupied = false
	EventBus.hiding_spot_erased.emit(data.id)
	EventBus.shake_requested.emit(0.25)
	queue_redraw()


func _update_group() -> void:
	if erased:
		return
	super._update_group()


func _process(delta: float) -> void:
	super._process(delta)
	if erase_progress > 0.0 and not erased:
		queue_redraw()
