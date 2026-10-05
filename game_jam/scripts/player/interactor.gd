class_name Interactor
extends Node2D
## Child of the Player. Picks what E would act on and publishes a prompt.
## Bubbles in reach win (stealable ones, and after the twist the broken ones
## a word can go back to): the one the player stands nearest to along the
## floor, ties going to the side they face. The mouse is not used, so it stays
## free to aim the flashlight.
## Hold E on a whole bubble: steal. Hold E on a broken bubble: give the
## selected word back. E on an object: speak the selected word (or, for plain
## objects, just use it). E with nothing near: speak into the room.

const REACH: float = 130.0
## How far from the speaker the player may be to steal at all.
const SPEAKER_REACH: float = 380.0
## How far to the side of a bubble the player may stand to take it.
const UNDER_REACH: float = 120.0
## Bubbles closer than this count as a tie; facing decides.
const TIE: float = 10.0
const STEAL_TIME: float = 0.5
const RETURN_TIME: float = 0.7
## Giving the last word back is a longer, heavier hold.
const FINAL_RETURN_TIME: float = 1.4

var _target: Node2D
var _hold: float = 0.0
var _choices: int = 0


func _ready() -> void:
	EventBus.bubble_selected.connect(_on_bubble_selected)


func _player() -> Player:
	return get_parent() as Player


func _process(delta: float) -> void:
	# The room it pointed into may have been freed (room change, quit).
	if not is_instance_valid(_target):
		_target = null
	var target: Node2D = _find_target() if _player().can_act() else null
	if target != _target:
		_clear_hold()
		if _target is SpeechBubble:
			(_target as SpeechBubble).targeted = false
		_target = target
		if _target is SpeechBubble:
			(_target as SpeechBubble).targeted = true
		_update_prompt()

	if not _target is SpeechBubble:
		return
	var bubble: SpeechBubble = _target as SpeechBubble
	var returning: bool = bubble.is_returnable()
	if Input.is_action_pressed("interact") and (not returning or GameState.selected_bubble() != null):
		_hold += delta
		var needed: float = STEAL_TIME
		if returning:
			needed = FINAL_RETURN_TIME if bubble.data.story_final else RETURN_TIME
		bubble.steal_progress = _hold / needed
		if _hold >= needed:
			if returning:
				_give_back(bubble)
			else:
				_steal(bubble)
	elif _hold > 0.0:
		_clear_hold()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_target):
		_target = null
	if not event.is_action_pressed("interact") or _target is SpeechBubble or not _player().can_act():
		return
	var target: Interactable = _target as Interactable
	if target != null and target.is_plain():
		target.interact_plain()
	elif target is ReturnSpot:
		(target as ReturnSpot).receive_word(GameState.selected_bubble())
	else:
		_speak(target)
	_update_prompt()
	get_viewport().set_input_as_handled()


func _find_target() -> Node2D:
	var facing: float = _player().facing
	var best_bubble: Node2D = null
	var best_score: float = INF
	_choices = 0
	for group in [&"stealable", &"returnable"]:
		for node in get_tree().get_nodes_in_group(group):
			var bubble: SpeechBubble = node as SpeechBubble
			if global_position.distance_to(bubble.get_interact_point()) > SPEAKER_REACH:
				continue
			var dx: float = bubble.global_position.x - global_position.x
			if absf(dx) > UNDER_REACH:
				continue
			_choices += 1
			# Bucket by TIE so near-equal distances compare on facing instead.
			var score: float = floorf(absf(dx) / TIE) * 2.0 + (0.0 if signf(dx) == facing or dx == 0.0 else 1.0)
			if score < best_score:
				best_bubble = bubble
				best_score = score
	if best_bubble != null:
		return best_bubble
	var best: Node2D = null
	var best_distance: float = REACH
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var item: Interactable = node as Interactable
		var distance: float = global_position.distance_to(item.get_interact_point())
		if distance < best_distance:
			best = item
			best_distance = distance
	return best


func _steal(bubble: SpeechBubble) -> void:
	var screen_pos: Vector2 = bubble.get_global_transform_with_canvas().origin
	var data: BubbleData = bubble.data
	bubble.steal()
	_target = null
	_hold = 0.0
	_update_prompt()
	GameState.add_bubble(data, screen_pos)


## Gives the selected word back if it belongs to this bubble's owner (any
## of their broken bubbles will do; the word's own bubble is the one that
## mends); otherwise "?".
func _give_back(bubble: SpeechBubble) -> void:
	_clear_hold()
	var word: BubbleData = InventorySlots.word_for_owner(bubble.data.stolen_from)
	if word == null or word.stolen_from != bubble.data.stolen_from or not GameState.is_bubble_stolen(word.id):
		bubble.refuse()
		EventBus.ability_failed.emit(word, &"")
		return
	if word.story_final and GameState.normal_words_held() > 0:
		# The last word goes back last: everyone else first.
		bubble.refuse()
		EventBus.caption_requested.emit("Not yet. You are still holding their words.", 3.0)
		return
	_target = null
	GameState.return_bubble(word, bubble.get_global_transform_with_canvas().origin)
	_update_prompt()


func _speak(target: Interactable) -> void:
	var bubble: BubbleData = GameState.selected_bubble()
	if bubble == null:
		if target != null:
			target.react_wrong()
			EventBus.player_reaction.emit("?")
		return
	if AbilityRegistry.speak(bubble, target):
		_target = null


func _clear_hold() -> void:
	_hold = 0.0
	if is_instance_valid(_target) and _target is SpeechBubble:
		(_target as SpeechBubble).steal_progress = 0.0


func _on_bubble_selected(_index: int) -> void:
	_update_prompt()


func _update_prompt() -> void:
	var text: String = ""
	var pos: Vector2 = Vector2.ZERO
	if is_instance_valid(_target):
		if _target is SpeechBubble:
			text = (_target as SpeechBubble).get_prompt()
			if _choices > 1:
				text += "   (step left / right to choose)"
		elif _target is Interactable:
			text = (_target as Interactable).get_prompt(GameState.selected_bubble())
		pos = get_viewport().get_canvas_transform() * (_target.call("get_interact_point") as Vector2)
	EventBus.interact_prompt_changed.emit(text, pos)
