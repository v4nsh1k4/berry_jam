class_name ShadowView
extends CrawlerView
## How the Ink Shadow looks: a hand-sized nightmare. A wall of ink floods the
## panel behind it, five huge jointed fingers rise from a palm, a pen-nib for a
## head, and a crowd of pale eyes (red when it hunts).

const SCALE: float = 1.8


func _draw() -> void:
	var brain: InkCrawler = get_parent() as InkCrawler
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _pose_seed
	var rise: float = brain.rise
	var f: float = brain.facing
	# The wall of ink behind it, reaching back past the panel's left edge.
	if (brain as InkShadow).draws_wall:
		var wall: PackedVector2Array = PackedVector2Array([Vector2(-2000, 60), Vector2(-40, 60)])
		for i in 9:
			var y: float = 60.0 - i * 64.0
			wall.append(Vector2(-20 + rng.randf_range(-30, 30), y))
		wall.append(Vector2(-2000, -560))
		InkDraw.fill(self, wall, InkDraw.INK)
	if rise <= 0.05:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(SCALE, SCALE))
	var h: float = 250.0 * rise
	# Palm.
	var palm: PackedVector2Array = InkDraw.ellipse_points(Vector2(10 * f, -h * 0.35), Vector2(70, h * 0.32), 16)
	InkDraw.fill(self, palm, InkDraw.INK)
	# Five fingers fanning up and forward, jointed, nib-tipped.
	for i in 5:
		var base: Vector2 = Vector2((-40 + i * 22) * f, -h * 0.55)
		var angle: float = Vector2(f * (0.15 + i * 0.22), -1.0).angle()
		CrawlerArt.finger(self, base, angle, h * (0.55 + 0.08 * (2 - absi(i - 2))), 5, rng.randi(), 7.0, 0.22 * f)
	# Pen-nib head with its slit and breather hole.
	var top: Vector2 = Vector2(30 * f, -h * 0.95)
	var nib: PackedVector2Array = PackedVector2Array([
		top + Vector2(-42, 40), top + Vector2(0, -70), top + Vector2(42, 40), top + Vector2(0, 70)])
	InkDraw.fill(self, nib, InkDraw.INK)
	InkDraw.polyline(self, nib, 6.0, _pose_seed, true, InkDraw.INK, 3.0)
	draw_line(top + Vector2(0, -60), top + Vector2(0, 10), CrawlerArt.PALE, 2.0, true)
	draw_circle(top + Vector2(0, 14), 5.0, CrawlerArt.PALE)
	# A crowd of uneven eyes over the nib and palm. Listening (the lair
	# variant): they open wide and white.
	var listen: float = (brain as HeartShadow).listening if brain is HeartShadow else 0.0
	var eye: Color = InkDraw.RED if brain.is_hunting() else CrawlerArt.PALE.lerp(InkDraw.WHITE, listen)
	for i in 11:
		var at: Vector2 = Vector2(rng.randf_range(-60, 60) * f, -h * rng.randf_range(0.2, 0.9))
		draw_circle(at, rng.randf_range(1.6, 4.5) * (1.0 + listen * 0.9), eye)
	draw_set_transform(Vector2.ZERO)
