extends Node
## Run-wide state: inventory, flags and the counters the twist reads. Every
## frame change takes a checkpoint (in memory and to user://).

## Comic damage at full strength = every stealable word in the game (100%):
## Chapter 1 has 6 (OPEN, PUSH, WAIT, HELP, REMEMBER, HUSH in the drawer),
## Chapter 2 has 3 (Mrs. Vane), Chapter 3 has none (it is about giving back).
# TODO(later): raise this if Stage 4B adds stealable words.
const DAMAGE_FOR_FULL_EFFECT: float = 9.0

var is_playing: bool = false
## A menu or lock dial is open; the player cannot act.
var modal_open: bool = false
var current_frame_id: StringName = &""
var current_chapter: ChapterData
## Snapshot taken when the current chapter began (Restart Chapter loads it).
var chapter_start: Dictionary = {}
var inventory: Array[BubbleData] = []
var selected_index: int = -1
var flags: Dictionary = {}
var stolen_bubble_ids: Array[StringName] = []
## Words given back to their owners. Gone for good: never stealable again.
var returned_bubble_ids: Array[StringName] = []

# Chapter 3 twist: stealing bubbles damages the comic.
# TODO(later): the player must return bubbles to escape.
var stolen_bubble_count: int = 0
var comic_damage: float = 0.0


func reset() -> void:
	inventory.clear()
	flags.clear()
	stolen_bubble_ids.clear()
	returned_bubble_ids.clear()
	selected_index = -1
	stolen_bubble_count = 0
	comic_damage = 0.0
	current_frame_id = &""
	modal_open = false
	EventBus.game_reset.emit()
	EventBus.bubble_selected.emit(-1)
	EventBus.comic_damage_changed.emit(0.0)


func set_flag(flag: StringName, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: StringName) -> bool:
	return flags.get(flag, false)


## 0..1 strength of the comic-damage foreshadowing.
func damage_ratio() -> float:
	return clampf(comic_damage / DAMAGE_FOR_FULL_EFFECT, 0.0, 1.0)


## What the visuals use: damage scaled up a little in later chapters.
func damage_visual() -> float:
	var scale: float = current_chapter.damage_visual_scale if current_chapter != null else 1.0
	return clampf(damage_ratio() * scale, 0.0, 1.0)


func is_bubble_stolen(bubble_id: StringName) -> bool:
	return stolen_bubble_ids.has(bubble_id)


func is_bubble_returned(bubble_id: StringName) -> bool:
	return returned_bubble_ids.has(bubble_id)


## True if returning words is allowed in the current chapter.
func can_return() -> bool:
	return current_chapter != null and current_chapter.allows_return


## Gives a stolen word back to its owner: out of the inventory, no longer
## stolen, and the comic heals by one step. Returned words are gone for good.
func return_bubble(bubble: BubbleData, screen_pos: Vector2 = Vector2.INF) -> void:
	var index: int = inventory.find(bubble)
	if index < 0:
		return
	inventory.remove_at(index)
	stolen_bubble_ids.erase(bubble.id)
	if not returned_bubble_ids.has(bubble.id):
		returned_bubble_ids.append(bubble.id)
	stolen_bubble_count = maxi(0, stolen_bubble_count - 1)
	comic_damage = maxf(0.0, comic_damage - 1.0)
	if selected_index == index:
		selected_index = -1
	elif selected_index > index:
		selected_index -= 1
	EventBus.bubble_removed.emit(bubble)
	EventBus.bubble_selected.emit(selected_index)
	EventBus.bubble_returned.emit(bubble, screen_pos)
	EventBus.comic_damage_changed.emit(comic_damage)
	# TODO(later): Stage 4B final-word logic. When the last stolen word goes
	# back (inventory empty of stolen words), the Ink Heart climax begins.


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
	EventBus.comic_damage_changed.emit(comic_damage)
	if selected_index < 0:
		select(inventory.size() - 1)


## Drops a spoken consumable bubble from the inventory.
# TODO(later): Chapter 3 return-bubbles mechanic also removes from here.
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


## Loads a saved word; if its file moved, tries data/bubbles/<id>.tres
## (word files are named after their id).
static func _load_bubble(path: String) -> BubbleData:
	if ResourceLoader.exists(path):
		return load(path) as BubbleData
	var fallback: String = "res://data/bubbles/%s" % path.get_file()
	if ResourceLoader.exists(fallback):
		return load(fallback) as BubbleData
	push_warning("GameState: saved word %s is missing; its owner keeps it" % path)
	return null


func checkpoint() -> void:
	SaveSystem.save_game(to_dict())


func to_dict() -> Dictionary:
	var paths: PackedStringArray = PackedStringArray()
	for bubble in inventory:
		paths.append(bubble.resource_path)
	var flag_names: PackedStringArray = PackedStringArray()
	for flag in flags:
		if flags[flag]:
			flag_names.append(String(flag))
	return {
		"frame": String(current_frame_id),
		"inventory": paths,
		"selected": selected_index,
		"flags": flag_names,
		"stolen_ids": stolen_bubble_ids.map(func(id: StringName) -> String: return String(id)),
		"returned_ids": returned_bubble_ids.map(func(id: StringName) -> String: return String(id)),
		"stolen_count": stolen_bubble_count,
		"damage": comic_damage,
		"chapter": current_chapter.resource_path if current_chapter != null else "",
		"chapter_start": chapter_start,
	}


## Restores a to_dict() snapshot. Returns false if it does not look valid.
func from_dict(snapshot: Dictionary) -> bool:
	if not snapshot.has("frame") or String(snapshot["frame"]) == "":
		return false
	reset()
	for path in snapshot.get("inventory", []):
		var bubble: BubbleData = _load_bubble(String(path))
		if bubble != null:
			inventory.append(bubble)
	for flag in snapshot.get("flags", []):
		flags[StringName(flag)] = true
	# A word only counts as stolen if it actually came back into the
	# inventory: if its file went missing, its owner gets it back instead of
	# being stuck without it forever.
	for id in snapshot.get("stolen_ids", []):
		var stolen_id: StringName = StringName(id)
		for bubble in inventory:
			if bubble.id == stolen_id:
				stolen_bubble_ids.append(stolen_id)
				break
	for id in snapshot.get("returned_ids", []):
		returned_bubble_ids.append(StringName(id))
	stolen_bubble_count = int(snapshot.get("stolen_count", inventory.size()))
	comic_damage = float(snapshot.get("damage", 0.0))
	current_frame_id = StringName(snapshot["frame"])
	var chapter_path: String = String(snapshot.get("chapter", ""))
	if chapter_path != "" and ResourceLoader.exists(chapter_path):
		current_chapter = load(chapter_path) as ChapterData
	var start: Variant = snapshot.get("chapter_start", {})
	chapter_start = start if typeof(start) == TYPE_DICTIONARY else {}
	selected_index = clampi(int(snapshot.get("selected", -1)), -1, inventory.size() - 1)
	EventBus.bubble_selected.emit(selected_index)
	EventBus.comic_damage_changed.emit(comic_damage)
	return true
