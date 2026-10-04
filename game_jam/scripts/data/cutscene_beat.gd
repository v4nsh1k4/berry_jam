class_name CutsceneBeat
extends Resource
## One beat of a cutscene: 1-4 mini panels on a page, a caption and a move.

@export var duration: float = 3.0
## Panel rects as fractions of the page's drawing area (0..1).
@export var panels: Array[Rect2] = []
## What each panel draws (a CutsceneArt id), one per panel.
@export var draws: PackedStringArray = PackedStringArray()
@export_multiline var caption: String = ""
## still, zoom_in, zoom_out, pan_left, pan_right, shake.
@export var camera: StringName = &"still"
## Sound played when the beat starts (an AudioManager sound id).
@export var sfx: StringName = &""
## A page turns over at the start of this beat.
@export var page_turn: bool = false
