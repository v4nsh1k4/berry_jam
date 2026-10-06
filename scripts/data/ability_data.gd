class_name AbilityData
extends Resource
## What a stolen word does. AbilityRegistry instantiates `handler` once.

enum TargetType {
	## Must be spoken at an Interactable that lists this ability.
	INTERACTABLE,
	## Spoken into the room; works without a target (HUSH, REMEMBER).
	ROOM,
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## The word as it appears in tooltips.
@export var icon_word: String = ""
@export var target_type: TargetType = TargetType.INTERACTABLE
## Seconds before the word can be spoken again (0 = none).
@export var cooldown: float = 0.0
## How long the effect lasts, for abilities that have one.
@export var duration: float = 0.0
## Script extending AbilityHandler.
@export var handler: Script
