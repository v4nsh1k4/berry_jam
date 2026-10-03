extends AbilityHandler
## HUSH: the Ink Crawler loses track of the player for `duration` seconds.


func execute(_bubble: BubbleData, _target: Interactable, _tree: SceneTree) -> bool:
	EventBus.crawler_hushed.emit(ability.duration)
	return true
