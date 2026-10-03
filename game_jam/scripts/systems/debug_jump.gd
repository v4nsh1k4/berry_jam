class_name DebugJump
extends RefCounted
## Debug builds only: jump straight to a room for testing.
## Web: add ?frame=<frame_id> to the page URL (e.g. ?frame=ch3_margin).
## Desktop: run with  -- --frame=<frame_id>
## The chapter is taken from the id's prefix (ch1_/ch2_/ch3_), and the words a
## player would normally carry into that chapter are added. Release builds
## ignore all of this.

const CARRIED: Dictionary = {
	"ch1": [],
	"ch2": ["arthur_open", "arthur_push", "portrait_remember"],
	"ch3": ["arthur_open", "arthur_push", "arthur_help", "portrait_remember", "vane_hide", "vane_hush", "vane_wait"],
}


## The requested frame id, or "" when not debugging / not asked.
static func requested_frame() -> String:
	if not OS.is_debug_build():
		return ""
	if OS.has_feature("web"):
		var query: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('frame') || ''", true)
		return String(query) if query != null else ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frame="):
			return arg.trim_prefix("--frame=")
	return ""


## Sets GameState up as if the player had played up to `frame_id`'s chapter.
static func prepare(frame_id: String) -> ChapterData:
	var chapter_id: String = frame_id.get_slice("_", 0)
	var path: String = "res://data/chapters/%s.tres" % chapter_id
	if not CARRIED.has(chapter_id) or not ResourceLoader.exists(path):
		return null
	GameState.reset()
	for word in CARRIED[chapter_id]:
		GameState.add_bubble(load("res://data/bubbles/%s.tres" % word))
	if chapter_id != "ch1":
		GameState.set_flag(&"has_flashlight")
	return load(path) as ChapterData
