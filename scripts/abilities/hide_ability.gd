extends AbilityHandler
## HIDE: the player's red glow drops to almost nothing for `duration` seconds;
## the Crawler cannot find them, even in light.


func execute(_bubble: BubbleData, _target: Interactable, _tree: SceneTree) -> bool:
	EventBus.player_hide_requested.emit(ability.duration)
	return true
