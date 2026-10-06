class_name CutsceneData
extends Resource
## A short comic-page cutscene between story beats (CutsceneSystem).

@export var id: StringName
## When it plays: "first_steal", "resolved:<interactable id>",
## "frame:<frame id>" or "repaired".
@export var trigger: String = ""
@export var skippable: bool = true
## Music cue while it plays (MusicManager track or stinger id).
@export var music_cue: StringName = &""
@export var beats: Array[CutsceneBeat] = []
