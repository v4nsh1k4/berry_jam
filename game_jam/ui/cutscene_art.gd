class_name CutsceneArt
extends RefCounted
## Drawings for cutscene panels (CutsceneBeat.draws ids). Each draws in
## panel space (0..size) under the camera view set by CutsceneView; `t` is
## seconds into the beat, for small motions. C3's ids live here, C5/C6's in
## CutsceneArt2, C1's c1_* ids in CutsceneArt5, the first-person pov_* ids
## (C2, C4) in CutsceneArt3/4,
## extra detail in CutsceneDetail. The player is always the red figure.

const DARK: Color = Color(0.1, 0.095, 0.11)
const GREY: Color = Color(0.62, 0.6, 0.57)


static func draw(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	if CutsceneArt3.is_pov(id):
		CutsceneArt3.draw(ci, id, s, t, tick)
		return
	if id.begins_with("c1_"):
		CutsceneArt5.draw(ci, id, s, t, tick)
		return
	match id:
		"story_tea":
			_story_tea(ci, s, t, tick)
		"story_family":
			_story_family(ci, s, t, tick)
		"story_door":
			_story_door(ci, s, t, tick)
		"story_gap":
			_story_gap(ci, s, t, tick)
		_:
			CutsceneArt2.draw(ci, id, s, t, tick)


## Scale unit: a 300-unit-tall panel is 1.0.
static func unit(s: Vector2) -> float:
	return minf(s.x * 0.75, s.y) / 300.0


## Draws with a local transform (at, scale) inside the current camera view.
static func place(ci: CanvasItem, at: Vector2, sc: float) -> void:
	ci.draw_set_transform_matrix(RevealArt._current * Transform2D(0.0, Vector2(sc, sc), 0.0, at))


static func unplace(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(RevealArt._current)


static func text(ci: CanvasItem, at: Vector2, words: String, size: int, color: Color = InkDraw.INK) -> void:
	var font: Font = ThemeDB.fallback_font
	var w: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, at - Vector2(w * 0.5, 0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func floor_line(ci: CanvasItem, s: Vector2, y: float, tick: int) -> void:
	InkDraw.line(ci, Vector2(-20, y), Vector2(s.x + 20, y + 4), 4.0, tick)


## C3: Mrs. Vane pouring tea, before.
static func _story_tea(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	_sepia(ci, s)
	floor_line(ci, s, s.y * 0.84, tick)
	var table: Rect2 = Rect2(s.x * 0.5, s.y * 0.58, 150 * u, 12 * u)
	InkDraw.rect(ci, table, 3.0, tick + 1, InkDraw.PAPER)
	InkDraw.line(ci, table.position + Vector2(10, 12) * u, Vector2(table.position.x + 10 * u, s.y * 0.84), 3.0, tick + 2)
	InkDraw.line(ci, table.end + Vector2(-10, 0) * u, Vector2(table.end.x - 10 * u, s.y * 0.84), 3.0, tick + 3)
	InkDraw.ellipse(ci, table.position + Vector2(50, -22) * u, Vector2(22, 18) * u, 3.0, tick + 4, InkDraw.WHITE)
	InkDraw.ellipse(ci, table.position + Vector2(110, -10) * u, Vector2(12, 8) * u, 2.5, tick + 5, InkDraw.WHITE)
	for i in 3:
		var x: float = table.position.x + (100 + i * 8) * u
		var y0: float = table.position.y - 24 * u - fmod(t * 14.0 + i * 9.0, 30.0) * u
		InkDraw.line(ci, Vector2(x, y0), Vector2(x + 4 * u, y0 - 14 * u), 2.0, tick + 6 + i, GREY)
	RevealArt._character(ci, &"housekeeper", Vector2(s.x * 0.32, s.y * 0.84), u * 1.15, tick)


## C3: the household together in a portrait, the way the book began.
static func _story_family(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	_sepia(ci, s)
	var frame: Rect2 = Rect2(s.x * 0.08, s.y * 0.08, s.x * 0.84, s.y * 0.84)
	InkDraw.rect(ci, frame, 7.0, tick, Color.TRANSPARENT, Color(0.35, 0.3, 0.26))
	var feet_y: float = s.y * 0.86
	RevealArt._character(ci, &"butler", Vector2(s.x * 0.3, feet_y), u * 1.05, tick)
	RevealArt._character(ci, &"housekeeper", Vector2(s.x * 0.7, feet_y), u * 1.05, tick + 1)
	RevealArt._character(ci, &"portrait", Vector2(s.x * 0.5, s.y * 0.48), u * 0.8, tick + 2)
	var smile: float = 0.5 + 0.5 * sin(t * 2.0)
	text(ci, Vector2(s.x * 0.5, s.y * 0.94), "THE HOLLOW HILL HOUSEHOLD", int(14 * u), Color(0.35, 0.3, 0.26, 0.6 + 0.4 * smile))


## C3: the cellar door that always stayed shut.
static func _story_door(ci: CanvasItem, s: Vector2, _t: float, tick: int) -> void:
	var u: float = unit(s)
	_sepia(ci, s)
	floor_line(ci, s, s.y * 0.88, tick)
	var door: Rect2 = Rect2(s.x * 0.5 - 70 * u, s.y * 0.88 - 220 * u, 140 * u, 220 * u)
	InkDraw.rect(ci, door, 5.0, tick + 1, Color(0.42, 0.36, 0.3))
	for i in 3:
		InkDraw.line(ci, door.position + Vector2(10 * u, (40 + i * 60) * u), door.position + Vector2(130 * u, (44 + i * 60) * u), 3.0, tick + 2 + i)
	InkDraw.rect(ci, Rect2(door.get_center() + Vector2(30, -10) * u, Vector2(26, 34) * u), 3.0, tick + 6, Color(0.6, 0.6, 0.6))
	InkDraw.ellipse(ci, door.get_center() + Vector2(43, -16) * u, Vector2(10, 12) * u, 3.0, tick + 7)
	text(ci, Vector2(s.x * 0.5, door.position.y - 14 * u), "NEVER THE CELLAR", int(18 * u))


## C3: the same portrait with a person-shaped hole, red seeping in.
static func _story_gap(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	_sepia(ci, s)
	var feet: Vector2 = Vector2(s.x * 0.5, s.y * 0.88)
	RevealArt._character(ci, &"butler", Vector2(s.x * 0.22, feet.y), u * 1.05, tick)
	RevealArt._character(ci, &"housekeeper", Vector2(s.x * 0.78, feet.y), u * 1.05, tick + 1)
	var outline: PackedVector2Array = PackedVector2Array([feet + Vector2(-26, 0) * u, feet + Vector2(-30, -110) * u,
		feet + Vector2(-20, -150) * u, feet + Vector2(-16, -190) * u, feet + Vector2(16, -190) * u, feet + Vector2(20, -150) * u,
		feet + Vector2(30, -110) * u, feet + Vector2(26, 0) * u])
	InkDraw.fill(ci, outline, InkDraw.WHITE)
	InkDraw.gap_ratio = 0.5
	InkDraw.polyline(ci, outline, 2.0, tick + 3, false, GREY)
	InkDraw.gap_ratio = 0.0
	var seep: float = clampf(t / 3.0, 0.0, 1.0)
	for i in 7:
		var p: Vector2 = feet + Vector2(-22 + i * 7, -4) * u
		InkDraw.line(ci, p, p + Vector2(0, -(30 + (i * 37) % 60) * seep) * u, 4.0 * u, tick + 4 + i, InkDraw.RED, 2.0)


## Old-photo wash for the flashback panels.
static func _sepia(ci: CanvasItem, s: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2(-40, -40), s + Vector2(80, 80)), Color(0.93, 0.88, 0.78))
