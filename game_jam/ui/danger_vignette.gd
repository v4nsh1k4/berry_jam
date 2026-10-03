extends ColorRect
## Red edge vignette that pulses with each heartbeat as the Crawler gets
## close or the noticed meter fills.

var _near: float = 0.0
var _notice: float = 0.0
var _pulse: float = 0.0
var _material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/danger_vignette.gdshader")
	material = _material
	EventBus.crawler_proximity.connect(_on_proximity)
	EventBus.notice_changed.connect(_on_notice)
	EventBus.heartbeat.connect(_on_heartbeat)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(_on_frame_changed.bind(null))


func _on_proximity(amount: float, _moving: bool) -> void:
	_near = amount


func _on_notice(amount: float) -> void:
	_notice = amount


func _on_heartbeat(_strength: float) -> void:
	_pulse = 1.0


func _on_frame_changed(_data: FrameData) -> void:
	_near = 0.0
	_notice = 0.0


func _process(delta: float) -> void:
	_pulse = move_toward(_pulse, 0.0, delta * 2.5)
	var strength: float = clampf(maxf(_near, _notice * 0.6), 0.0, 1.0)
	_material.set_shader_parameter("strength", strength)
	_material.set_shader_parameter("pulse", _pulse)
	visible = strength > 0.01
