class_name LightTextures
extends RefCounted
## Shared light textures generated in code (no image assets).

## Radius in pixels of radial() at texture_scale 1.
const RADIAL_RADIUS: float = 128.0

static var _radial: GradientTexture2D


static func radial() -> GradientTexture2D:
	if _radial == null:
		var gradient: Gradient = Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.55))
		_radial = GradientTexture2D.new()
		_radial.gradient = gradient
		_radial.fill = GradientTexture2D.FILL_RADIAL
		_radial.fill_from = Vector2(0.5, 0.5)
		_radial.fill_to = Vector2(1.0, 0.5)
		_radial.width = 256
		_radial.height = 256
	return _radial
