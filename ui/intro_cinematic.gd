extends Control
## New Game opening (Stage 5: shorter, "sucked into the comic"), drawn in code
## as comic pages (18.5 s; click / Space skips). Page 1: late at night, a
## reader bent over the comic open on their desk, the page lighting their face.
## Page 2 (page turn): the page's ink lifts and reaches out, the room warps
## toward the page, a finger touches it and turns red. Page 3: inside the
## pull (panel borders zooming into the page, speed lines, page lines curling),
## the red reader dragged into the light, then SLAM: the book shuts. Then the
## white first panel inks in and the team's recorded cry plays, faint.
## Scenes (IntroArt / IntroArt2): 0 room, 1 the page close up, 2 the tunnel.

const T_PAGE2: float = 4.4
const T_INK: float = 4.8
const T_TOUCH: float = 7.4
const T_PAGE3: float = 9.8
const T_SLAM: float = 13.6
const T_WHITE: float = 15.0
const T_CRY: float = 15.3
const T_END: float = 18.5

var _t: float = -1.0
var _slammed: bool = false
var _pages: ComicPages


func _ready() -> void:
	UiTheme.make_screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.returned_to_menu.connect(_stop)
	_pages = ComicPages.new()
	_pages.scene_drawer = _scene
	_pages.footer = "click / space: skip"
	_pages.pages = [
		{start = 0.0, end = T_PAGE2, caption = "Late. One more chapter. The pages are warm.", panels = [
			{rect = Rect2(0, 0, 1, 0.56), src = Rect2(40, 150, 1200, 520), zoom = 1.08},
			{rect = Rect2(0, 0.56, 0.46, 0.44), src = Rect2(470, 380, 380, 180), tilt = -1.5, zoom = 1.25},
			{rect = Rect2(0.46, 0.56, 0.54, 0.44), src = Rect2(330, 220, 400, 220), tilt = 1.5, zoom = 1.2}]},
		{start = T_PAGE2, end = T_PAGE3, caption = "Something in the ink wants a reader.", panels = [
			{rect = Rect2(0, 0, 0.6, 1), src = Rect2(200, 60, 900, 640), scene = 1, tilt = -2.0, zoom = 1.15},
			{rect = Rect2(0.6, 0, 0.4, 0.5), src = Rect2(80, 120, 1100, 560), tilt = 2.5, zoom = 1.3},
			{rect = Rect2(0.6, 0.5, 0.4, 0.5), src = Rect2(470, 300, 420, 320), scene = 1, tilt = -3.0, zoom = 1.45}]},
		{start = T_PAGE3, end = T_WHITE, caption = "", panels = [
			{rect = Rect2(0.03, 0.02, 0.94, 0.96), src = Rect2(160, 80, 960, 600), scene = 2, tilt = 1.0, zoom = 1.5}]},
	]
	add_child(_pages)
	hide()


func play() -> void:
	_t = 0.0
	_slammed = false
	show()
	EventBus.music_cue.emit(&"sting_soft")


func _stop() -> void:
	_t = -1.0
	hide()


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	var was: float = _t
	_t += delta
	var crossed: Callable = func(at: float) -> bool: return _t >= at and was < at
	if crossed.call(T_INK):
		AudioManager.play(&"whisper", -10.0, 0.05)
	if crossed.call(T_TOUCH):
		AudioManager.play(&"steal", -4.0, 0.0)
	for at in [T_PAGE2, T_PAGE3, T_PAGE3 + 2.0]:
		if crossed.call(at):
			AudioManager.play(&"swoosh", -6.0 if at != T_PAGE3 + 2.0 else -3.0, 0.05)
	if _t >= T_SLAM and not _slammed:
		_slammed = true
		AudioManager.play(&"slam", -2.0, 0.0)
		EventBus.shake_requested.emit(0.5)
	if crossed.call(T_CRY):
		AudioManager.play_cry(&"raw", -17.0, 0.4, &"cry_intro")
	if _t >= T_END:
		_finish()
		return
	_pages.visible = _t < T_WHITE
	_pages.set_time(_t)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		accept_event()
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _t >= 0.0 and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _t < 0.0:
		return
	_stop()
	EventBus.intro_cinematic_finished.emit()


## Scene `id` at time `t` (scene space 1280x720), see IntroArt.
func _scene(ci: CanvasItem, id: int, t: float, tick: int) -> void:
	var glow: float = smoothstep(0.0, T_PAGE2, t) * 0.6 + smoothstep(T_INK, T_TOUCH, t) * 0.4
	var ink: float = smoothstep(T_INK, T_TOUCH, t)
	var reach: float = smoothstep(T_INK + 0.6, T_TOUCH, t)
	var red: float = smoothstep(T_TOUCH, T_TOUCH + 1.2, t)
	match id:
		0:
			IntroArt.room(ci, t, glow, ink, reach, red, smoothstep(T_INK + 0.8, T_PAGE3, t), 1.0, tick)
		1:
			IntroArt2.page_close(ci, t, ink, reach, red, smoothstep(T_TOUCH + 0.9, T_PAGE3 + 0.2, t), tick)
		2:
			if t < T_SLAM:
				IntroArt2.tunnel(ci, t, smoothstep(T_PAGE3 + 0.2, T_SLAM - 0.1, t), tick)
			else:
				_slam(ci, t, tick)


## The book slammed shut on an empty desk: a white flash, SLAM!, then black.
func _slam(ci: CanvasItem, t: float, tick: int) -> void:
	IntroArt.room(ci, t, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, tick, true)
	var big: Rect2 = Rect2(Vector2(-400, -400), Vector2(2080, 1520))
	ci.draw_rect(big, Color(1, 1, 1, 0.75 * (1.0 - smoothstep(T_SLAM, T_SLAM + 0.25, t))))
	ci.draw_rect(big, Color(0, 0, 0, smoothstep(T_SLAM + 0.6, T_WHITE, t)))
	var font: Font = ThemeDB.fallback_font
	ci.draw_string_outline(font, Vector2(440, 330), "SLAM!", HORIZONTAL_ALIGNMENT_LEFT, -1, 120, 14, InkDraw.WHITE)
	ci.draw_string(font, Vector2(440, 330), "SLAM!", HORIZONTAL_ALIGNMENT_LEFT, -1, 120, InkDraw.INK)


func _draw() -> void:
	if _t < 0.0:
		return
	if _t >= T_WHITE:
		# The white page the story starts on, its first panel's border inking in.
		var k: float = smoothstep(T_WHITE, T_WHITE + 1.2, _t)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0).lerp(InkDraw.WHITE, k))
		var draw_in: float = smoothstep(T_WHITE + 0.8, T_END - 0.3, _t)
		if draw_in > 0.0:
			var pts: PackedVector2Array = InkDraw.rect_points(Rect2(48, 32, 1184, 528))
			pts.append(pts[0])
			for i in 4:
				var part: float = clampf(draw_in * 4.0 - i, 0.0, 1.0)
				if part > 0.0:
					draw_line(pts[i], pts[i].lerp(pts[i + 1], part), InkDraw.INK, 6.0)
		return
