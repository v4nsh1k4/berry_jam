extends AbilityHandler
## PUSH: shoves heavy furniture one step along its push_offset.


func execute(_bubble: BubbleData, target: Interactable, _tree: SceneTree) -> bool:
	target.push()
	return true
