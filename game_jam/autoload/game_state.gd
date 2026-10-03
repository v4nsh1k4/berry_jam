extends Node
## Run-wide state: inventory, flags and the counters the twist reads. Every
## frame change takes a checkpoint (in memory and to user://).

## Comic damage at full strength = roughly every stealable word in the game:
## Ch. 1 has 6, Ch. 2 has 3, Ch. 3 about 6.
# TODO(later): set to the exact total once Chapter 3's words exist.
const DAMAGE_FOR_FULL_EFFECT: float = 15.0

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

# Chapter 3 twist: stealing bubbles damages the comic.
# TODO(later): the player must return bubbles to escape.
var stolen_bubble_count: int = 0
var comic_damage: float = 0.0


func reset() -> void:
	inventory.clear()
	flags.clear()
	stolen_bubble_ids.clear()
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
		if ResourceLoader.exists(path):
			inventory.append(load(path) as BubbleData)
	for flag in snapshot.get("flags", []):
		flags[StringName(flag)] = true
	for id in snapshot.get("stolen_ids", []):
		stolen_bubble_ids.append(StringName(id))
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
