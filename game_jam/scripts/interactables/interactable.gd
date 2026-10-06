class_name Interactable
extends Node2D
## Something in a frame the player acts on, built from InteractableData.
## Origin is the top-left of `data.size`. Word targets (door, drawer, latch,
## pushable) are resolved by ability handlers; plain targets (inspect, pickup,
## symbol_lock, hiding_spot) react to E with no word. `revealed_by_light`
## objects only show (and only work) while the flashlight cone is on them.
## Drawing lives in InteractableArt / InteractableArt2. Kinds with more
## behaviour are subclasses: HidingSpot, ReturnSpot (see Frame.KIND_CLASSES).

const PUSH_TIME: float = 0.4
## Kinds whose opening gets the unified feedback (UnlockFeedback).
const UNLOCK_KINDS: Array[StringName] = [&"door", &"symbol_lock", &"lever", &"latch", &"secret_door", &"drawer",
	&"light_ink", &"lens", &"shadow_puzzle", &"pushable"]
## Kinds drawn with a padlock until their requires_flag is set.
const BOLTED_KINDS: Array[StringName] = [&"door", &"symbol_lock"]
## Kinds that react to E without a word.
const PLAIN_KINDS: Array[StringName] = [&"inspect", &"pickup", &"symbol_lock", &"hiding_spot", &"lever"]
## Kinds that are never a target for E.
const PASSIVE_KINDS: Array[StringName] = [&"memory", &"writing", &"clock", &"secret_door", &"light_ink", &"lens", &"shadow_puzzle"]

var data: InteractableData
var resolved: bool = false
## 0..1 visibility of a memory sketch.
var memory_alpha: float = 0.0:
	set(value):
		memory_alpha = value
		if _glow != null:
			_glow.energy = value * 0.9
		queue_redraw()
## 1 -> 0 while the padlock falls off (its requires_flag just came true).
var unbolt: float = 0.0
## 0..1 how much the flashlight is revealing this (revealed_by_light only).
var reveal: float = 0.0
var _wiggle: float = 0.0
## Glow light (memory sketches, return spots).
var _glow: PointLight2D
var _tick: int = -1


func setup(interactable: InteractableData) -> void:
	data = interactable
	position = interactable.position
	resolved = data.sets_flag != &"" and GameState.has_flag(data.sets_flag)
	if data.kind == &"pushable" and resolved:
		position += data.push_offset
	if data.kind == &"memory":
		add_to_group(&"memory")
		_glow = PointLight2D.new()
		_glow.texture = LightTextures.radial()
		_glow.texture_scale = maxf(data.size.x, data.size.y) / LightTextures.RADIAL_RADIUS * 0.9
		_glow.position = data.size * 0.5
		_glow.energy = 0.0
		add_child(_glow)
	_update_group()
	if data.kind == &"symbol_lock":
		EventBus.symbol_lock_solved.connect(_on_symbol_lock_solved)
	if data.kind == &"secret_door":
		EventBus.interactable_resolved.connect(_on_any_resolved)
	if BOLTED_KINDS.has(data.kind) and data.requires_flag != &"" and not GameState.has_flag(data.requires_flag):
		EventBus.flag_set.connect(_on_flag_set)



## Targetable unless passive, used up, or still hidden in the dark.
func _update_group() -> void:
	var usable: bool = not PASSIVE_KINDS.has(data.kind) and (not resolved or data.kind in [&"inspect", &"hiding_spot"])
	if data.revealed_by_light and reveal < 0.6:
		usable = false
	if usable and not is_in_group(&"interactable"):
		add_to_group(&"interactable")
	elif not usable and is_in_group(&"interactable"):
		remove_from_group(&"interactable")


func is_plain() -> bool:
	return PLAIN_KINDS.has(data.kind)


func accepts(ability_id: StringName) -> bool:
	var unlocked: bool = data.requires_flag == &"" or GameState.has_flag(data.requires_flag)
	return unlocked and data.accepted_ability_ids.has(ability_id)


func get_interact_point() -> Vector2:
	return to_global(Vector2(data.size.x * 0.5, data.size.y + 20.0))


func get_prompt(bubble: BubbleData) -> String:
	match data.kind:
		&"inspect":
			return "E: look"
		&"pickup":
			return "E: take"
		&"symbol_lock":
			return "E: try the dials"
		&"lever":
			return "E: pull"
	if data.requires_flag != &"" and not GameState.has_flag(data.requires_flag) and data.prompt != "":
		return data.prompt
	if bubble == null:
		return data.prompt if data.prompt != "" else "It needs a word. Pick one with 1-6 or Q / R."
	return "E: say \"%s\"" % bubble.text


## E with no word, for plain kinds.
func interact_plain() -> void:
	match data.kind:
		&"inspect":
			var looked: StringName = StringName("looked_" + String(data.id))
			var again: bool = data.repeat_caption != "" and GameState.seen.has(looked)
			if not GameState.seen.has(looked):
				GameState.seen.append(looked)
			EventBus.caption_requested.emit(data.repeat_caption if again else data.caption, 3.0 if again else 4.5)
			EventBus.inspected.emit(data.id)
		&"lever":
			resolve()
		&"pickup":
			resolve()
			if data.caption != "":
				EventBus.caption_requested.emit(data.caption, 4.0)
		&"symbol_lock":
			EventBus.symbol_lock_requested.emit(data)


## Done: opened, pushed, unlocked or taken.
func resolve() -> void:
	resolved = true
	_update_group()
	if data.sets_flag != &"":
		GameState.set_flag(data.sets_flag)
	var screen_pos: Vector2 = get_global_transform_with_canvas() * (data.size * 0.5)
	EventBus.interactable_resolved.emit(data.id, data.kind, screen_pos)
	if UNLOCK_KINDS.has(data.kind):
		EventBus.unlocked.emit(data, screen_pos)
	if data.reward_bubble != null and not GameState.is_bubble_stolen(data.reward_bubble.id):
		GameState.add_bubble(data.reward_bubble, screen_pos)
		EventBus.caption_requested.emit("A crumpled word was hidden inside: \"%s\"." % data.reward_bubble.text, 3.5)
	queue_redraw()


func push() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + data.push_offset, PUSH_TIME)
	resolve()


func can_remember() -> bool:
	return data.kind == &"memory" and (data.requires_flag == &"" or GameState.has_flag(data.requires_flag))


func reveal_memory(duration: float) -> void:
	if data.caption != "":
		EventBus.caption_requested.emit(data.caption, maxf(duration, 3.5))
	var tween: Tween = create_tween()
	tween.tween_property(self, "memory_alpha", 1.0, 0.5)
	tween.tween_interval(maxf(duration, 1.0))
	tween.tween_property(self, "memory_alpha", 0.0, 1.0)
	if data.sets_flag != &"" and not GameState.has_flag(data.sets_flag):
		GameState.set_flag(data.sets_flag)
		var screen_pos: Vector2 = get_global_transform_with_canvas() * (data.size * 0.5)
		EventBus.interactable_resolved.emit(data.id, data.kind, screen_pos)


## Wrong word: a little shudder, never a failure state.
func react_wrong() -> void:
	var tween: Tween = create_tween()
	for offset in [6.0, -5.0, 3.0, 0.0]:
		tween.tween_property(self, "_wiggle", offset, 0.05)
	tween.tween_callback(queue_redraw)


func _on_symbol_lock_solved(lock_id: StringName) -> void:
	if lock_id == data.id and not resolved:
		resolve()


## The bolt condition came true while the player is here: the padlock falls.
func _on_flag_set(flag: StringName) -> void:
	if flag != data.requires_flag or resolved:
		return
	EventBus.flag_set.disconnect(_on_flag_set)
	create_tween().tween_property(self, "unbolt", 0.0, 0.9).from(1.0)
	EventBus.unlocked.emit(data, get_global_transform_with_canvas() * (data.size * 0.5))


## A secret door opens itself once the flag it waits on is set.
func _on_any_resolved(_id: StringName, _kind: StringName, _pos: Vector2) -> void:
	if not resolved and data.requires_flag != &"" and GameState.has_flag(data.requires_flag):
		resolve()


func _process(delta: float) -> void:
	if data != null and data.revealed_by_light:
		_update_reveal(delta)
	var tick: int = InkDraw.boil_tick()
	if tick != _tick or _wiggle != 0.0:
		_tick = tick
		queue_redraw()


## Fades in while the cone is on it, out when it leaves.
func _update_reveal(delta: float) -> void:
	var lamp: Flashlight = get_tree().get_first_node_in_group(&"flashlight") as Flashlight
	var lit: bool = lamp != null and lamp.illuminates_rect(Rect2(global_position, data.size * global_scale))
	reveal = move_toward(reveal, 1.0 if lit else 0.0, delta * (3.0 if lit else 1.2))
	_update_group()


func _draw() -> void:
	if data == null:
		return
	draw_set_transform(Vector2(_wiggle, 0))
	if LightPuzzleArt.handles(data.kind):
		LightPuzzleArt.draw(self, _tick)
	elif InteractableArt2.handles(data.kind):
		InteractableArt2.draw(self, _tick)
	else:
		InteractableArt.draw(self, _tick)
