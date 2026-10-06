class_name CrowShapes
extends RefCounted
## One crow as hatchable masses for TitleArt (local space: beak toward +x,
## back up, ~330 px from tail to beak). Each part is [polygon, hatch angles,
## stroke spacing]: denser spacing and more angles read darker.

## Where the eye sits (TitleLive draws it, pale with a glint).
const EYE: Vector2 = Vector2(84, -36)
## A wing tip that shivers now and then (TitleLive).
const WING_TIP: Vector2 = Vector2(-40, -200)


static func parts(spread: bool) -> Array:
	var out: Array = []
	# Tail: a fan of long feathers.
	for i in 4:
		out.append([leaf(Vector2(-60, 4), PI + (i - 1.5) * 0.16, 120.0 - absf(i - 1.5) * 10.0, 30.0), [0.35, -0.55], 2.3])
	out.append([InkDraw.ellipse_points(Vector2(0, 0), Vector2(82, 42), 22), [0.9, -0.35, 0.15], 2.0])
	out.append([InkDraw.ellipse_points(Vector2(70, -30), Vector2(32, 30), 18), [1.2, -0.9], 1.9])
	out.append([PackedVector2Array([Vector2(96, -42), Vector2(156, -26), Vector2(98, -16)]), [0.1], 3.1])
	if spread:
		# The near wing raised: coverts, then primaries fanning up and back.
		out.append([PackedVector2Array([Vector2(40, -30), Vector2(-10, -60), Vector2(-70, -110), Vector2(-40, -40), Vector2(10, -16)]),
			[0.6, -0.8], 2.1])
		for i in 6:
			var a: float = -PI * 0.55 - i * 0.13
			out.append([leaf(Vector2(-10 - i * 9, -46 - i * 4), a, 170.0 - i * 9.0, 34.0), [0.25, -0.75], 2.2])
		# The far wing, lower and smaller, behind the body.
		for i in 3:
			out.append([leaf(Vector2(-6, 26), PI * 0.62 + i * 0.16, 110.0 - i * 10.0, 28.0), [0.5], 2.4])
	else:
		# Folded: one long wing over the body, its tips split into feathers.
		out.append([PackedVector2Array([Vector2(56, -24), Vector2(-10, -44), Vector2(-90, -26), Vector2(-40, 8), Vector2(20, 6)]),
			[0.7, -0.6], 2.0])
		for i in 3:
			out.append([leaf(Vector2(-70, -16 + i * 10), PI - 0.18 + i * 0.12, 90.0, 22.0), [0.3, -0.6], 2.2])
		for i in 2:
			out.append([leaf(Vector2(10 + i * 18, 34), PI * 0.5 + 0.1, 46.0, 9.0), [0.0], 2.0])
	return out


## A feather: a pointed leaf from `base` along `angle`.
static func leaf(base: Vector2, angle: float, length: float, width: float) -> PackedVector2Array:
	var d: Vector2 = Vector2.from_angle(angle)
	var n: Vector2 = d.orthogonal()
	return PackedVector2Array([base, base + d * length * 0.28 + n * width * 0.5, base + d * length * 0.72 + n * width * 0.38,
		base + d * length, base + d * length * 0.72 - n * width * 0.32, base + d * length * 0.28 - n * width * 0.45])
