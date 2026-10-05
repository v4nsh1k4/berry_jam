class_name Hints
extends RefCounted
## One-time tutorial hints: each id shows once per install (remembered in
## user://progress.cfg, so a new game doesn't repeat them).


static func once(id: String, text: String, duration: float = 4.0) -> void:
	if SaveSystem.get_progress("hint_" + id):
		return
	SaveSystem.set_progress("hint_" + id)
	EventBus.caption_requested.emit(text, duration)
