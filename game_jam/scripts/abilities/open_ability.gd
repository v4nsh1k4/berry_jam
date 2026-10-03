extends AbilityHandler
## OPEN: unlocks doors, drawers and latches.


func execute(_bubble: BubbleData, target: Interactable, _tree: SceneTree) -> bool:
	target.resolve()
	return true
