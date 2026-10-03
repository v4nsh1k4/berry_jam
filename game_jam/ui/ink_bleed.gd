extends ColorRect
## Panel-sized overlay for the ink_bleed shader, fed by comic damage.


func _ready() -> void:
	position = Frame.PANEL_RECT.position
	size = Frame.PANEL_RECT.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/ink_bleed.gdshader")
	shader_material.set_shader_parameter("rect_size", size)
	material = shader_material
	EventBus.comic_damage_changed.connect(_on_damage_changed)
	EventBus.returned_to_menu.connect(hide)
	EventBus.frame_changed.connect(_on_frame_changed)
	hide()


func _on_frame_changed(_data: FrameData) -> void:
	show()


func _on_damage_changed(_value: float) -> void:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	shader_material.set_shader_parameter("damage", GameState.damage_visual())
