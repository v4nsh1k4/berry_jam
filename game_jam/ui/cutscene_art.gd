class_name CutsceneArt
extends RefCounted
## Drawings for cutscene panels (CutsceneBeat.draws ids). Each draws in
## panel space (0..size) under the camera view set by CutsceneView; `t` is
## seconds into the beat, for small motions. Chapters 1-2 ids live here,
## the rest in CutsceneArt2. The player is always the red figure.

const DARK: Color = Color(0.1, 0.095, 0.11)
const GREY: Color = Color(0.62, 0.6, 0.57)


static func draw(ci: CanvasItem, id: String, s: Vector2, t: float, tick: int) -> void:
	match id:
		"steal_tear":
			_steal_tear(ci, s, t, tick)
		"pencil_lines":
			_pencil_lines(ci, s, t, tick)
		"torch":
			_torch(ci, s, t, tick)
		"pen_shadow":
			_pen_shadow(ci, s, t, tick)
		"story_tea":
			_story_tea(ci, s, t, tick)
		"story_family":
			_story_family(ci, s, t, tick)
		"story_door":
			_story_door(ci, s, t, tick)
		"story_gap":
			_story_gap(ci, s, t, tick)
		"red_smudge":
			_red_smudge(ci, s, t, tick)
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


## C1: a word coming away from a bubble in red fingers, the bubble torn.
static func _steal_tear(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	var c: Vector2 = Vector2(s.x * 0.36, s.y * 0.42)
	BubbleArt.draw_shell(ci, c, Vector2(220, 110) * u, c + Vector2(-60, 120) * u, tick, 1.0, 4.0 * u)
	# The torn hole where the word was.
	var hole: PackedVector2Array = PackedVector2Array()
	for i in 12:
		var a: float = TAU * i / 12.0
		var r: float = (34.0 + (i % 2) * 14.0) * u
		hole.append(c + Vector2(cos(a) * r * 1.8, sin(a) * r * 0.8))
	InkDraw.fill(ci, hole, Color(0.9, 0.88, 0.82))
	InkDraw.polyline(ci, hole, 2.5 * u, tick + 1, true)
	var pull: float = clampf(t / 1.6, 0.0, 1.0)
	var word_at: Vector2 = c.lerp(Vector2(s.x * 0.74, s.y * 0.5), ease(pull, 0.5))
	place(ci, word_at, u * (1.0 + 0.2 * pull))
	BubbleArt.draw_bold(ci, Vector2(-44, 12), "OPEN", 34, InkDraw.INK)
	unplace(ci)
	# Red fingers pinching it.
	for i in 3:
		var base: Vector2 = word_at + Vector2(60 + i * 8, -20 + i * 18) * u
		InkDraw.line(ci, base + Vector2(70, 10) * u, base, 7.0 * u, tick + 4 + i, InkDraw.RED)
	for i in 5:
		var drop: Vector2 = c.lerp(word_at, (i + 1) / 6.0) + Vector2(0, 12 + fmod(t * 40.0 + i * 13.0, 50.0)) * u
		ci.draw_circle(drop, 3.5 * u, InkDraw.INK)


## C1: the house's lines going thin; Arthur's bubble left empty.
static func _pencil_lines(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	var thin: float = clampf(t / 2.5, 0.0, 1.0)
	InkDraw.gap_ratio = 0.15 + 0.45 * thin
	floor_line(ci, s, s.y * 0.8, tick)
	InkDraw.rect(ci, Rect2(s.x * 0.62, s.y * 0.28, 90 * u, s.y * 0.52), 5.0, tick + 1)
	for i in 5:
		var y: float = s.y * (0.2 + i * 0.12)
		InkDraw.line(ci, Vector2(s.x * 0.06, y), Vector2(s.x * 0.5, y + 6), 2.0, tick + 2 + i, GREY)
	RevealArt._character(ci, &"butler", Vector2(s.x * 0.34, s.y * 0.8), u * 1.1, tick)
	InkDraw.gap_ratio = 0.0
	BubbleArt.draw_shell(ci, Vector2(s.x * 0.22, s.y * 0.18), Vector2(110, 54) * u, Vector2(s.x * 0.32, s.y * 0.3), tick + 9, 1.0, 3.0 * u)
	text(ci, Vector2(s.x * 0.22, s.y * 0.2), "...", int(26 * u))


## C2: the torch cone finding writing on the wall.
static func _torch(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	ci.draw_rect(Rect2(Vector2(-40, -40), s + Vector2(80, 80)), DARK)
	var hand: Vector2 = Vector2(s.x * 0.2, s.y * 0.56)
	var sweep: float = sin(t * 1.3) * 0.12
	var aim: Vector2 = Vector2(s.x * 0.72, s.y * (0.38 + sweep))
	var cone: PackedVector2Array = PackedVector2Array([hand, aim + Vector2(-30, -110) * u, aim + Vector2(40, -90) * u,
		aim + Vector2(40, 90) * u, aim + Vector2(-30, 110) * u])
	ci.draw_colored_polygon(cone, Color(1.0, 0.96, 0.82, 0.85))
	var font_size: int = int(28 * u)
	text(ci, Vector2(s.x * 0.72, s.y * 0.36), "IT SEES", font_size, Color(InkDraw.RED, 0.9))
	text(ci, Vector2(s.x * 0.72, s.y * 0.46), "THE LIGHT", font_size, Color(InkDraw.RED, 0.9))
	RevealArt.red_figure(ci, Vector2(s.x * 0.14, s.y * 0.86), u * 1.2, tick)
	ci.draw_circle(hand, 6.0 * u, Color(1, 0.95, 0.7))


## C2: the house at night with a huge pen nib's shadow sliding over it.
static func _pen_shadow(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	ci.draw_rect(Rect2(Vector2(-40, -40), s + Vector2(80, 80)), Color(0.78, 0.76, 0.72))
	var base: float = s.y * 0.85
	var house: PackedVector2Array = PackedVector2Array([Vector2(s.x * 0.25, base), Vector2(s.x * 0.25, base - 120 * u),
		Vector2(s.x * 0.5, base - 210 * u), Vector2(s.x * 0.75, base - 120 * u), Vector2(s.x * 0.75, base)])
	InkDraw.shape(ci, house, 4.0, tick, Color(0.3, 0.29, 0.32))
	for i in 3:
		ci.draw_rect(Rect2(s.x * (0.32 + i * 0.13), base - 100 * u, 22 * u, 30 * u), Color(0.95, 0.9, 0.6))
	var slide: float = lerpf(-0.3, 0.25, clampf(t / 3.0, 0.0, 1.0))
	var tip: Vector2 = Vector2(s.x * (0.5 + slide), base - 40 * u)
	var nib: PackedVector2Array = PackedVector2Array([tip, tip + Vector2(-90, -260) * u, tip + Vector2(-20, -330) * u,
		tip + Vector2(60, -300) * u])
	ci.draw_colored_polygon(nib, Color(0, 0, 0, 0.55))
	InkDraw.line(ci, tip, tip + Vector2(-30, -230) * u, 3.0, tick + 4, Color(0.8, 0.78, 0.74, 0.6))


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


## C4: a red thumbprint smeared across the panel lines.
static func _red_smudge(ci: CanvasItem, s: Vector2, t: float, tick: int) -> void:
	var u: float = unit(s)
	for i in 6:
		InkDraw.line(ci, Vector2(0, s.y * (0.15 + i * 0.14)), Vector2(s.x, s.y * (0.18 + i * 0.14)), 2.5, tick + i, GREY)
	var c: Vector2 = s * 0.5
	var smear: float = clampf(t / 2.0, 0.0, 1.0)
	for i in 9:
		var r: float = (14.0 + i * 9.0) * u
		var pts: PackedVector2Array = InkDraw.ellipse_points(c + Vector2(smear * i * 8.0 * u, 0), Vector2(r, r * 1.25), 24)
		InkDraw.polyline(ci, pts, 3.0 * u, tick + 10 + i, true, Color(InkDraw.RED, 0.85 - i * 0.07), 2.0)
	ci.draw_colored_polygon(InkDraw.ellipse_points(c + Vector2(smear * 120.0 * u, 6 * u), Vector2(140 * smear + 4, 22) * u, 20),
		Color(InkDraw.RED, 0.35))


## Old-photo wash for the flashback panels.
static func _sepia(ci: CanvasItem, s: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2(-40, -40), s + Vector2(80, 80)), Color(0.93, 0.88, 0.78))
