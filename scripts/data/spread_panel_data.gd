class_name SpreadPanelData
extends Resource
## One small panel of a PageSpreadData page. Coordinates are frame (panel)
## coordinates, like everything else in FrameData; the frame's interactables
## and characters belong to whichever panel contains them.

@export var id: StringName
@export var rect: Rect2
## Degrees the panel's drawing is knocked askew (visual only).
@export var tilt: float = 0.0
## 0..1 how lit this panel is on its own (0 = dark: only the torch shows it).
@export_range(0.0, 1.0) var ambient: float = 0.6
## SpreadArt drawing: gallery, dark_room, torn, door_room.
@export var style: StringName = &"gallery"
## Where the feet stand (y, frame coords).
@export var floor_y: float = 0.0
## Where the gutter spits the player back after a fall.
@export var entry: Vector2
## X range (frame coords) of a tear in the floor that drops into the gutter;
## Vector2.ZERO = none. Jump over it, or bridge it.
@export var gap: Vector2 = Vector2.ZERO
## This flag fills the tear for good (e.g. a crate pushed into it).
@export var gap_bridge_flag: StringName = &""
## A pencil-sketched plank spans the tear, solid only while the torch is on it.
@export var gap_lit_bridge: bool = false
