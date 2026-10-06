extends AbilityHandler
## HELP: the comic itself answers with a hint for the current frame.


func execute(_bubble: BubbleData, _target: Interactable, _tree: SceneTree) -> bool:
	var frame: Frame = FrameManager.current_frame
	if frame == null or frame.data.hint == "":
		return false
	EventBus.caption_requested.emit(frame.data.hint, 6.0)
	return true
