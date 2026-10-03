class_name FrameBackground
extends Node2D
## Procedural ink art for a panel, chosen by FrameData.background_style.
## Each style lives in a Bg* helper so no file gets too long.

const FLOOR_Y: float = 380.0

var panel_size: Vector2 = Vector2(1184, 528)
var style: StringName = &"plain":
	set(value):
		style = value
		queue_redraw()
## Seconds since the frame opened, for slow animation (ink drips).
var time: float = 0.0
## 0..1 share of strokes left out: the room is only half drawn.
var sketch: float = 0.0

var _tick: int = -1


func _process(delta: float) -> void:
	time += delta
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	InkDraw.gap_ratio = sketch
	_draw_style()
	InkDraw.gap_ratio = 0.0


func _draw_style() -> void:
	draw_room(self, _tick)
	match style:
		&"awakening":
			BgBedrooms.awakening(self, _tick)
		&"bedchamber":
			BgBedrooms.bedchamber(self, _tick)
		&"landing":
			BgHalls.landing(self, _tick)
		&"study_corridor":
			BgHalls.study_corridor(self, _tick)
		&"hallway":
			BgHalls.hallway(self, _tick)
		&"study":
			BgStudy.study(self, _tick)
		&"exit_room":
			BgStudy.exit_room(self, _tick)
		&"long_hallway":
			BgCh2Halls.long_hallway(self, _tick)
		&"gallery":
			BgCh2Halls.gallery(self, _tick)
		&"passage":
			BgCh2Halls.passage(self, _tick)
		&"pantry":
			BgCh2Rooms.pantry(self, _tick)
		&"clock_room":
			BgCh2Rooms.clock_room(self, _tick)
		&"cellar_stair":
			BgCh2Rooms.cellar_stair(self, _tick)
		&"torn_page":
			BgCh3.torn_page(self, _tick)
		&"returning_room":
			BgCh3.returning_room(self, _tick)
		&"gallery_words":
			BgCh3.gallery_words(self, _tick)
		&"margin":
			BgCh3.margin(self, _tick)


## Floor, floorboards in perspective, skirting shadow and wallpaper stripes.
static func draw_room(ci: FrameBackground, tick: int) -> void:
	var s: int = tick * 31
	var size: Vector2 = ci.panel_size
	InkDraw.line(ci, Vector2(0, FLOOR_Y), Vector2(size.x, FLOOR_Y), 3.0, s)
	var vanish: Vector2 = Vector2(size.x * 0.5, FLOOR_Y - 600.0)
	for i in 13:
		var top: Vector2 = Vector2(-200.0 + i * 130.0, FLOOR_Y)
		var dir: Vector2 = (top - vanish).normalized()
		InkDraw.line(ci, top, top + dir * ((size.y - FLOOR_Y) / dir.y), 1.5, s + i)
	InkDraw.hatch(ci, Rect2(0, FLOOR_Y - 26, size.x, 24), 9.0, 1.0, s + 50)
	for i in int(size.x / 74):
		var x: float = 30.0 + i * 74.0
		InkDraw.line(ci, Vector2(x, 0), Vector2(x, FLOOR_Y - 30), 1.0, s + 90 + i, Color(InkDraw.INK, 0.35), 2.0)


## A doorway: dark opening with a frame. `ajar` draws a door leaf swung in.
static func doorway(ci: CanvasItem, r: Rect2, s: int, ajar: bool = false) -> void:
	InkDraw.rect(ci, r.grow(9), 5.0, s, Color(0.2, 0.19, 0.22))
	InkDraw.rect(ci, r, 3.0, s + 1, Color(0.04, 0.04, 0.05))
	if ajar:
		var leaf: PackedVector2Array = PackedVector2Array([
			r.position, r.position + Vector2(26, 18), Vector2(r.position.x + 26, r.end.y - 14), Vector2(r.position.x, r.end.y)])
		InkDraw.shape(ci, leaf, 3.0, s + 2, Color(0.78, 0.75, 0.68))
