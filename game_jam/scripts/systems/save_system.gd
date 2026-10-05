class_name SaveSystem
extends RefCounted
## One save slot in user:// (IndexedDB on the web). Every call fails soft:
## a missing or broken file just means "no save".
## Version 2 (Stage 4B) adds twist_revealed and reorders Chapter 3. Version 3
## (Stage 4C) cuts and merges rooms and adds seen cutscenes; older saves are
## migrated by migrate().

const SAVE_PATH: String = "user://ink_bleed_save.json"
const VERSION: int = 4
## Survives new games: things the player has already seen (the reveal can be
## skipped on later viewings) and whether they finished the game.
const PROGRESS_PATH: String = "user://progress.cfg"


static func save_game(snapshot: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var data: Dictionary = snapshot.duplicate()
	data["version"] = VERSION
	file.store_string(JSON.stringify(data))
	file.close()
	return true


static func has_save() -> bool:
	return not load_game().is_empty()


static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return migrate(parsed)


## Brings an older save up to VERSION, or returns {} (no save) when it can't
## be used safely. Unknown future versions are ignored too.
static func migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("version", 0))
	if version == VERSION:
		return data
	if version == 3:
		return _migrate_v3(data)
	if version == 2:
		return _migrate_v2(data)
	if version != 1:
		return {}
	# Version 1 (Stage 4A) let words be given back before the reveal, and its
	# Chapter 3 rooms are in a different order. Chapters 1-2 carry over as
	# they are; a save inside Chapter 3 goes back to the start of Chapter 3
	# (its chapter_start snapshot), so the reveal is never skipped.
	var migrated: Dictionary = data
	if String(data.get("chapter", "")).ends_with("/ch3.tres"):
		var start: Variant = data.get("chapter_start", {})
		if typeof(start) != TYPE_DICTIONARY or not (start as Dictionary).has("frame"):
			return {}
		migrated = (start as Dictionary).duplicate(true)
		migrated["chapter_start"] = (start as Dictionary).duplicate(true)
	migrated["twist_revealed"] = false
	migrated["returned_ids"] = []
	migrated["version"] = 2
	return _migrate_v2(migrated)


## Version 2 -> 3 (Stage 4C). The Torn Page, the Torn Page revisit and the
## Gallery revisit were cut (rooms that no longer exist fall back safely in
## StateSnapshot.apply), and cutscenes now remember being seen. Nothing else
## changed shape, so the save carries over as it is.
static func _migrate_v2(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	if not migrated.has("seen"):
		migrated["seen"] = []
	return _migrate_v3(migrated)


## v3 -> v4 (Stage 4D): reading the Clock Room's face used to open its door
## (flag clock_read); now the dial box does (clock_solved). A save past the
## clock keeps its open door. (Hints and scares need nothing: the first is
## remembered in progress.cfg, the second simply hasn't fired yet.)
static func _migrate_v3(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	for snapshot in [migrated, migrated.get("chapter_start", {})]:
		if typeof(snapshot) != TYPE_DICTIONARY:
			continue
		var flags: Array = (snapshot as Dictionary).get("flags", [])
		if flags.has("clock_read") and not flags.has("clock_solved"):
			flags.append("clock_solved")
	migrated["version"] = VERSION
	return migrated


static func clear() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


static func get_progress(key: String) -> bool:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PROGRESS_PATH) != OK:
		return false
	return bool(config.get_value("progress", key, false))


static func set_progress(key: String) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PROGRESS_PATH)
	config.set_value("progress", key, true)
	config.save(PROGRESS_PATH)
