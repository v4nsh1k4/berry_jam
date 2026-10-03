class_name InkDraw
extends RefCounted
## Hand-drawn ink helpers. Lines are subdivided and jittered from a seed, so
## redrawing with a new seed every BOIL_INTERVAL_MS gives the "line boil" look.

const INK: Color = Color(0.06, 0.05, 0.07)
const PAPER: Color = Color(0.94, 0.91, 0.84)
const WHITE: Color = Color(1, 1, 1)
## The ONE accent colour. Red means the player, danger or damage; nothing
## else in the comic's world is coloured.
const RED: Color = Color(0.784, 0.063, 0.18)
const BOIL_INTERVAL_MS: int = 140
const STEP: float = 22.0

## Wobble multiplier for the whole comic (raised in later chapters).
static var jitter_scale: float = 1.0

## 0..1 share of line segments left out, for characters drawn "unfinished".
## Set it around a draw call and put it back to 0 afterwards.
static var gap_ratio: float = 0.0


static func boil_tick() -> int:
	return int(Time.get_ticks_msec() / BOIL_INTERVAL_MS)


static func wobble(points: PackedVector2Array, jitter: float, seed_value: int, closed: bool = false) -> PackedVector2Array:
	jitter *= jitter_scale
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: PackedVector2Array = PackedVector2Array()
	var count: int = points.size()
	var segments: int = count if closed else count - 1
	for i in segments:
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % count]
		var steps: int = maxi(1, int(a.distance_to(b) / STEP))
		for s in steps:
			var p: Vector2 = a.lerp(b, float(s) / steps)
			out.append(p + Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter)))
	var last: Vector2 = points[0] if closed else points[count - 1]
	out.append(last + Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter)))
	if closed:
		out[out.size() - 1] = out[0]
	return out


static func line(ci: CanvasItem, from: Vector2, to: Vector2, width: float, seed_value: int, color: Color = INK, jitter: float = 1.2) -> void:
	ci.draw_polyline(wobble(PackedVector2Array([from, to]), jitter, seed_value), color, width, true)


static func polyline(ci: CanvasItem, points: PackedVector2Array, width: float, seed_value: int, closed: bool = false, color: Color = INK, jitter: float = 1.2) -> void:
	var pts: PackedVector2Array = wobble(points, jitter, seed_value, closed)
	if gap_ratio <= 0.0:
		ci.draw_polyline(pts, color, width, true)
		return
	# "Unfinished" ink: skip some segments. Seeded without the boil so the
	# gaps stay put while the line wobbles.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = pts.size() * 7919 + int(width * 13.0)
	for i in pts.size() - 1:
		if rng.randf() >= gap_ratio:
			ci.draw_line(pts[i], pts[i + 1], color, width, true)


static func rect_points(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func rect(ci: CanvasItem, r: Rect2, width: float, seed_value: int, fill: Color = Color.TRANSPARENT, color: Color = INK, jitter: float = 1.2) -> void:
	if fill.a > 0.0:
		ci.draw_rect(r, fill)
	polyline(ci, rect_points(r), width, seed_value, true, color, jitter)


static func ellipse_points(center: Vector2, radii: Vector2, segments: int = 28) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in segments:
		var t: float = TAU * i / segments
		pts.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y))
	return pts


static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, width: float, seed_value: int, fill: Color = Color.TRANSPARENT, color: Color = INK, jitter: float = 1.0) -> void:
	var pts: PackedVector2Array = ellipse_points(center, radii)
	if fill.a > 0.0:
		ci.draw_colored_polygon(pts, fill)
	polyline(ci, pts, width, seed_value, true, color, jitter)


## Fills a jittery outline even if the jitter folded it over itself
## (falls back to its convex hull instead of failing to triangulate).
static func fill(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	if Geometry2D.triangulate_polygon(points).is_empty():
		points = Geometry2D.convex_hull(points)
	ci.draw_colored_polygon(points, color)


static func shape(ci: CanvasItem, points: PackedVector2Array, width: float, seed_value: int, fill: Color = PAPER, color: Color = INK, jitter: float = 1.2) -> void:
	ci.draw_colored_polygon(points, fill)
	polyline(ci, points, width, seed_value, true, color, jitter)


## 45-degree hatching clipped to a rect.
static func hatch(ci: CanvasItem, r: Rect2, spacing: float, width: float, seed_value: int, color: Color = INK) -> void:
	var c: float = r.position.x + r.position.y + spacing
	var c_end: float = r.end.x + r.end.y
	var n: int = 0
	while c < c_end:
		var xa: float = maxf(r.position.x, c - r.end.y)
		var xb: float = minf(r.end.x, c - r.position.y)
		if xb - xa > 2.0:
			line(ci, Vector2(xa, c - xa), Vector2(xb, c - xb), width, seed_value + n, color, 0.8)
		c += spacing
		n += 1
