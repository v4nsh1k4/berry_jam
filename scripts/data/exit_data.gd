class_name ExitData
extends Resource
## A walk-through area that leads to another frame.

enum TransitionStyle { SLIDE, INK_SPLASH }

@export var area: Rect2 = Rect2(1120, 390, 64, 110)
@export var target_frame_id: StringName
## Panel-coordinate spawn in the target frame; Vector2.INF uses its default.
@export var target_spawn: Vector2 = Vector2.INF
@export var transition_style: TransitionStyle = TransitionStyle.SLIDE
## Exit stays closed until this flag is set (empty = always open).
@export var required_flag: StringName = &""
