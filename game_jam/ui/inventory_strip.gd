extends Control
## Comic strip below the panel showing GameState.inventory, which has no size
## cap. Six slots are visible at once; the window follows the selection and
## arrows show when words are off-screen. 1-6 pick a visible slot, Q / R or
## the mouse wheel cycle through every word, a click picks a slot.

const VISIBLE_SLOTS: int = 6
const SLOT_SIZE: Vector2 = Vector2(134, 92)
const SLOTS_LEFT: float = 114.0
const SLOT_GAP: float = 10.0
const FLY_TIME: float = 0.55
const SPOKEN_TIME: float = 0.45

## Inventory index of the first visible slot.
var _first: int = 0
## Inventory index currently mid-flight (hidden in its slot until it lands).
var _flying_index: int = -1
var _hover_slot: int = -1
var _spoken_index: int = -1
var _spoken_left: float = 0.0
var _tick: int = -1


class FlyingBubble:
	extends Node2D
	var text: String = ""

	func _draw() -> void:
		BubbleArt.draw(self, Vector2.ZERO, text, BubbleArt.NO_TAIL, 3)


func _ready() -> void:
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.bubble_selected.connect(_on_bubble_selected)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.bubble_removed.connect(_on_bubble_removed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.game_reset.connect(_on_game_reset)
	EventBus.ability_used.connect(_on_ability_used)
	mouse_exited.connect(_on_mouse_exited)
	hide()


## True when inventory entry `index` is inside the visible window.
func is_index_visible(index: int) -> bool:
	return index >= _first and index < _first + VISIBLE_SLOTS


func first_visible() -> int:
	return _first


func _show_index(index: int) -> void:
	if index >= 0:
		if index < _first:
			_first = index
		elif index >= _first + VISIBLE_SLOTS:
			_first = index - VISIBLE_SLOTS + 1
	_first = clampi(_first, 0, maxi(0, GameState.inventory.size() - VISIBLE_SLOTS))
	queue_redraw()


func _on_game_reset() -> void:
	_first = 0
	queue_redraw()


func _on_bubble_removed(_bubble: BubbleData) -> void:
	_show_index(GameState.selected_index)


func _on_ability_used(bubble: BubbleData, _target_id: StringName) -> void:
	_spoken_index = GameState.inventory.find(bubble)
	_spoken_left = SPOKEN_TIME


func _on_mouse_exited() -> void:
	_hover_slot = -1
	queue_redraw()


func _on_frame_changed(_data: FrameData) -> void:
	show()


func _on_bubble_selected(index: int) -> void:
	_show_index(index)


func _slot_rect(slot: int) -> Rect2:
	return Rect2(Vector2(SLOTS_LEFT + slot * (SLOT_SIZE.x + SLOT_GAP), (size.y - SLOT_SIZE.y) * 0.5), SLOT_SIZE)


func _on_bubble_stolen(bubble: BubbleData, from_screen_pos: Vector2) -> void:
	var index: int = GameState.inventory.size() - 1
	_show_index(index)
	if from_screen_pos == Vector2.INF:
		return
	_flying_index = index
	var flyer: FlyingBubble = FlyingBubble.new()
	flyer.text = bubble.text
	flyer.position = from_screen_pos
	# Flashes red as it is torn away, fading back to white on the way down.
	flyer.modulate = Color(1.0, 0.25, 0.3)
	get_parent().add_child(flyer)
	var target: Vector2 = get_global_transform() * _slot_rect(index - _first).get_center()
	var tween: Tween = flyer.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(flyer, "scale", Vector2(1.35, 1.35), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(flyer, "position", target, FLY_TIME)
	tween.parallel().tween_property(flyer, "scale", Vector2(0.85, 0.85), FLY_TIME)
	tween.parallel().tween_property(flyer, "modulate", Color.WHITE, FLY_TIME)
	tween.tween_callback(_on_flyer_landed.bind(flyer))


func _on_flyer_landed(flyer: Node2D) -> void:
	flyer.queue_free()
	_flying_index = -1
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playing or GameState.modal_open:
		return
	if event.is_action_pressed("word_prev"):
		GameState.cycle(-1)
	elif event.is_action_pressed("word_next"):
		GameState.cycle(1)
	else:
		for slot in VISIBLE_SLOTS:
			if event.is_action_pressed("bubble_slot_%d" % (slot + 1)):
				GameState.select(_first + slot)
				get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hover: int = -1
		for slot in VISIBLE_SLOTS:
			if _slot_rect(slot).has_point((event as InputEventMouseMotion).position):
				hover = slot
		if hover != _hover_slot:
			_hover_slot = hover
			queue_redraw()
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	if mouse.button_index == MOUSE_BUTTON_WHEEL_UP or mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		GameState.cycle(-1 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
	elif mouse.button_index == MOUSE_BUTTON_LEFT:
		for slot in VISIBLE_SLOTS:
			if _slot_rect(slot).has_point(mouse.position):
				GameState.select(_first + slot)
	accept_event()


func _process(delta: float) -> void:
	if _spoken_left > 0.0:
		_spoken_left = maxf(0.0, _spoken_left - delta)
		queue_redraw()
	var tick: int = InkDraw.boil_tick()
	if tick != _tick or InventoryArt.any_cooling():
		_tick = tick
		queue_redraw()


func _draw() -> void:
	var s: int = _tick * 41
	var font: Font = ThemeDB.fallback_font
	var count: int = GameState.inventory.size()
	InkDraw.rect(self, Rect2(Vector2.ZERO, size), 4.0, s, InkDraw.PAPER)
	draw_string(font, Vector2(16, size.y * 0.5 - 12), "WORDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, InkDraw.INK)
	draw_string(font, Vector2(16, size.y * 0.5 + 8), "1-6, Q / R", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(InkDraw.INK, 0.6))
	if count > 0:
		draw_string(font, Vector2(16, size.y * 0.5 + 26), "%d words" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(InkDraw.INK, 0.6))
	for slot in VISIBLE_SLOTS:
		var index: int = _first + slot
		var r: Rect2 = _slot_rect(slot)
		var selected: bool = index == GameState.selected_index and index < count
		if selected:
			draw_rect(r, InkDraw.WHITE)
			InkDraw.hatch(self, r.grow(-3), 10.0, 1.0, s + slot, Color(InkDraw.INK, 0.3))
		InkDraw.rect(self, r, 5.0 if selected else 2.5, s + 10 + slot, Color.TRANSPARENT, InkDraw.RED if selected else InkDraw.INK)
		draw_string(font, r.position + Vector2(8, 18), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, InkDraw.INK)
		if index >= count or index == _flying_index:
			continue
		var bubble: BubbleData = GameState.inventory[index]
		var center: Vector2 = r.get_center() + Vector2(6, 4)
		if index == _spoken_index and _spoken_left > 0.0:
			# "Spoken": the word hops up out of its slot and drops back.
			center.y -= sin((1.0 - _spoken_left / SPOKEN_TIME) * PI) * 26.0
		BubbleArt.draw(self, center, bubble.text, BubbleArt.NO_TAIL, s + 20 + slot, InventoryArt.fit_font_size(bubble.text, r.size.x - 20))
		InventoryArt.draw_cooldown(self, r, bubble.ability_id)
	if _first > 0:
		InventoryArt.draw_more_arrow(self, _slot_rect(0).position.x - 6.0, -1.0, _first)
	if _first + VISIBLE_SLOTS < count:
		InventoryArt.draw_more_arrow(self, _slot_rect(VISIBLE_SLOTS - 1).end.x + 6.0, 1.0, count - _first - VISIBLE_SLOTS)
	if _hover_slot >= 0 and _first + _hover_slot < count:
		InventoryArt.draw_tooltip(self, _slot_rect(_hover_slot), GameState.inventory[_first + _hover_slot], _tick)
