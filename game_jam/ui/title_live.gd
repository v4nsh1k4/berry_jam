class_name TitleLive
extends RefCounted
## The title page / menu backdrop's live layer over TitleArt's texture,
## stepped at the line-boil rate: the white centre's spiral of looping lines
## turning slowly, the crows' small pale eyes (a glint, a rare blink), a
## feather shiver now and then, and the one red thing: a tiny unperson
## standing in the middle. Plus TitleLettering with a dark smudge behind it.


static func draw(ci: CanvasItem, screen: Vector2, tick: int) -> void:
	var sc: Vector2 = screen / Vector2(TitleArt.SIZE)
	if TitleArt.texture != null:
		ci.draw_texture_rect(TitleArt.texture, Rect2(Vector2.ZERO, screen), false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, sc)
	var tq: float = tick * InkDraw.BOIL_INTERVAL_MS / 1000.0
	_spiral(ci, TitleArt.CENTRE, tq)
	for i in TitleArt.crows.size():
		var xf: Transform2D = TitleArt.crows[i][0]
		var eye: Vector2 = xf * CrowShapes.EYE
		var blink: bool = fposmod(tq + i * 1.37, 5.0 + i % 3) < 0.15
		var r: float = 6.0 * xf.get_scale().x
		ci.draw_colored_polygon(InkDraw.ellipse_points(eye, Vector2(r, r * (0.15 if blink else 0.85)), 12), Color(0.9, 0.88, 0.8))
		if not blink:
			ci.draw_circle(eye + Vector2(1, 0).rotated(xf.get_rotation()) * r * 0.3, r * 0.45, InkDraw.INK)
			ci.draw_circle(eye + Vector2(-r * 0.25, -r * 0.3), r * 0.22, Color(1, 1, 1, 0.95))
	# A feather shiver: one crow's wing tip trembles for a moment.
	var which: int = int(tq / 2.6) % maxi(TitleArt.crows.size(), 1)
	if fposmod(tq, 2.6) < 0.42 and not TitleArt.crows.is_empty():
		var xf2: Transform2D = TitleArt.crows[which][0]
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = tick
		for k in 4:
			var at: Vector2 = xf2 * (CrowShapes.WING_TIP + Vector2(rng.randf_range(-20, 20), rng.randf_range(-12, 12)))
			ci.draw_line(at, at + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12)), InkDraw.INK, 2.0)
	RevealArt.red_figure(ci, TitleArt.CENTRE + Vector2(0, 34), 0.42, tick)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Looping lines spiralling into the white centre, slowly turning.
static func _spiral(ci: CanvasItem, c: Vector2, tq: float) -> void:
	for arm in 2:
		var pts: PackedVector2Array = PackedVector2Array()
		for j in 480:
			var k: float = j / 479.0
			var th: float = k * TAU * 3.2 + tq * 0.25 + arm * PI
			var r: float = 26.0 + 190.0 * k
			pts.append(c + Vector2(cos(th), sin(th) * 0.72) * r + Vector2.from_angle(th * 6.0) * (8.0 + 20.0 * k))
		ci.draw_polyline(pts, Color(InkDraw.INK, 0.55), 1.4)


## A soft dark smudge (ink wash) so white lettering reads over the crows.
static func smudge(ci: CanvasItem, c: Vector2, radii: Vector2) -> void:
	for i in 16:
		var k: float = 1.0 - i / 16.0
		ci.draw_colored_polygon(InkDraw.ellipse_points(c, radii * (0.4 + 0.7 * k), 36), Color(0.03, 0.03, 0.04, 0.085))


## The title block: "ink-bleed" and the subtitle, scrawled in white.
static func title(ci: CanvasItem, c: Vector2, tick: int, alpha: float = 1.0) -> void:
	smudge(ci, c + Vector2(0, -12), Vector2(360, 96))
	TitleLettering.draw(ci, "ink-bleed", c, 46.0, tick, alpha)
	TitleLettering.draw(ci, "The Silent House of Hollow Hill", c + Vector2(0, 62), 12.0, tick + 1, alpha)
