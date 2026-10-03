extends Node
## Run-wide state: inventory, flags and the counters the twist reads. Every
## frame change takes a checkpoint (in memory and to user://). Snapshots are
## built and read by StateSnapshot.

## Comic damage at full strength = every stealable word in the game (100%):
## Chapter 1 has 6 (OPEN, PUSH, WAIT, HELP, REMEMBER, HUSH in the drawer),
## Chapter 2 has 3 (Mrs. Vane), Chapter 3 has the last one (ERASE).
const DAMAGE_FOR_FULL_EFFECT: float = 10.0
## How fast the shown damage follows the real value (words per second), so
## returning a word heals the page smoothly instead of in a jump.
const DAMAGE_EASE: float = 0.8

var is_playing: bool = false
## A menu or lock dial is open; the player cannot act.
var modal_open: bool = false
var current_frame_id: StringName = &""
var current_chapter: ChapterData
## Snapshot taken when the current chapter began (Restart Chapter loads it).
## After the reveal it is retaken, so a restart begins the return phase.
var chapter_start: Dictionary = {}
var inventory: Array[BubbleData] = []
var selected_index: int = -1
var flags: Dictionary = {}
var stolen_bubble_ids: Array[StringName] = []
## Words given back to their owners. Gone for good: never stealable again.
var returned_bubble_ids: Array[StringName] = []
## The reveal has played (the Shadow is the Artist's hand). Until then no word
## can be given back.
var twist_revealed: bool = false

var stolen_bubble_count: int = 0
var comic_damage: float = 0.0
var shown_damage: float = 0.0 ## What the visuals show; eases toward comic_damage.


func reset() -> void:
	inventory.clear()
	flags.clear()
	stolen_bubble_ids.clear()
	returned_bubble_ids.clear()
	selected_index = -1
	stolen_bubble_count = 0
	comic_damage = 0.0
	shown_damage = 0.0
	twist_revealed = false
	current_frame_id = &""
	modal_open = false
	EventBus.game_reset.emit()
	EventBus.bubble_selected.emit(-1)
	EventBus.comic_damage_changed.emit(0.0)


func _process(delta: float) -> void:
	if shown_damage != comic_damage:
		shown_damage = move_toward(shown_damage, comic_damage, delta * DAMAGE_EASE)
		EventBus.comic_damage_changed.emit(shown_damage)


## Jumps the shown damage to the real value (loading, restarting).
func snap_damage() -> void:
	shown_damage = comic_damage
	EventBus.comic_damage_changed.emit(shown_damage)


func set_flag(flag: StringName, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: StringName) -> bool:
	return flags.get(flag, false)


## 0..1 strength of the comic-damage effects (eased).
func damage_ratio() -> float:
	return clampf(shown_damage / DAMAGE_FOR_FULL_EFFECT, 0.0, 1.0)


## What the visuals use: damage scaled up a little in later chapters.
func damage_visual() -> float:
	var scale: float = current_chapter.damage_visual_scale if current_chapter != null else 1.0
	return clampf(damage_ratio() * scale, 0.0, 1.0)


func is_bubble_stolen(bubble_id: StringName) -> bool:
	return stolen_bubble_ids.has(bubble_id)


func is_bubble_returned(bubble_id: StringName) -> bool:
	return returned_bubble_ids.has(bubble_id)


## True once words may be given back: the twist has played, in a chapter
## that allows it.
func can_return() -> bool:
	return twist_revealed and current_chapter != null and current_chapter.allows_return


func reveal_twist() -> void:
	twist_revealed = true
	EventBus.twist_revealed.emit()


## FrameData.glitch as it shows now: none once the comic is repaired.
func glitch_of(frame: FrameData) -> float:
	return 0.0 if has_flag(&"comic_repaired") else frame.glitch


## Ordinary (not story_final) stolen words still in the inventory.
func normal_words_held() -> int:
	var count: int = 0
	for bubble in inventory:
		if not bubble.story_final and is_bubble_stolen(bubble.id):
			count += 1
	return count


## 0..1 share of the ordinary words taken that the player still holds (the
## Artist's hand weakens as this falls). 0 when nothing was ever taken.
func held_share() -> float:
	var returned: int = 0
	for id in returned_bubble_ids:
		var bubble: BubbleData = StateSnapshot.load_bubble("res://data/bubbles/%s.tres" % id)
		if bubble != null and not bubble.story_final:
			returned += 1
	var held: int = normal_words_held()
	return float(held) / float(held + returned) if held + returned > 0 else 0.0


## Gives a stolen word back to its owner: out of the inventory, no longer
## stolen, and the comic heals by one step. Returned words are gone for good.
## Does nothing before the twist.
func return_bubble(bubble: BubbleData, screen_pos: Vector2 = Vector2.INF) -> void:
	var index: int = inventory.find(bubble)
	if index < 0 or not can_return():
		return
	inventory.remove_at(index)
	if selected_index == index:
		selected_index = -1
	elif selected_index > index:
		selected_index -= 1
	EventBus.bubble_removed.emit(bubble)
	EventBus.bubble_selected.emit(selected_index)
	_mark_returned(bubble, screen_pos)
	if bubble.story_final:
		set_flag(&"comic_repaired")
		EventBus.comic_repaired.emit()


## Fallback so no owner stays broken forever: a word marked stolen that is no
## longer in the inventory (lost with a renamed file, say) goes home by itself.
func restore_lost_word(bubble: BubbleData) -> void:
	if inventory.has(bubble) or not is_bubble_stolen(bubble.id):
		return
	_mark_returned(bubble, Vector2.INF)


func _mark_returned(bubble: BubbleData, screen_pos: Vector2) -> void:
	stolen_bubble_ids.erase(bubble.id)
	if not returned_bubble_ids.has(bubble.id):
		returned_bubble_ids.append(bubble.id)
	stolen_bubble_count = maxi(0, stolen_bubble_count - 1)
	comic_damage = maxf(0.0, comic_damage - 1.0)
	EventBus.bubble_returned.emit(bubble, screen_pos)


func stolen_from_count(character_id: StringName) -> int:
	var count: int = 0
	for bubble in inventory:
		if bubble.stolen_from == character_id:
			count += 1
	return count


## `from_screen_pos` is where the bubble was taken, for the fly-in animation.
func add_bubble(bubble: BubbleData, from_screen_pos: Vector2 = Vector2.INF) -> void:
	inventory.append(bubble)
	stolen_bubble_ids.append(bubble.id)
	stolen_bubble_count += 1
	comic_damage += 1.0
	EventBus.bubble_stolen.emit(bubble, from_screen_pos)
	if selected_index < 0:
		select(inventory.size() - 1)


## Drops a spoken consumable word.
func remove_bubble(bubble: BubbleData) -> void:
	var index: int = inventory.find(bubble)
	if index < 0:
		return
	inventory.remove_at(index)
	EventBus.bubble_removed.emit(bubble)
	if selected_index == index:
		select(-1)
	elif selected_index > index:
		selected_index -= 1
		EventBus.bubble_selected.emit(selected_index)


## Selects an inventory entry. With `toggle`, picking the selected one
## again clears the selection. The inventory has no size cap.
func select(index: int, toggle: bool = true) -> void:
	if index < 0 or index >= inventory.size() or (toggle and index == selected_index):
		index = -1
	selected_index = index
	EventBus.bubble_selected.emit(index)


## Moves the selection by `step`, wrapping around (Q / R / mouse wheel).
func cycle(step: int) -> void:
	if inventory.is_empty():
		return
	var start: int = selected_index if selected_index >= 0 else (0 if step > 0 else 1)
	select(posmod(start + step, inventory.size()), false)


func selected_bubble() -> BubbleData:
	if selected_index < 0 or selected_index >= inventory.size():
		return null
	return inventory[selected_index]


func checkpoint() -> void:
	SaveSystem.save_game(to_dict())


func to_dict() -> Dictionary:
	return StateSnapshot.build(self)


## Restores a to_dict() snapshot. Returns false if it does not look valid.
func from_dict(snapshot: Dictionary) -> bool:
	if not snapshot.has("frame") or String(snapshot["frame"]) == "":
		return false
	reset()
	StateSnapshot.apply(self, snapshot)
	selected_index = clampi(selected_index, -1, inventory.size() - 1)
	EventBus.bubble_selected.emit(selected_index)
	snap_damage()
	return true
