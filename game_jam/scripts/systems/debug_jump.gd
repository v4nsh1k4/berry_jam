class_name DebugJump
extends RefCounted
## Debug builds only: jump straight to a room for testing.
## Web: add ?frame=<frame_id> to the page URL (e.g. ?frame=ch3_margin), and
## optionally &words=arthur_open,vane_hide and &twist=1.
## Desktop: run with  -- --frame=<frame_id> [--words=a,b] [--twist=1]
## In game: F9 jumps to the next Chapter 3 room (see main.gd).
## The chapter is taken from the id's prefix (ch1_/ch2_/ch3_), and the words a
## player would normally carry there are added. Return-phase rooms also get
## ERASE and twist_revealed. Release builds ignore all of this.

const CARRIED: Dictionary = {
	"ch1": [],
	"ch2": ["arthur_open", "arthur_push", "portrait_remember"],
	"ch3": ["arthur_open", "arthur_push", "arthur_help", "portrait_remember", "vane_hide", "vane_hush", "vane_wait"],
}
## Chapter 3 in story order, for F9.
const CH3_ROOMS: PackedStringArray = [
	"ch3_torn_page", "ch3_gallery_words", "ch3_margin", "ch3_ink_heart",
	"ch3_returning_room", "ch3_torn_return", "ch3_gallery_return", "ch3_heart_return", "ch3_escape",
]
## Rooms after the reveal.
const RETURN_PHASE: PackedStringArray = [
	"ch3_returning_room", "ch3_torn_return", "ch3_gallery_return", "ch3_heart_return", "ch3_escape",
]
const FINAL_WORD: String = "hand_erase"


## The requested frame id, or "" when not debugging / not asked.
static func requested_frame() -> String:
	return _arg("frame")


## A debug option from the URL (web) or the command line (desktop).
static func _arg(key: String) -> String:
	if not OS.is_debug_build():
		return ""
	if OS.has_feature("web"):
		var js: String = "new URLSearchParams(location.search).get('%s') || ''" % key
		var query: Variant = JavaScriptBridge.eval(js, true)
		return String(query) if query != null else ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % key):
			return arg.trim_prefix("--%s=" % key)
	return ""


## The Chapter 3 room after `frame_id` (wraps round; anything else starts
## at the first).
static func next_room(frame_id: String) -> String:
	var index: int = CH3_ROOMS.find(frame_id)
	return CH3_ROOMS[(index + 1) % CH3_ROOMS.size()]


## Sets GameState up as if the player had played up to `frame_id`.
static func prepare(frame_id: String) -> ChapterData:
	var chapter_id: String = frame_id.get_slice("_", 0)
	var path: String = "res://data/chapters/%s.tres" % chapter_id
	if not CARRIED.has(chapter_id) or not ResourceLoader.exists(path):
		return null
	GameState.reset()
	var after_reveal: bool = RETURN_PHASE.has(frame_id)
	var twist: String = _arg("twist")
	if twist != "":
		after_reveal = twist == "1"
	var words: Array = CARRIED[chapter_id].duplicate()
	var asked: String = _arg("words")
	if asked != "":
		words = Array(asked.split(",", false))
	if after_reveal and not words.has(FINAL_WORD):
		words.append(FINAL_WORD)
	# Before the words go in: holding ERASE without the twist plays the reveal.
	GameState.twist_revealed = after_reveal
	for word in words:
		var bubble_path: String = "res://data/bubbles/%s.tres" % word
		if ResourceLoader.exists(bubble_path):
			GameState.add_bubble(load(bubble_path))
	if chapter_id != "ch1":
		GameState.set_flag(&"has_flashlight")
	GameState.snap_damage()
	return load(path) as ChapterData
