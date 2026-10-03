class_name FrameData
extends Resource
## One comic panel. Positions are in panel coordinates (0,0 = panel top-left,
## size = Frame.PANEL_RECT.size).

@export var id: StringName
@export var display_name: String = ""
@export_range(0.0, 1.0) var ambient_light: float = 0.08
## Picks the procedural drawing in FrameBackground.
@export var background_style: StringName = &"plain"
@export var player_spawn: Vector2 = Vector2(200, 460)
## Where the player's feet may go (the floor band of the side view).
@export var walk_area: Rect2 = Rect2(40, 390, 1104, 110)
## Caption boxes shown on the panel (narration and tutorial hints).
@export var captions: PackedStringArray = PackedStringArray()
@export var exits: Array[ExitData] = []
@export var interactables: Array[InteractableData] = []
@export var npcs: Array[NpcData] = []
## Where the Ink Crawler lies dormant; Vector2.INF = no Crawler here.
@export var crawler_spawn: Vector2 = Vector2.INF
## The Crawler walks the room instead of lying dormant.
@export var crawler_patrol: bool = false
## Fixed candle / moon lights.
@export var lights: Array[LightSpotData] = []
## Scripted moments (ids in Frame.EVENT_SCRIPTS), each plays once.
@export var events: Array[StringName] = []
## What the HELP word tells the player here.
@export_multiline var hint: String = ""
## Non-empty: this frame ends the chapter and shows this card.
@export var ending_card: String = ""
## 0..1 how broken this panel is (Chapter 3): glitch tears, missing border,
## a misregistered ghost panel, ink dripping into the gutter, coarse halftone.
## The glitch calms as the player returns words.
@export_range(0.0, 1.0) var glitch: float = 0.0
## Degrees the whole panel is knocked askew.
@export var panel_tilt: float = 0.0
## 0..1 share of the background left as unfinished sketch (missing strokes).
@export_range(0.0, 1.0) var sketch: float = 0.0
## Which enemy sits at crawler_spawn: &"crawler", &"shadow" (Ink Shadow) or
## &"heart" (the Shadow guarding the last word in the Ink Heart).
@export var crawler_kind: StringName = &"crawler"
## Non-null: arriving here ends the chapter and starts this one (intro first).
@export var next_chapter: ChapterData
## Once the comic is repaired, a gap opens in the right border showing the
## lit real-world page (the way out).
@export var border_gap: bool = false
## Arriving here plays the epilogue before the ending card.
@export var epilogue: bool = false
