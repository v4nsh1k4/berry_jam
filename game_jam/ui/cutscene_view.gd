class_name CutsceneView
extends Control
## Draws one CutsceneBeat as a comic page: the beat's panels ink in one after
## another, the caption types itself into a narration box, and an optional
## page turn sweeps across first. Each panel is a clipped child Control that
## draws its CutsceneArt id through a slow camera move.

signal skip_requested

const PAGE_RECT: Rect2 = Rect2(60, 40, 1160, 640)
## Drawing area inside the page margin (panel fractions are of this).
const INNER: Rect2 = Rect2(90, 64, 1100, 500)
const GUTTER: float = 14.0
const PANEL_STAGGER: float = 0.35
const TURN_TIME: float = 0.5
const TYPE_SPEED: float = 38.0

var _beat: CutsceneBeat
var _t: float = 0.0
var _can_skip: bool = false
var _panels: Array[Control] = []
var _turn: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_turn = Control.new()
	_turn.set_anchors_preset(Control.PRESET_FULL_RECT)
	_turn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn.draw.connect(_draw_turn)
	add_child(_turn)


func set_beat(beat: CutsceneBeat) -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_beat = beat
	_t = 0.0
	for p in _panels:
		p.queue_free()
	_panels.clear()
	for i in beat.panels.size():
		var f: Rect2 = beat.panels[i]
		var panel: Control = Control.new()
		panel.clip_contents = true
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.position = INNER.position + f.position * INNER.size + Vector2(GUTTER, GUTTER) * 0.5
		panel.size = f.size * INNER.size - Vector2(GUTTER, GUTTER)
		var draw_id: String = beat.draws[i] if i < beat.draws.size() else ""
		panel.draw.connect(_draw_panel.bind(panel, draw_id, i))
		add_child(panel)
		_panels.append(panel)
	move_child(_turn, -1)
	queue_redraw()


func set_time(t: float, can_skip: bool) -> void:
	_t = t
	_can_skip = can_skip
	queue_redraw()
	for p in _panels:
		p.queue_redraw()
	_turn.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var pressed: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
	pressed = pressed or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_SPACE)
	pressed = pressed or (event is InputEventMouseButton and event.pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		skip_requested.emit()


func _draw() -> void:
	if _beat == null:
		return
	var tick: int = InkDraw.boil_tick()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.045, 0.06))
	draw_rect(Rect2(PAGE_RECT.position + Vector2(14, 18), PAGE_RECT.size), Color(0, 0, 0, 0.4))
	draw_rect(PAGE_RECT, InkDraw.PAPER)
	_caption(tick)
	if _can_skip:
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(PAGE_RECT.end.x - 190, PAGE_RECT.end.y + 26), "Space: skip",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(InkDraw.PAPER, 0.5))


func _caption(tick: int) -> void:
	if _beat.caption == "":
		return
	var shown: int = int(maxf(_t - 0.3, 0.0) * TYPE_SPEED)
	var text: String = _beat.caption.substr(0, mini(shown, _beat.caption.length()))
	var font: Font = ThemeDB.fallback_font
	var box: Rect2 = Rect2(INNER.position.x + 40, INNER.end.y + 22, INNER.size.x - 80, 72)
	InkDraw.rect(self, box, 3.5, tick, Color(1.0, 0.97, 0.86), InkDraw.INK)
	var lines: PackedStringArray = text.split("\n")
	for i in lines.size():
		var top: float = box.size.y * 0.5 - _beat.caption.split("\n").size() * 14.0 + 22.0
		draw_string(font, box.position + Vector2(24, top + i * 28), lines[i], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 48, 24, InkDraw.INK)


func _draw_panel(panel: Control, draw_id: String, index: int) -> void:
	var appear: float = clampf((_t - index * PANEL_STAGGER) / 0.3, 0.0, 1.0)
	if _beat.page_turn:
		appear = clampf((_t - TURN_TIME - index * PANEL_STAGGER) / 0.3, 0.0, 1.0)
	if appear <= 0.0:
		return
	var tick: int = InkDraw.boil_tick() + index * 7
	var s: Vector2 = panel.size
	panel.draw_rect(Rect2(Vector2.ZERO, s), InkDraw.WHITE)
	var cam: Transform2D = _camera(s)
	RevealArt.set_view(panel, cam)
	CutsceneArt.draw(panel, draw_id, s, _t, tick)
	CutsceneDetail.extra(panel, draw_id, s, _t, tick)
	CutsceneFill.draw(panel, draw_id, s, tick)
	RevealArt.set_view(panel, Transform2D.IDENTITY)
	CutsceneDetail.texture(panel, s, draw_id.hash())
	if CutsceneArt3.is_pov(draw_id):
		CutsceneArt3.overlay(panel, draw_id, s, _t, tick, cam)
	InkDraw.rect(panel, Rect2(Vector2(3, 3), s - Vector2(6, 6)), 6.0, tick + 3)
	if appear < 1.0:
		panel.draw_rect(Rect2(Vector2.ZERO, s), Color(InkDraw.PAPER, 1.0 - appear))


## The beat's slow camera move, as a transform around the panel centre.
## pov_* modes (first person) add breathing sway and a slight roll:
## look_up (eyes rise to the bubble), look (drift), sweep (follow the torch),
## look_down (down the stair, a step's bob), shake (fear).
func _camera(s: Vector2) -> Transform2D:
	var k: float = clampf(_t / maxf(_beat.duration, 0.1), 0.0, 1.0)
	var c: Vector2 = s * 0.5
	var zoom: float = 1.0
	var offset: Vector2 = Vector2.ZERO
	var roll: float = 0.0
	match _beat.camera:
		&"zoom_in":
			zoom = lerpf(1.0, 1.18, k)
		&"zoom_out":
			zoom = lerpf(1.2, 1.0, k)
		&"pan_left":
			zoom = 1.12
			offset.x = lerpf(s.x * 0.05, -s.x * 0.05, k)
		&"pan_right":
			zoom = 1.12
			offset.x = lerpf(-s.x * 0.05, s.x * 0.05, k)
		&"shake", &"pov_shake":
			var fade: float = maxf(0.0, 1.0 - _t * 1.4)
			offset = Vector2(sin(_t * 61.0), cos(_t * 47.0)) * 9.0 * fade
			zoom = 1.12 if _beat.camera == &"pov_shake" else 1.0
		&"pov_look_up":
			zoom = 1.12
			offset.y = lerpf(-s.y * 0.07, s.y * 0.04, ease(k, -1.6))
		&"pov_look":
			zoom = 1.1
			offset.x = lerpf(s.x * 0.03, -s.x * 0.03, k)
		&"pov_sweep":
			zoom = 1.12
			offset.x = -sin(_t * 1.5 - 1.2) * s.x * 0.035
		&"pov_look_down":
			zoom = lerpf(1.08, 1.22, k)
			offset.y = lerpf(s.y * 0.05, -s.y * 0.05, k) + absf(sin(_t * 4.2)) * 6.0
	if String(_beat.camera).begins_with("pov_"):
		offset += Vector2(sin(_t * 1.1) * s.x * 0.006, sin(_t * 2.2) * s.y * 0.008)
		roll = sin(_t * 0.9) * 0.012
	var xf: Transform2D = Transform2D(roll, Vector2(zoom, zoom), 0.0, Vector2.ZERO)
	xf.origin = c + offset - xf.basis_xform(c)
	return xf


## The page turn: the old page folds away to the left, a curl at its edge.
func _draw_turn() -> void:
	if _beat == null or not _beat.page_turn or _t >= TURN_TIME:
		return
	var k: float = ease(clampf(_t / TURN_TIME, 0.0, 1.0), 0.6)
	var r: Rect2 = PAGE_RECT
	var edge: float = lerpf(r.end.x, r.position.x, k)
	var curl: float = 70.0 * sin(k * PI)
	_turn.draw_rect(Rect2(r.position, Vector2(edge - r.position.x, r.size.y)), InkDraw.PAPER)
	for i in 6:
		var y: float = r.position.y + 90.0 + i * 90.0
		_turn.draw_line(Vector2(r.position.x + 40, y), Vector2(maxf(edge - 40, r.position.x + 40), y), Color(InkDraw.INK, 0.08), 2.0)
	if curl < 2.0:
		return
	var fold: PackedVector2Array = PackedVector2Array([Vector2(edge, r.position.y), Vector2(edge + curl, r.position.y + 20),
		Vector2(edge + curl, r.end.y - 20), Vector2(edge, r.end.y)])
	_turn.draw_colored_polygon(fold, Color(0.82, 0.79, 0.72))
	_turn.draw_rect(Rect2(edge + curl, r.position.y, 30, r.size.y), Color(0, 0, 0, 0.18 * sin(k * PI)))
	_turn.draw_polyline(fold, InkDraw.INK, 2.5)
