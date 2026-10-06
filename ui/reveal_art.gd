class_name RevealArt
extends RefCounted
## Drawing for the reveal, in "desk space": a comic page lying on the
## Artist's desk. The page has three wide panels; the bottom one is the Ink
## Heart, with the red figure (the player) in it. Units are about one game
## pixel per unit at the panel, so the first shot matches the live game.

const DESK: Color = Color(0.2, 0.19, 0.2)
const PAGE: Rect2 = Rect2(0, 0, 1400, 1980)
## The Ink Heart panel on the page (same shape as the game panel).
const HEART_PANEL: Rect2 = Rect2(60, 1282, 1280, 571)
const SMUDGE: Color = Color(0.62, 0.6, 0.58)
## Who each owner is in the "cost" shot, and which frame holds their lines.
const OWNERS: PackedStringArray = ["arthur", "mrs_vane", "portrait_lady"]
const OWNER_FRAMES: PackedStringArray = ["ch3_returning_room", "ch3_returning_room", "ch3_returning_room"]

static var _current: Transform2D = Transform2D.IDENTITY


static func desk(ci: CanvasItem, tick: int) -> void:
	ci.draw_rect(Rect2(-3000, -3000, 8000, 8000), DESK)
	for i in 14:
		var y: float = -900.0 + i * 260.0
		InkDraw.line(ci, Vector2(-2000, y), Vector2(4000, y + 90), 6.0, tick + i, Color(0.12, 0.11, 0.12), 6.0)


## The page with its three panels. `figure_x` 0..1 is where the player stood.
static func page(ci: CanvasItem, figure_x: float, rubbed: float, tick: int) -> void:
	ci.draw_rect(Rect2(PAGE.position + Vector2(30, 40), PAGE.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(PAGE, InkDraw.PAPER)
	var landing: Rect2 = Rect2(60, 60, 1280, 571)
	var gallery: Rect2 = Rect2(60, 671, 1280, 571)
	InkDraw.rect(ci, landing, 8.0, tick, InkDraw.WHITE)
	_landing(ci, landing, tick)
	InkDraw.rect(ci, gallery, 8.0, tick + 1, InkDraw.WHITE)
	_gallery(ci, gallery, tick)
	heart_panel(ci, HEART_PANEL, figure_x, rubbed, tick)


## Arthur on the landing, drawn small, with his door.
static func _landing(ci: CanvasItem, r: Rect2, tick: int) -> void:
	InkDraw.line(ci, Vector2(r.position.x, r.position.y + 410), Vector2(r.end.x, r.position.y + 410), 5.0, tick + 2)
	InkDraw.rect(ci, Rect2(r.position + Vector2(980, 150), Vector2(150, 260)), 6.0, tick + 3, Color(0.78, 0.75, 0.68))
	_character(ci, &"butler", r.position + Vector2(420, 430), 1.1, tick)


## Three portraits on a wall.
static func _gallery(ci: CanvasItem, r: Rect2, tick: int) -> void:
	for i in 3:
		var frame: Rect2 = Rect2(r.position + Vector2(140 + i * 380, 90), Vector2(220, 280))
		InkDraw.rect(ci, frame, 8.0, tick + 4 + i, Color(0.3, 0.28, 0.3))
		InkDraw.rect(ci, frame.grow(-18), 3.0, tick + 8 + i, InkDraw.PAPER)
		InkDraw.ellipse(ci, frame.get_center() + Vector2(0, -20), Vector2(36, 46), 4.0, tick + 12 + i, InkDraw.WHITE)


## The Ink Heart as it looks on the page: a dark panel, the pool, and the
## red figure, partly rubbed out (`rubbed` 0..1).
static func heart_panel(ci: CanvasItem, r: Rect2, figure_x: float, rubbed: float, tick: int) -> void:
	ci.draw_rect(r, Color(0.16, 0.15, 0.17))
	InkDraw.fill(ci, PackedVector2Array([r.position + Vector2(r.size.x, 0), r.position + Vector2(900, 120),
		r.position + Vector2(760, r.size.y), r.end]), Color(0.03, 0.03, 0.04))
	for i in 8:
		var a: Vector2 = r.position + Vector2(60 + i * 140, 80 + (i % 3) * 50)
		InkDraw.line(ci, a, a + Vector2(220, 30), 2.0, tick + 20 + i, Color(0.6, 0.58, 0.55, 0.5), 4.0)
	InkDraw.line(ci, r.position + Vector2(0, 410), r.position + Vector2(r.size.x, 410), 4.0, tick + 30, Color(0.5, 0.48, 0.46))
	var feet: Vector2 = r.position + Vector2(r.size.x * figure_x, 500)
	red_figure(ci, feet, 1.08, tick)
	if rubbed > 0.0:
		_smudges(ci, feet, rubbed, tick)
	InkDraw.rect(ci, r, 8.0, tick + 31)


## The player as drawn on the page: red, faceless, an empty bubble.
static func red_figure(ci: CanvasItem, feet: Vector2, s: float, tick: int) -> void:
	var red: Color = InkDraw.RED
	var hip: Vector2 = feet + Vector2(0, -42) * s
	InkDraw.line(ci, hip, feet + Vector2(-7, 0) * s, 4.5 * s, tick, red)
	InkDraw.line(ci, hip, feet + Vector2(7, 0) * s, 4.5 * s, tick + 1, red)
	InkDraw.shape(ci, PackedVector2Array([feet + Vector2(-11, -84) * s, feet + Vector2(11, -84) * s,
		feet + Vector2(9, -42) * s, feet + Vector2(-9, -42) * s]), 3.0 * s, tick + 2, red, red)
	InkDraw.ellipse(ci, feet + Vector2(0, -98) * s, Vector2(12, 13) * s, 3.0 * s, tick + 3, InkDraw.PAPER, red)
	InkDraw.ellipse(ci, feet + Vector2(26, -142) * s, Vector2(30, 17) * s, 2.5 * s, tick + 4, InkDraw.WHITE)


## Eraser rubbings across the figure's lower half and the floor round it.
static func _smudges(ci: CanvasItem, feet: Vector2, amount: float, tick: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5150
	# A few strokes across the legs and the floor: rubbed, not buried.
	for i in 4:
		var c: Vector2 = feet + Vector2(rng.randf_range(-50, 50), rng.randf_range(-40, 6))
		var radii: Vector2 = Vector2(rng.randf_range(30, 55), rng.randf_range(6, 11))
		ci.draw_colored_polygon(InkDraw.ellipse_points(c, radii, 16), Color(SMUDGE, 0.45 * amount))
	for i in 14:
		ci.draw_circle(feet + Vector2(rng.randf_range(-90, 90), rng.randf_range(-6, 14)), rng.randf_range(1.5, 3.5), Color(SMUDGE, amount))


## A character drawn at `at` (feet) with scale `s`, inside the current view.
static func _character(ci: CanvasItem, style: StringName, at: Vector2, s: float, tick: int) -> void:
	ci.draw_set_transform_matrix(_current * Transform2D(0.0, Vector2(s, s), 0.0, at))
	NpcArt.draw(ci, style, tick)
	ci.draw_set_transform_matrix(_current)


## Sets the transform the reveal draws with, remembered so characters can be
## placed inside it.
static func set_view(ci: CanvasItem, view: Transform2D) -> void:
	_current = view
	ci.draw_set_transform_matrix(view)


## Who the player robbed, with one broken line each (from the owners' frame
## data): [[style, display name, broken line], ...].
static func robbed_owners() -> Array:
	var out: Array = []
	for i in OWNERS.size():
		var owner: StringName = StringName(OWNERS[i])
		if GameState.stolen_from_count(owner) == 0:
			continue
		var frame: FrameData = load("res://data/frames/%s.tres" % OWNER_FRAMES[i]) as FrameData
		for npc in frame.npcs:
			if npc.id != owner:
				continue
			var line: String = "..."
			for j in npc.bubbles.size():
				if GameState.is_bubble_stolen(npc.bubbles[j].id) and j < npc.broken_lines.size():
					line = npc.broken_lines[j]
					break
			out.append([npc.visual_style, npc.display_name, line])
	return out


## The cost: each robbed character in their own panel, drawn unfinished, with
## a broken bubble. Screen space.
static func cost(ci: CanvasItem, screen: Vector2, owners: Array, alpha: float, tick: int) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, screen), InkDraw.WHITE)
	var count: int = maxi(owners.size(), 1)
	var w: float = minf(380.0, (screen.x - 120.0) / count - 30.0)
	var left: float = screen.x * 0.5 - (w * count + 30.0 * (count - 1)) * 0.5
	for i in owners.size():
		var r: Rect2 = Rect2(left + i * (w + 30.0), 150, w, 440)
		InkDraw.rect(ci, r, 7.0, tick + i, InkDraw.PAPER)
		var style: StringName = owners[i][0]
		var feet: Vector2 = r.position + Vector2(r.size.x * 0.5, 400) if style != &"portrait" else r.get_center() + Vector2(0, 40)
		InkDraw.gap_ratio = 0.55
		var saved: float = InkDraw.jitter_scale
		InkDraw.jitter_scale = 2.4
		set_view(ci, Transform2D(0.0, Vector2(0.9, 0.9), 0.0, feet))
		NpcArt.draw(ci, style, tick)
		set_view(ci, Transform2D.IDENTITY)
		InkDraw.jitter_scale = saved
		BubbleArt.draw(ci, r.position + Vector2(r.size.x * 0.5, 70), String(owners[i][2]), feet + Vector2(0, -170), tick + 9)
		InkDraw.gap_ratio = 0.0
		var name_size: Vector2 = ThemeDB.fallback_font.get_string_size(owners[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		ci.draw_string(ThemeDB.fallback_font, Vector2(r.get_center().x - name_size.x * 0.5, r.end.y + 34), owners[i][1],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, InkDraw.INK)
	ci.draw_rect(Rect2(Vector2.ZERO, screen), Color(InkDraw.WHITE, 1.0 - alpha))


## A narration box (no voice-over: sparse captions only).
static func caption(ci: CanvasItem, text: String, center: Vector2, alpha: float, tick: int) -> void:
	if alpha <= 0.01:
		return
	var font: Font = ThemeDB.fallback_font
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	var box: Rect2 = Rect2(center - size * 0.5 - Vector2(26, 18), size + Vector2(52, 36))
	InkDraw.rect(ci, box, 4.0, tick, Color(InkDraw.PAPER, alpha), Color(InkDraw.INK, alpha))
	ci.draw_string(font, box.position + Vector2(26, 18 + font.get_ascent(30)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(InkDraw.INK, alpha))
