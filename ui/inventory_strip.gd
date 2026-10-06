extends Control
## Comic strip below the panel showing the inventory as word SLOTS
## (InventorySlots: same-word bubbles share a slot with an "x2" badge). Six
## slots show at once; the window follows the selection and arrows show when
## words are off-screen. 1-6 pick a visible slot, Q / R or the mouse wheel
## cycle, a click picks a slot. Reorder: drag a slot onto another, or
## Shift+Q / Shift+R moves the selected word. Hover shows what a word does;
## the selected word's name and effect stay on a line above the strip.

const VISIBLE_SLOTS: int = 6
const SLOT_SIZE: Vector2 = Vector2(134, 92)
const SLOTS_LEFT: float = 114.0
const SLOT_GAP: float = 10.0
const FLY_TIME: float = 0.55
const SPOKEN_TIME: float = 0.45
const DRAG_START: float = 12.0

## Slot index of the first visible slot.
var _first: int = 0
## Slot hidden mid-flight (the stolen word is flying into it).
var _flying_slot: int = -1
var _hover_slot: int = -1
var _spoken_slot: int = -1
var _spoken_left: float = 0.0
## Mouse drag: the slot pressed, where, and whether it became a drag.
var _press_slot: int = -1
var _press_pos: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_pos: Vector2 = Vector2.ZERO
var _tick: int = -1
## The "+N" arrow under the mouse: -1 left, 1 right, 0 none.
var _hover_arrow: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.bubble_selected.connect(_on_bubble_selected)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.bubble_removed.connect(func(_b: BubbleData) -> void: _on_bubble_selected(0))
	EventBus.inventory_reordered.connect(queue_redraw)
	EventBus.returned_to_menu.connect(hide)
	EventBus.game_reset.connect(_on_game_reset)
	EventBus.ability_used.connect(_on_ability_used)
	mouse_exited.connect(_on_mouse_exited)
	hide()


## True when slot `slot` is inside the visible window.
func is_slot_visible(slot: int) -> bool:
	return slot >= _first and slot < _first + VISIBLE_SLOTS


func first_visible() -> int:
	return _first


func _show_slot(slot: int) -> void:
	if slot >= 0:
		if slot < _first:
			_first = slot
		elif slot >= _first + VISIBLE_SLOTS:
			_first = slot - VISIBLE_SLOTS + 1
	_first = clampi(_first, 0, maxi(0, InventorySlots.count() - VISIBLE_SLOTS))
	queue_redraw()


func _on_game_reset() -> void:
	_first = 0
	queue_redraw()


func _on_ability_used(bubble: BubbleData, _target_id: StringName) -> void:
	_spoken_slot = InventorySlots.slot_of(bubble)
	_spoken_left = SPOKEN_TIME


func _on_mouse_exited() -> void:
	_hover_slot = -1
	_hover_arrow = 0
	queue_redraw()


func _on_frame_changed(_data: FrameData) -> void:
	show()


func _on_bubble_selected(_index: int) -> void:
	_show_slot(InventorySlots.selected_slot())


func _slot_rect(slot: int) -> Rect2:
	return Rect2(Vector2(SLOTS_LEFT + slot * (SLOT_SIZE.x + SLOT_GAP), (size.y - SLOT_SIZE.y) * 0.5), SLOT_SIZE)


## -1 / 1 when `pos` is on a shown "+N" arrow, else 0.
func _arrow_at(pos: Vector2) -> int:
	if _first > 0 and InventoryArt.arrow_rect(_slot_rect(0).position.x - 6.0, -1.0).has_point(pos):
		return -1
	if _first + VISIBLE_SLOTS < InventorySlots.count() and InventoryArt.arrow_rect(_slot_rect(VISIBLE_SLOTS - 1).end.x + 6.0, 1.0).has_point(pos):
		return 1
	return 0


func _slot_at(pos: Vector2) -> int:
	for slot in VISIBLE_SLOTS:
		if _slot_rect(slot).has_point(pos) and _first + slot < InventorySlots.count():
			return slot
	return -1


func _on_bubble_stolen(bubble: BubbleData, from_screen_pos: Vector2) -> void:
	var slot: int = InventorySlots.slot_of(bubble)
	_show_slot(slot)
	Hints.once("say_selected", "The highlighted word is the one you speak. Press E to say it.", 6.0)
	Hints.once("hover_words", "Hover a word to see what it does (the selected word's effect shows above the strip).", 5.0)
	if InventorySlots.count() >= 3:
		Hints.once("reorder_words", "Drag a word to move it, or Shift+Q / Shift+R.", 4.0)
	if from_screen_pos == Vector2.INF:
		return
	_flying_slot = slot
	var target: Vector2 = get_global_transform() * _slot_rect(slot - _first).get_center()
	InventoryArt.fly(get_parent(), bubble.text, from_screen_pos, target, FLY_TIME, _on_flyer_landed)


func _on_flyer_landed() -> void:
	_flying_slot = -1
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playing or GameState.modal_open:
		return
	var shift: bool = event is InputEventWithModifiers and (event as InputEventWithModifiers).shift_pressed
	var step: int = -1 if event.is_action_pressed("word_prev") else (1 if event.is_action_pressed("word_next") else 0)
	if step != 0 and shift:
		InventorySlots.move_selected(step)
	elif step != 0:
		InventorySlots.cycle(step)
	else:
		for slot in VISIBLE_SLOTS:
			if event.is_action_pressed("bubble_slot_%d" % (slot + 1)):
				InventorySlots.select_slot(_first + slot)
				get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var pos: Vector2 = (event as InputEventMouseMotion).position
		var arrow: int = _arrow_at(pos)
		if arrow != _hover_arrow:
			_hover_arrow = arrow
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if arrow != 0 else Control.CURSOR_ARROW
			queue_redraw()
		var hover: int = _slot_at(pos)
		if _press_slot >= 0 and pos.distance_to(_press_pos) > DRAG_START:
			_dragging = true
		_drag_pos = pos
		if hover != _hover_slot or _dragging:
			_hover_slot = hover
			queue_redraw()
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null:
		return
	if mouse.pressed and (mouse.button_index == MOUSE_BUTTON_WHEEL_UP or mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		InventorySlots.cycle(-1 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
	elif mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed and _arrow_at(mouse.position) != 0:
		# Stage 6b: the "+N" arrows scroll the window one slot.
		_first = clampi(_first + _arrow_at(mouse.position), 0, maxi(0, InventorySlots.count() - VISIBLE_SLOTS))
		_hover_arrow = _arrow_at(mouse.position)
		queue_redraw()
	elif mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
		_press_slot = _slot_at(mouse.position)
		_press_pos = mouse.position
		_dragging = false
	elif mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed and _press_slot >= 0:
		var drop: int = _slot_at(mouse.position)
		if _dragging and drop >= 0 and drop != _press_slot:
			InventorySlots.select_slot(_first + _press_slot, false)
			InventorySlots.move_slot(_first + _press_slot, _first + drop)
		elif not _dragging:
			InventorySlots.select_slot(_first + _press_slot)
		_press_slot = -1
		_dragging = false
		queue_redraw()
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
	var list: Array = InventorySlots.slots()
	var count: int = list.size()
	var selected: int = InventorySlots.selected_slot()
	InkDraw.rect(self, Rect2(Vector2.ZERO, size), 4.0, s, InkDraw.PAPER)
	draw_string(font, Vector2(16, size.y * 0.5 - 12), "WORDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, InkDraw.INK)
	draw_string(font, Vector2(16, size.y * 0.5 + 8), "1-6, Q / R", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(InkDraw.INK, 0.6))
	draw_string(font, Vector2(16, size.y * 0.5 + 42), "E says it", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, InkDraw.INK)
	if count > 0:
		draw_string(font, Vector2(16, size.y * 0.5 + 26), "%d words" % GameState.inventory.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(InkDraw.INK, 0.6))
	for slot in VISIBLE_SLOTS:
		var index: int = _first + slot
		var r: Rect2 = _slot_rect(slot)
		var is_selected: bool = index == selected and index < count
		if is_selected:
			draw_rect(r, InkDraw.WHITE)
			InkDraw.hatch(self, r.grow(-3), 10.0, 1.0, s + slot, Color(InkDraw.INK, 0.3))
		InkDraw.rect(self, r, 5.0 if is_selected else 2.5, s + 10 + slot, Color.TRANSPARENT, InkDraw.RED if is_selected else InkDraw.INK)
		draw_string(font, r.position + Vector2(8, 18), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, InkDraw.INK)
		if index >= count or index == _flying_slot or (_dragging and slot == _press_slot):
			continue
		var group: Array = list[index]
		var bubble: BubbleData = group[0]
		var center: Vector2 = r.get_center() + Vector2(6, 4)
		if index == _spoken_slot and _spoken_left > 0.0:
			# "Spoken": the word hops up out of its slot and drops back.
			center.y -= sin((1.0 - _spoken_left / SPOKEN_TIME) * PI) * 26.0
		BubbleArt.draw(self, center, bubble.text, BubbleArt.NO_TAIL, s + 20 + slot, InventoryArt.fit_font_size(bubble.text, r.size.x - 20))
		InventoryArt.draw_cooldown(self, r, bubble.ability_id)
		InventoryArt.draw_badge(self, r, group.size())
	if _first > 0:
		InventoryArt.draw_more_arrow(self, _slot_rect(0).position.x - 6.0, -1.0, _first, _hover_arrow == -1)
	if _first + VISIBLE_SLOTS < count:
		InventoryArt.draw_more_arrow(self, _slot_rect(VISIBLE_SLOTS - 1).end.x + 6.0, 1.0, count - _first - VISIBLE_SLOTS, _hover_arrow == 1)
	if _dragging and _press_slot >= 0 and _first + _press_slot < count:
		var dragged: BubbleData = (list[_first + _press_slot] as Array)[0]
		BubbleArt.draw(self, _drag_pos, dragged.text, BubbleArt.NO_TAIL, s + 60)
	elif _hover_slot >= 0 and _first + _hover_slot < count:
		InventoryArt.draw_tooltip(self, _slot_rect(_hover_slot), (list[_first + _hover_slot] as Array)[0], _tick)
	else:
		InventoryArt.draw_selected_line(self, GameState.selected_bubble())
