extends AbilityHandler
## REMEMBER: shows every reachable memory sketch in the frame for a while.
## Fails (the "?" reaction) if there is nothing to remember here yet.


func execute(_bubble: BubbleData, _target: Interactable, tree: SceneTree) -> bool:
	var shown: bool = false
	for node in tree.get_nodes_in_group(&"memory"):
		var memory: Interactable = node as Interactable
		if memory.can_remember():
			memory.reveal_memory(ability.duration)
			shown = true
	return shown
