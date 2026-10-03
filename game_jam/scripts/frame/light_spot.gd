class_name LightSpot
extends Node2D
## A fixed light from LightSpotData. Candles draw themselves and flicker.

var data: LightSpotData

var _light: PointLight2D
var _time: float = randf() * 10.0
var _tick: int = -1


func setup(spot: LightSpotData) -> void:
	data = spot
	position = spot.position
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial()
	_light.texture_scale = spot.radius / LightTextures.RADIAL_RADIUS
	_light.energy = spot.energy
	match spot.kind:
		&"candle":
			_light.color = Color(1.0, 0.92, 0.78)
		&"moon":
			_light.color = Color(0.85, 0.9, 1.0)
	add_child(_light)


func _process(delta: float) -> void:
	if data == null or data.kind != &"candle":
		return
	_time += delta
	var flicker: float = 0.88 + 0.08 * sin(_time * 9.0) + 0.05 * sin(_time * 23.0 + 1.3)
	_light.energy = data.energy * flicker
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	if data == null or data.kind != &"candle":
		return
	# Flame at the origin, candle below it, small drip of wax.
	var s: int = _tick * 3
	InkDraw.rect(self, Rect2(-5, 6, 10, 26), 2.0, s, InkDraw.WHITE)
	InkDraw.line(self, Vector2(-11, 32), Vector2(11, 32), 3.0, s + 1)
	InkDraw.line(self, Vector2(0, 6), Vector2(0, 2), 1.5, s + 2)
	var sway: float = sin(_time * 7.0) * 1.5
	var flame: PackedVector2Array = PackedVector2Array([
		Vector2(0, 3), Vector2(-4, -3), Vector2(sway, -13), Vector2(4, -3)])
	draw_colored_polygon(flame, InkDraw.WHITE)
	InkDraw.polyline(self, flame, 1.5, s + 3, true, InkDraw.INK, 0.4)
