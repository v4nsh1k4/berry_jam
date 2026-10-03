extends Node2D
## Ink-blot HUD for the noticed meter. Grows as the Crawler takes notice;
## only shown in frames that have a Crawler.

const MAX_RADIUS: float = 44.0

var _notice: float = 0.0
var _tick: int = -1


func _ready() -> void:
	EventBus.notice_changed.connect(_on_notice_changed)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.light_toggled.connect(_on_light_toggled)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	visible = data.crawler_spawn != Vector2.INF and LightingSystem.has_flashlight()


func _on_light_toggled(_on: bool) -> void:
	if FrameManager.current_frame != null:
		_on_frame_changed(FrameManager.current_frame.data)


func _on_notice_changed(amount: float) -> void:
	_notice = amount
	queue_redraw()


func _process(_delta: float) -> void:
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _tick
	InkDraw.ellipse(self, Vector2.ZERO, Vector2(MAX_RADIUS, MAX_RADIUS), 2.0, _tick, InkDraw.WHITE, Color(InkDraw.INK, 0.6))
	if _notice > 0.01:
		var radius: float = 6.0 + (MAX_RADIUS - 6.0) * _notice
		var blot: PackedVector2Array = PackedVector2Array()
		for i in 22:
			var t: float = TAU * i / 22.0
			var spike: float = rng.randf_range(0.8, 1.15) if i % 3 != 0 else rng.randf_range(1.1, 1.35)
			blot.append(Vector2(cos(t), sin(t)) * radius * minf(spike, MAX_RADIUS / radius))
		draw_colored_polygon(blot, InkDraw.RED)
	var font: Font = ThemeDB.fallback_font
	var label: String = "NOTICED!" if _notice >= 1.0 else "NOTICE"
	var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(-w * 0.5, MAX_RADIUS + 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, InkDraw.RED if _notice >= 1.0 else InkDraw.INK)
