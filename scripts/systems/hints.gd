class_name Hints
extends RefCounted
## One-time tutorial hints: each id shows once per install (remembered in
## user://progress.cfg, so a new game doesn't repeat them). Stage 6b: shown
## at the bottom right of the panel (PageOverlay), queued, never overlapping.


## `urgent` (safety hints: the light, the meter, running) goes ahead of the
## queue and pre-empts a running tip, which comes back after it.
static func once(id: String, text: String, duration: float = 4.0, urgent: bool = false) -> void:
	if SaveSystem.get_progress("hint_" + id):
		return
	SaveSystem.set_progress("hint_" + id)
	EventBus.hint_requested.emit(text, duration, urgent)
