class_name HandFloorArt
extends RefCounted
## What the Artist's hand leaves on the floor: the eraser's shadow while it
## aims (the warning: a hatched strip that darkens as it comes down, with the
## eraser's own block-shaped shadow in the middle tightening as it nears), the
## rubbed strip and crumbs while it rubs, and grey smudges that fade after.

const SMUDGE: Color = Color(0.55, 0.54, 0.53)


## `floor_band` = (top y, bottom y) of the floor; `progress` 0..1 through the
## current aim or rub; `smudges` are (x, alpha).
static func draw(ci: CanvasItem, aiming: bool, rubbing: bool, x: float, width: float, floor_band: Vector2,
		progress: float, smudges: Array[Vector2], tick: int) -> void:
	for smudge in smudges:
		var c: Vector2 = Vector2(smudge.x, (floor_band.x + floor_band.y) * 0.5)
		InkDraw.fill(ci, InkDraw.ellipse_points(c, Vector2(width * 0.45, 34), 18), Color(SMUDGE, 0.45 * smudge.y))
	if not aiming and not rubbing:
		return
	var strip: Rect2 = Rect2(x - width * 0.5, floor_band.x, width, floor_band.y - floor_band.x)
	var dark: float = 0.12 + 0.4 * progress if aiming else 0.6
	ci.draw_rect(strip, Color(InkDraw.INK, dark * 0.5))
	InkDraw.hatch(ci, strip, lerpf(16.0, 7.0, progress) if aiming else 6.0, 1.5, tick * 5, Color(InkDraw.INK, dark))
	# The eraser block's own shadow, sharper and darker as it comes down.
	var near: float = progress if aiming else 1.0
	var block: Vector2 = Vector2(lerpf(width * 0.5, width * 0.3, near), lerpf(30.0, 18.0, near))
	var centre: Vector2 = Vector2(x, floor_band.x + (floor_band.y - floor_band.x) * 0.45)
	var pts: PackedVector2Array = PackedVector2Array([centre + Vector2(-block.x, -block.y * 0.4), centre + Vector2(block.x * 0.7, -block.y),
		centre + Vector2(block.x, block.y * 0.4), centre + Vector2(-block.x * 0.7, block.y)])
	InkDraw.fill(ci, pts, Color(InkDraw.INK, 0.2 + 0.45 * near))
	# Dashed edges: where it will come down. Step out of them.
	for edge in [strip.position.x, strip.end.x]:
		for i in 6:
			var y: float = strip.position.y + i * strip.size.y / 6.0
			ci.draw_line(Vector2(edge, y), Vector2(edge, y + strip.size.y / 12.0), InkDraw.INK, 3.0, true)
	if rubbing:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = tick
		for i in 18:
			var p: Vector2 = Vector2(rng.randf_range(strip.position.x, strip.end.x), rng.randf_range(strip.position.y, strip.end.y))
			ci.draw_circle(p, rng.randf_range(2.0, 5.0), SMUDGE)
