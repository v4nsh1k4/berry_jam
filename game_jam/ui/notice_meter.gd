extends Node2D
## Ink-blot HUD for the noticed meter. Grows as the Crawler takes notice;
## only shown in frames that have a Crawler. Stage 6b: labelled "NOTICED",
## pulses as it nears full; while hunted it turns jagged and bigger, reads
## "HUNTED!" and snaps (a nib scratch) on top of the danger sting.

const MAX_RADIUS: float = 44.0

var _notice: float = 0.0
var _light: bool = false
var _noise: bool = false
## Last meter level a tick sound played at (a quiet tick per 12%).
var _ticked: float = 0.0
var _tick: int = -1
var _hunted: bool = false
var _time: float = 0.0


func _ready() -> void:
	EventBus.notice_changed.connect(_on_notice_changed)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.light_toggled.connect(_on_light_toggled)
	EventBus.notice_sources.connect(_on_sources)
	EventBus.crawler_state_changed.connect(_on_crawler_state)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	visible = data.crawler_spawn != Vector2.INF and LightingSystem.has_flashlight()


func _on_light_toggled(_on: bool) -> void:
	if FrameManager.current_frame != null:
		_on_frame_changed(FrameManager.current_frame.data)


func _on_crawler_state(state: StringName) -> void:
	var hunted: bool = state in [&"HUNTING", &"TELEGRAPH", &"LUNGE"]
	if hunted and not _hunted and visible:
		AudioManager.play(&"nib", -4.0, 0.05)
	_hunted = hunted
	queue_redraw()


func _on_sources(light: bool, noise: bool) -> void:
	_light = light
	_noise = noise
	queue_redraw()


func _on_notice_changed(amount: float) -> void:
	if amount > _ticked + 0.12:
		_ticked = amount
		AudioManager.play(&"click", -19.0, 0.2)
	elif amount < _ticked - 0.12:
		_ticked = amount
	_notice = amount
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var tick: int = InkDraw.boil_tick()
	if _notice > 0.7 or _hunted:
		queue_redraw()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _tick
	InkDraw.ellipse(self, Vector2.ZERO, Vector2(MAX_RADIUS, MAX_RADIUS), 2.0, _tick, InkDraw.WHITE, Color(InkDraw.INK, 0.6))
	# A faint pulse as it nears full; jagged claws while it hunts you.
	var pulse: float = 1.0 + (0.07 * sin(_time * 9.0) if _notice > 0.7 and not _hunted else 0.0)
	if _notice > 0.7 and not _hunted:
		draw_arc(Vector2.ZERO, MAX_RADIUS + 5.0 + 3.0 * sin(_time * 9.0), 0.0, TAU, 32, Color(InkDraw.RED, 0.35), 2.0)
	if _notice > 0.01 or _hunted:
		var amount: float = 1.0 if _hunted else _notice
		var radius: float = (6.0 + (MAX_RADIUS - 6.0) * amount) * pulse * (1.15 if _hunted else 1.0)
		var blot: PackedVector2Array = PackedVector2Array()
		var points: int = 30 if _hunted else 22
		for i in points:
			var t: float = TAU * i / points
			var spike: float = rng.randf_range(0.8, 1.15) if i % 3 != 0 else rng.randf_range(1.1, 1.35)
			if _hunted:
				spike = 0.62 if i % 2 == 0 else rng.randf_range(1.25, 1.5)
			blot.append(Vector2(cos(t), sin(t)) * radius * (spike if _hunted else minf(spike, MAX_RADIUS / radius)))
		draw_colored_polygon(blot, InkDraw.RED)
	var font: Font = ThemeDB.fallback_font
	var label: String = "HUNTED!" if _hunted else "NOTICED"
	var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(-w * 0.5, MAX_RADIUS + 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, InkDraw.RED if _hunted or _notice >= 1.0 else InkDraw.INK)
	NoticeIcons.draw(self, Vector2(-MAX_RADIUS - 34, -14), _light, Vector2(-MAX_RADIUS - 34, 22), _noise, _tick)
