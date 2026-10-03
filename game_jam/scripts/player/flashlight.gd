class_name Flashlight
extends PointLight2D
## Cone light that aims at the mouse. Reads LightingSystem for on/off and
## intensity. The cone texture is generated once in code (no assets).

const TEXTURE_SIZE: int = 256
const CONE_HALF_ANGLE: float = deg_to_rad(24.0)

static var _cone_texture: ImageTexture

var _flicker_time: float = 0.0


func _ready() -> void:
	add_to_group(&"flashlight")
	if _cone_texture == null:
		_cone_texture = _build_cone_texture()
	texture = _cone_texture
	texture_scale = 4.2
	energy = 0.0
	blend_mode = Light2D.BLEND_MODE_ADD


func _process(delta: float) -> void:
	rotation = (get_global_mouse_position() - global_position).angle()
	_flicker_time += delta
	var target: float = 0.0
	if LightingSystem.is_light_on:
		var flicker: float = 1.0 - 0.06 * (0.5 + 0.5 * sin(_flicker_time * 23.0) * sin(_flicker_time * 7.0))
		target = 1.25 * LightingSystem.light_intensity * flicker
	energy = move_toward(energy, target, delta * 9.0)


## True if the lit cone covers this point (light on, in range, in angle).
func illuminates(global_point: Vector2) -> bool:
	if not LightingSystem.is_light_on or energy < 0.3:
		return false
	var to_point: Vector2 = global_point - global_position
	if to_point.length() > TEXTURE_SIZE * 0.5 * texture_scale * 0.9:
		return false
	return absf(angle_difference(global_rotation, to_point.angle())) < CONE_HALF_ANGLE


## True if the cone covers any of a rect's centre or (inset) corners.
func illuminates_rect(global_rect: Rect2) -> bool:
	var inner: Rect2 = global_rect.grow_individual(-global_rect.size.x * 0.2, -global_rect.size.y * 0.2, -global_rect.size.x * 0.2, -global_rect.size.y * 0.2)
	for p in [inner.get_center(), inner.position, inner.end, Vector2(inner.position.x, inner.end.y), Vector2(inner.end.x, inner.position.y)]:
		if illuminates(p):
			return true
	return false


## Cone pointing along +X from the texture centre, with a small spill circle
## around the lens so the hand is lit too.
static func _build_cone_texture() -> ImageTexture:
	var img: Image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var half: float = TEXTURE_SIZE * 0.5
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var d: Vector2 = Vector2(x + 0.5 - half, y + 0.5 - half)
			var dist: float = d.length() / half
			var cone: float = 0.0
			if d.x > 0.0 and dist < 1.0:
				var angle: float = absf(atan2(d.y, d.x))
				var edge: float = 1.0 - smoothstep(CONE_HALF_ANGLE * 0.7, CONE_HALF_ANGLE, angle)
				cone = edge * pow(1.0 - dist, 0.8)
			var spill: float = clampf(1.0 - dist / 0.09, 0.0, 1.0) * 0.7
			var v: float = maxf(cone, spill)
			img.set_pixel(x, y, Color(1.0, 0.97, 0.9, v))
	return ImageTexture.create_from_image(img)
