class_name FrostArt
extends RefCounted
## The WAIT freeze, drawn in ink: pale ice shards and frost lines around a
## frozen thing, with a little sparkle, so the player sees what stopped.

const ICE: Color = Color(0.78, 0.9, 1.0)


static func draw(ci: CanvasItem, center: Vector2, radius: float, tick: int, alpha: float = 1.0) -> void:
	if alpha <= 0.01:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 911
	ci.draw_arc(center, radius, 0.0, TAU, 32, Color(ICE, 0.35 * alpha), 3.0, true)
	for i in 10:
		var a: float = TAU * i / 10.0 + rng.randf_range(-0.2, 0.2)
		var base: Vector2 = center + Vector2.from_angle(a) * radius * rng.randf_range(0.7, 1.0)
		var tip: Vector2 = base + Vector2.from_angle(a) * radius * rng.randf_range(0.25, 0.5)
		var side: Vector2 = Vector2.from_angle(a).orthogonal() * radius * 0.06
		ci.draw_colored_polygon(PackedVector2Array([base - side, tip, base + side]), Color(ICE, 0.75 * alpha))
		ci.draw_polyline(PackedVector2Array([base - side, tip, base + side]), Color(InkDraw.INK, 0.6 * alpha), 1.5, true)
	var twinkle: int = tick % 4
	var spark: Vector2 = center + Vector2.from_angle(TAU * twinkle / 4.0 + 0.6) * radius * 0.8
	ci.draw_line(spark - Vector2(7, 0), spark + Vector2(7, 0), Color(InkDraw.WHITE, alpha), 2.0)
	ci.draw_line(spark - Vector2(0, 7), spark + Vector2(0, 7), Color(InkDraw.WHITE, alpha), 2.0)
