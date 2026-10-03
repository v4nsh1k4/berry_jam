class_name ChapterData
extends Resource
## A chapter: its title, the intro captions and where it starts.

@export var id: StringName
@export var title: String = ""
## Shown one at a time before the first frame.
@export var intro_lines: PackedStringArray = PackedStringArray()
@export var first_frame_id: StringName
## How strongly comic damage shows in this chapter (Ch. 2 is shakier).
@export var damage_visual_scale: float = 1.0
## Line wobble multiplier: the drawing quality slips as the story goes on.
@export var line_jitter: float = 1.0
