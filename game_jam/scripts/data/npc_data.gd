class_name NpcData
extends Resource
## A comic character standing in a frame, optionally holding a bubble.

@export var id: StringName
@export var display_name: String = ""
@export var position: Vector2
@export var visual_style: StringName = &"generic"
## Bubbles the character speaks, in order. Each can be stolen.
@export var bubbles: Array[BubbleData] = []
## Full line per bubble; "{word}" marks the stealable word. Empty = word only.
@export var lines: PackedStringArray = PackedStringArray()
## What is left of each line once its word is stolen (stutters, gaps).
@export var broken_lines: PackedStringArray = PackedStringArray()
## Caption when the player comes close after a theft, by number stolen (1st, 2nd...).
@export var reactions: PackedStringArray = PackedStringArray()
## Custom bubble positions relative to the NPC (empty = defaults).
@export var bubble_offsets: PackedVector2Array = PackedVector2Array()
## Captions when a word is given back, by number returned (1st, 2nd...).
@export var relief_lines: PackedStringArray = PackedStringArray()
## False: words this character still has can't be taken (Chapter 3).
@export var words_stealable: bool = true
## Captions while they are missing words and nothing can be given back yet
## (Chapter 3 before the reveal), one per approach, in turn.
@export var plea_lines: PackedStringArray = PackedStringArray()
@export var scale: float = 1.0
## Pushes the reach point down to the floor for NPCs on the wall (portraits).
@export var reach_y: float = 0.0
