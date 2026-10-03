class_name ReturnSpot
extends Interactable
## Where an owner's words can go back (Chapter 3): a painting of them or the
## old drawer (data.text). Takes any word whose stolen_from is data.owner_id.
## Lights up and sets data.sets_flag once its owner is whole again; owners the
## player never robbed are whole from the start, so they never block anything.


func setup(interactable: InteractableData) -> void:
	super.setup(interactable)
	add_to_group(&"return_spot")
	_glow = PointLight2D.new()
	_glow.texture = LightTextures.radial()
	_glow.texture_scale = maxf(data.size.x, data.size.y) / LightTextures.RADIAL_RADIUS * 1.1
	_glow.position = data.size * 0.5
	_glow.color = Color(1.0, 0.95, 0.85)
	add_child(_glow)
	EventBus.bubble_returned.connect(_on_word_returned)
	_check_owner_whole(false)


func get_prompt(bubble: BubbleData) -> String:
	return "E: give back \"%s\"" % bubble.text if bubble != null else "Pick a word (1-6, Q / R) to give back"


func _update_group() -> void:
	super._update_group()
	if not GameState.can_return() and is_in_group(&"interactable"):
		remove_from_group(&"interactable")


func receive_word(bubble: BubbleData) -> void:
	if bubble == null or bubble.stolen_from != data.owner_id or not GameState.can_return():
		react_wrong()
		EventBus.ability_failed.emit(bubble, data.id)
		return
	GameState.return_bubble(bubble, get_global_transform_with_canvas() * (data.size * 0.5))


func _on_word_returned(_bubble: BubbleData, _pos: Vector2) -> void:
	_check_owner_whole(true)
	queue_redraw()


func _check_owner_whole(announce: bool) -> void:
	var whole: bool = GameState.stolen_from_count(data.owner_id) == 0
	_glow.energy = 0.9 if whole else 0.0
	if not whole or resolved:
		return
	if announce:
		resolve()
	else:
		resolved = true
		if data.sets_flag != &"":
			GameState.set_flag(data.sets_flag)
		_update_group()
