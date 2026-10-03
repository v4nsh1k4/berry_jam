class_name SaveSystem
extends RefCounted
## One save slot in user:// (IndexedDB on the web). Every call fails soft:
## a missing or broken file just means "no save".

const SAVE_PATH: String = "user://ink_bleed_save.json"
const VERSION: int = 1


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
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return {}
	return parsed


static func clear() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
