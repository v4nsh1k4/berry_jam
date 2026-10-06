class_name RevealArtTear
extends RefCounted
## The reveal's "every theft tore the page" beat, over the cost screen: rips
## run down through the robbed characters (`tear` 0..1), then stitch closed
## with pale light (`mend` 0..1), the promise of giving the words back.

const RIPS: int = 4


static func tear(ci: CanvasItem, screen: Vector2, tear_k: float, mend: float, tick: int) -> void:
	if tear_k <= 0.0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3131
	for r in RIPS:
		var x: float = screen.x * (0.18 + r * 0.22) + rng.randf_range(-40, 40)
		var pts: PackedVector2Array = PackedVector2Array()
		var steps: int = 14
		var shown: int = int(ceil(steps * clampf(tear_k * 1.2 - r * 0.07, 0.0, 1.0)))
		for i in shown + 1:
			pts.append(Vector2(x + rng.randf_range(-26, 26), 120.0 + i * (screen.y - 160.0) / steps))
		if pts.size() < 2:
			continue
		var open: float = 7.0 * (1.0 - mend)
		ci.draw_polyline(pts, Color(0.05, 0.04, 0.06, 1.0 - mend * 0.8), 3.0 + open * 2.0, true)
		InkDraw.polyline(ci, pts, 2.0, tick + r, false, Color(InkDraw.PAPER, 0.7 * (1.0 - mend)))
		if mend > 0.0:
			var lit: int = int(pts.size() * mend)
			if lit >= 2:
				ci.draw_polyline(pts.slice(0, lit), Color(1.0, 0.95, 0.75, 0.9), 3.0, true)
