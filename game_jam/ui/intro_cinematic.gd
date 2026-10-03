extends Control
## New Game opening, drawn in code (about 19 s; click / Space skips): a
## teenager reading "The Silent House of Hollow Hill" late at night, the book
## starts to glow, red ink erupts from the pages and pulls them in, the book
## slams shut. Then the white page, and Chapter 1's intro captions.

const HIP: Vector2 = Vector2(330, 470)
const BOOK: Vector2 = Vector2(560, 360)
const T_GLOW: float = 4.0
const T_INK: float = 8.0
const T_PULL: float = 12.5
const T_SLAM: float = 15.5
const T_DARK: float = 17.5
const T_END: float = 19.0
const CAPTIONS: PackedStringArray = ["Late. One more chapter.", "The pages are warm.", "Something in the ink wants a reader."]
const CAPTION_AT: PackedFloat32Array = [0.6, 4.6, 8.6]

var _t: float = -1.0
var _slammed: bool = false


func _ready() -> void:
	UiTheme.make_screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.returned_to_menu.connect(_stop)
	hide()


func play() -> void:
	_t = 0.0
	_slammed = false
	show()


func _stop() -> void:
	_t = -1.0
	hide()


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t >= T_INK and _t - delta < T_INK:
		AudioManager.play(&"steal", -4.0, 0.0)
	if _t >= T_SLAM and not _slammed:
		_slammed = true
		AudioManager.play(&"slam", -2.0, 0.0)
	if _t >= T_END:
		_finish()
		return
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


func _draw() -> void:
	if _t < 0.0:
		return
	var tick: int = InkDraw.boil_tick()
	if _t >= T_DARK:
		# The white page the story starts on.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0).lerp(InkDraw.WHITE, smoothstep(T_DARK, T_END, _t)))
		return
	RealWorldArt.bedroom(self, size, 0.0, tick)
	var glow: float = smoothstep(T_GLOW, T_INK, _t) * (0.0 if _slammed else 1.0)
	var shrink: float = smoothstep(T_PULL, T_SLAM - 0.3, _t)
	var shake: Vector2 = Vector2(randf_range(-4, 4), randf_range(-3, 3)) * smoothstep(T_INK, T_PULL, _t) * (0.0 if _slammed else 1.0)
	var book: Vector2 = BOOK + shake
	if not _slammed:
		RealWorldArt.teen(self, HIP, book, 1.0 - smoothstep(T_SLAM - 0.6, T_SLAM, _t), shrink, tick)
	RealWorldArt.book(self, book if not _slammed else Vector2(560, 500), 0.0 if _slammed else 1.0, glow, tick)
	var ink: float = smoothstep(T_INK, T_PULL, _t) * (1.0 - smoothstep(T_PULL + 1.5, T_SLAM, _t))
	RealWorldArt.red_ink(self, book, HIP.lerp(book, shrink) + Vector2(10, -200) * (1.0 - shrink), ink, tick * 3)
	if _slammed:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, smoothstep(T_SLAM, T_DARK, _t)))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.6 * (1.0 - smoothstep(T_SLAM, T_SLAM + 0.25, _t))))
	for i in CAPTIONS.size():
		var shown: float = _t - CAPTION_AT[i]
		var alpha: float = clampf(shown / 0.5, 0.0, 1.0) * clampf((3.4 - shown) / 0.5, 0.0, 1.0)
		RevealArt.caption(self, CAPTIONS[i], Vector2(size.x * 0.5, 64), alpha, tick + i)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, size.y - 24), "click / space: skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.6, 0.6))
