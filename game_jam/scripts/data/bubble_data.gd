class_name BubbleData
extends Resource
## A stealable speech bubble.

@export var id: StringName
@export var text: String = ""
## Key into AbilityRegistry, e.g. &"open".
@export var ability_id: StringName
@export var stolen_from: StringName
## Used up when spoken successfully. Off by default so no word can be lost
## in a way that soft-locks a puzzle.
@export var consumable: bool = false
## Who it is given back to, for prompts ("give back to Arthur").
@export var owner_name: String = ""
## The last word of the story (ERASE): stealing it plays the reveal, and
## giving it back repairs the comic.
@export var story_final: bool = false
