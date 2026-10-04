class_name StateSnapshot
extends RefCounted
## Turns GameState into a plain Dictionary (JSON-safe, for saves and the
## Restart Chapter snapshot) and back.

const FRAME_PATH: String = "res://data/frames/%s.tres"


static func build(gs: Node) -> Dictionary:
	var paths: PackedStringArray = PackedStringArray()
	for bubble in gs.inventory:
		paths.append(bubble.resource_path)
	var flag_names: PackedStringArray = PackedStringArray()
	for flag in gs.flags:
		if gs.flags[flag]:
			flag_names.append(String(flag))
	var chapter: ChapterData = gs.current_chapter
	return {
		"frame": String(gs.current_frame_id),
		"inventory": paths,
		"selected": gs.selected_index,
		"flags": flag_names,
		"stolen_ids": _strings(gs.stolen_bubble_ids),
		"returned_ids": _strings(gs.returned_bubble_ids),
		"seen": _strings(gs.seen),
		"stolen_count": gs.stolen_bubble_count,
		"damage": gs.comic_damage,
		"twist_revealed": gs.twist_revealed,
		"chapter": chapter.resource_path if chapter != null else "",
		"chapter_start": gs.chapter_start,
	}


## Fills a freshly reset GameState from `snapshot`.
static func apply(gs: Node, snapshot: Dictionary) -> void:
	for path in snapshot.get("inventory", []):
		var bubble: BubbleData = load_bubble(String(path))
		if bubble != null:
			gs.inventory.append(bubble)
	for flag in snapshot.get("flags", []):
		gs.flags[StringName(flag)] = true
	# A word only counts as stolen if it actually came back into the
	# inventory: if its file went missing, its owner gets it back instead of
	# being stuck without it forever.
	for id in snapshot.get("stolen_ids", []):
		var stolen_id: StringName = StringName(id)
		for bubble in gs.inventory:
			if bubble.id == stolen_id:
				gs.stolen_bubble_ids.append(stolen_id)
				break
	for id in snapshot.get("returned_ids", []):
		gs.returned_bubble_ids.append(StringName(id))
	for id in snapshot.get("seen", []):
		gs.seen.append(StringName(id))
	gs.stolen_bubble_count = int(snapshot.get("stolen_count", gs.inventory.size()))
	gs.comic_damage = float(snapshot.get("damage", 0.0))
	gs.twist_revealed = bool(snapshot.get("twist_revealed", false))
	var chapter_path: String = String(snapshot.get("chapter", ""))
	if chapter_path != "" and ResourceLoader.exists(chapter_path):
		gs.current_chapter = load(chapter_path) as ChapterData
	var start: Variant = snapshot.get("chapter_start", {})
	gs.chapter_start = start if typeof(start) == TYPE_DICTIONARY else {}
	gs.selected_index = int(snapshot.get("selected", -1))
	gs.current_frame_id = StringName(snapshot["frame"])
	# A frame that no longer exists (renamed or cut) falls back to the start
	# of its chapter, or of the return phase if the twist is already known,
	# instead of leaving the player on a blank page.
	if not ResourceLoader.exists(FRAME_PATH % gs.current_frame_id) and gs.current_chapter != null:
		var back: StringName = gs.current_chapter.first_frame_id
		if gs.twist_revealed and gs.current_chapter.return_frame_id != &"":
			back = gs.current_chapter.return_frame_id
		gs.current_frame_id = back


## Loads a saved word; if its file moved, tries data/bubbles/<id>.tres
## (word files are named after their id).
static func load_bubble(path: String) -> BubbleData:
	if ResourceLoader.exists(path):
		return load(path) as BubbleData
	var fallback: String = "res://data/bubbles/%s" % path.get_file()
	if ResourceLoader.exists(fallback):
		return load(fallback) as BubbleData
	push_warning("GameState: saved word %s is missing; its owner keeps it" % path)
	return null


static func _strings(ids: Array[StringName]) -> Array:
	return ids.map(func(id: StringName) -> String: return String(id))
