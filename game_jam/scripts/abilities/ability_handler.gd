class_name AbilityHandler
extends RefCounted
## Base for word abilities. One small script per ability; the registry keeps
## one instance per AbilityData. `target` is the Interactable in reach, or
## null when the word is spoken into the room.

var ability: AbilityData


func execute(_bubble: BubbleData, _target: Interactable, _tree: SceneTree) -> bool:
	return false
