extends AbilityHandler
## WAIT: freezes ONE moving thing for `duration` seconds: a risen Crawler if
## there is one (it is the thing that matters), otherwise whatever moving
## thing is nearest (a pendulum...). "?" if nothing here moves.


func execute(_bubble: BubbleData, _target: Interactable, tree: SceneTree) -> bool:
	var player: Node2D = tree.get_first_node_in_group(&"player") as Node2D
	if player == null:
		return false
	var best: Node2D = null
	var best_distance: float = INF
	for node in tree.get_nodes_in_group(&"freezable"):
		var thing: Node2D = node as Node2D
		if not thing.call("can_freeze"):
			continue
		var d: float = player.global_position.distance_to(thing.global_position)
		if thing.is_in_group(&"crawler"):
			d -= 100000.0
		if d < best_distance:
			best = thing
			best_distance = d
	if best == null:
		return false
	best.call("freeze", ability.duration)
	return true
