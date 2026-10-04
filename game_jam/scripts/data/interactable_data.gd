class_name InteractableData
extends Resource
## Something in a frame that stolen words act on (door, drawer, cabinet), or
## a hidden memory sketch that REMEMBER reveals.

@export var id: StringName
## Word targets: door, drawer, latch, pushable. Plain E: inspect, pickup,
## symbol_lock, hiding_spot. Not targetable: memory, writing, clock,
## secret_door. Picks behaviour and drawing.
@export var kind: StringName = &"door"
@export var position: Vector2
@export var size: Vector2 = Vector2(90, 220)
## Ability ids this object reacts to, e.g. [&"open"].
@export var accepted_ability_ids: Array[StringName] = []
## Flag set in GameState once resolved (exits can wait on it).
@export var sets_flag: StringName = &""
## Only usable / revealable once this flag is set (e.g. memory behind a cabinet).
@export var requires_flag: StringName = &""
## PUSH moves the object by this much.
@export var push_offset: Vector2 = Vector2(-150, 0)
## Symbols drawn by a memory sketch (or a lock's answer), e.g. ["moon", "eye", "key"].
@export var symbols: PackedStringArray = PackedStringArray()
## Only visible (and usable) while the flashlight cone covers it.
@export var revealed_by_light: bool = false
## return_spot: whose words this takes back (BubbleData.stolen_from).
@export var owner_id: StringName = &""
## Words for `writing`; the look for `hiding_spot` (wardrobe, curtain, table)
## and `symbol_lock` ("panel" = small wall box instead of a door).
@export var text: String = ""
@export var prompt: String = ""
## Caption shown on inspect / pickup.
@export_multiline var caption: String = ""
## A bubble found inside when this is opened (e.g. a word in a drawer).
@export var reward_bubble: BubbleData

## Light puzzles (LightPuzzle): seconds the cone must stay on it (light_ink,
## lens, shadow_puzzle). light_ink `text` picks the look: door, pool, growth
## (growth creeps back in the dark).
@export var light_hold: float = 1.5
## shadow_puzzle: where the player must stand (panel coords) for the object's
## shadow to fall into the shape on the wall.
@export var stand_spot: Rect2 = Rect2()
