extends ColorRect
## Panel-sized overlay for the glitch shader (Chapter 3). Strength comes from
## the frame (FrameData.glitch) and from comic damage, so giving words back
## visibly calms the panel. Hidden entirely when there is nothing to glitch.

var _frame_glitch: float = 0.0
var _material: ShaderMaterial


func _ready() -> void:
	position = Frame.PANEL_RECT.position
	size = Frame.PANEL_RECT.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/glitch.gdshader")
	_material.set_shader_parameter("seed", randf() * 100.0)
	material = _material
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.comic_damage_changed.connect(_on_damage_changed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.comic_repaired.connect(_on_comic_repaired)
	hide()


func _on_frame_changed(data: FrameData) -> void:
	_frame_glitch = GameState.glitch_of(data)
	_apply()


## The last word went home: the glitch fades to nothing.
func _on_comic_repaired() -> void:
	create_tween().tween_method(func(value: float) -> void:
		_frame_glitch = value
		_apply(), _frame_glitch, 0.0, 2.5)


func _on_damage_changed(_value: float) -> void:
	_apply()


func _apply() -> void:
	var strength: float = _frame_glitch * (0.3 + 0.7 * GameState.damage_visual())
	_material.set_shader_parameter("strength", strength)
	visible = strength > 0.01
