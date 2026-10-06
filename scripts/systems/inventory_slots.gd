class_name InventorySlots
extends RefCounted
## The inventory as the player sees it: one SLOT per word text. Two stolen
## bubbles with the same word (WAIT from Arthur and from Mrs. Vane, HUSH from
## the drawer and from Mrs. Vane) share one slot with a "x2" badge, but each
## keeps its own stolen_from, so giving words back still goes to the right
## owner (`word_for_owner`). GameState.inventory stays the single source of
## truth (its order is the slot order); GameState.selected_index points at the
## first bubble of the selected slot.


## Arrays of BubbleData grouped by text, in inventory order.
static func slots() -> Array:
	var out: Array = []
	var by_text: Dictionary = {}
	for bubble in GameState.inventory:
		if not by_text.has(bubble.text):
			by_text[bubble.text] = out.size()
			out.append([])
		(out[by_text[bubble.text]] as Array).append(bubble)
	return out


static func count() -> int:
	return slots().size()


static func slot_of(bubble: BubbleData) -> int:
	var list: Array = slots()
	for i in list.size():
		if (list[i] as Array).has(bubble):
			return i
	return -1


static func selected_slot() -> int:
	var bubble: BubbleData = GameState.selected_bubble()
	return slot_of(bubble) if bubble != null else -1


static func select_slot(slot: int, toggle: bool = true) -> void:
	var list: Array = slots()
	if slot < 0 or slot >= list.size() or (toggle and slot == selected_slot()):
		GameState.select(-1)
		return
	GameState.select(GameState.inventory.find((list[slot] as Array)[0]), false)


## Q / R / wheel: the next slot, wrapping.
static func cycle(step: int) -> void:
	var n: int = count()
	if n == 0:
		return
	var start: int = selected_slot()
	if start < 0:
		start = 0 if step > 0 else 1
	select_slot(posmod(start + step, n), false)


## The bubble in the selected slot that belongs to `owner` (for giving words
## back); otherwise the selected bubble itself.
static func word_for_owner(owner: StringName) -> BubbleData:
	var selected: BubbleData = GameState.selected_bubble()
	if selected == null:
		return null
	for bubble in GameState.inventory:
		if bubble.text == selected.text and bubble.stolen_from == owner:
			return bubble
	return selected


## Moves the selected slot one place left / right (Shift+Q / Shift+R, drag).
static func move_selected(step: int) -> void:
	move_slot(selected_slot(), selected_slot() + step)


static func move_slot(from: int, to: int) -> void:
	var list: Array = slots()
	if from < 0 or from >= list.size():
		return
	to = clampi(to, 0, list.size() - 1)
	if to == from:
		return
	var selected: BubbleData = GameState.selected_bubble()
	var group: Array = list[from]
	list.remove_at(from)
	list.insert(to, group)
	var order: Array[BubbleData] = []
	for g in list:
		for bubble in g:
			order.append(bubble)
	GameState.inventory = order
	GameState.selected_index = order.find(selected) if selected != null else -1
	EventBus.inventory_reordered.emit()
	EventBus.bubble_selected.emit(GameState.selected_index)
