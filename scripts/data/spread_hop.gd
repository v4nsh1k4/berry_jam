class_name SpreadHop
extends Resource
## A way from one spread panel to another, across the gutter.
##   right / left  walk off that edge of the panel (inside zone_x)
##   jump          press jump (Space) while standing in zone_x
##   fall          walk onto zone_x (a tear in the floor that drops you through)
##   down          press down (S) at the front of the floor in zone_x

@export var from_panel: StringName
@export var trigger: StringName = &"right"
## X range (frame coords) the feet must be in; Vector2.ZERO = anywhere.
@export var zone_x: Vector2 = Vector2.ZERO
@export var to_panel: StringName
## Where the feet land (frame coords).
@export var to_point: Vector2
@export var requires_flag: StringName = &""
@export var locked_caption: String = ""
