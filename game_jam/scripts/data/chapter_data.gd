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
## Stolen words can be given back to their owners in this chapter, once the
## twist has been revealed. Off in Chapters 1-2 so a needed word (OPEN) can't
## be returned too early.
@export var allows_return: bool = false
## Where the player lands after the reveal (the return phase starts here).
@export var return_frame_id: StringName = &""
