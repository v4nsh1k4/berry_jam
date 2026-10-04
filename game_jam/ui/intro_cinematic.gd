extends Control
## New Game opening, drawn in code as comic pages (about 25 s; click / Space
## skips). Page 1: a teenager reading "The Silent House of Hollow Hill" late
## at night, the book, their face. Page 2 (page turn): the book glows, red
## ink erupts and drags them in. Page 3: the book slams shut. Then the white
## first panel (the Awakening) and Chapter 1's intro captions. The scene
## itself is one continuous 1280x720 drawing; the panels look into it.

const HIP: Vector2 = Vector2(330, 470)
const BOOK: Vector2 = Vector2(560, 360)
const T_GLOW: float = 5.0
const T_INK: float = 9.5
const T_PULL: float = 13.5
const T_SLAM: float = 19.6
const T_WHITE: float = 22.2
const T_END: float = 25.0

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
		{start = 0.0, end = 8.6, caption = "Late. One more chapter. The pages are warm.", panels = [
			{rect = Rect2(0, 0, 1, 0.56), src = Rect2(0, 60, 1280, 600), zoom = 1.06},
			{rect = Rect2(0, 0.56, 0.46, 0.44), src = Rect2(420, 250, 300, 220), tilt = -1.5, zoom = 1.2},
			{rect = Rect2(0.46, 0.56, 0.54, 0.44), src = Rect2(200, 150, 340, 230), tilt = 1.5, zoom = 1.15}]},
		{start = 8.6, end = 17.4, caption = "Something in the ink wants a reader.", panels = [
			{rect = Rect2(0, 0, 0.6, 1), src = Rect2(330, 120, 520, 520), tilt = -2.0, zoom = 1.12},
			{rect = Rect2(0.6, 0, 0.4, 0.5), src = Rect2(140, 110, 420, 360), tilt = 2.5, zoom = 1.25},
			{rect = Rect2(0.6, 0.5, 0.4, 0.5), src = Rect2(470, 260, 220, 180), tilt = -3.0, zoom = 1.4}]},
		{start = 17.4, end = T_WHITE, caption = "", panels = [
			{rect = Rect2(0.04, 0.02, 0.92, 0.96), src = Rect2(160, 80, 900, 560), tilt = 1.0, zoom = 1.3}]},
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
	_t += delta
	if _t >= T_INK and _t - delta < T_INK:
		AudioManager.play(&"steal", -4.0, 0.0)
	for at in [8.6, 17.4]:
		if _t >= at and _t - delta < at:
			AudioManager.play(&"swoosh", -6.0, 0.05)
	if _t >= T_SLAM and not _slammed:
		_slammed = true
		AudioManager.play(&"slam", -2.0, 0.0)
		EventBus.shake_requested.emit(0.5)
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


## The continuous scene the panels look into (scene space 1280x720).
func _scene(ci: CanvasItem, _id: int, t: float, tick: int) -> void:
	var screen: Vector2 = ComicPages.SCENE
	var slammed: bool = t >= T_SLAM
	RealWorldArt.bedroom(ci, screen, 0.0, tick)
	var glow: float = smoothstep(T_GLOW, T_INK, t) * (0.0 if slammed else 1.0)
	var shrink: float = smoothstep(T_PULL, T_SLAM - 0.4, t)
	var shake: Vector2 = Vector2(sin(t * 53.0), cos(t * 41.0)) * 4.0 * smoothstep(T_INK, T_PULL, t) * (0.0 if slammed else 1.0)
	var book: Vector2 = BOOK + shake
	if not slammed:
		RealWorldArt.teen(ci, HIP, book, 1.0 - smoothstep(T_SLAM - 0.8, T_SLAM, t), shrink, tick)
	RealWorldArt.book(ci, book if not slammed else Vector2(560, 500), 0.0 if slammed else 1.0, glow, tick)
	var ink: float = smoothstep(T_INK, T_PULL, t) * (1.0 - smoothstep(T_SLAM - 1.5, T_SLAM, t))
	RealWorldArt.red_ink(ci, book, HIP.lerp(book, shrink) + Vector2(10, -200) * (1.0 - shrink), ink, tick * 3)
	if slammed:
		var k: float = smoothstep(T_SLAM, T_SLAM + 0.25, t)
		ci.draw_rect(Rect2(Vector2(-200, -200), screen + Vector2(400, 400)), Color(1, 1, 1, 0.7 * (1.0 - k)))
		ci.draw_rect(Rect2(Vector2(-200, -200), screen + Vector2(400, 400)), Color(0, 0, 0, smoothstep(T_SLAM + 0.6, T_WHITE, t)))
		var font: Font = ThemeDB.fallback_font
		ci.draw_string_outline(font, Vector2(560, 300), "SLAM!", HORIZONTAL_ALIGNMENT_LEFT, -1, 110, 14, InkDraw.WHITE)
		ci.draw_string(font, Vector2(560, 300), "SLAM!", HORIZONTAL_ALIGNMENT_LEFT, -1, 110, InkDraw.INK)


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
