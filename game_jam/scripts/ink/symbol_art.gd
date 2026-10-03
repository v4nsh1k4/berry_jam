class_name SymbolArt
extends RefCounted
## The small set of ink symbols used by memory sketches and symbol locks.

const ALL: PackedStringArray = ["moon", "eye", "key", "hand", "spiral", "house", "nib"]


static func draw(ci: CanvasItem, symbol: StringName, c: Vector2, r: float, seed_value: int, color: Color = InkDraw.INK, width: float = 3.0) -> void:
	match symbol:
		&"moon":
			var outer: PackedVector2Array = PackedVector2Array()
			for i in 13:
				var t: float = lerpf(PI * 0.35, PI * 1.65, i / 12.0)
				outer.append(c + Vector2(cos(t), sin(t)) * r)
			for i in 13:
				var t: float = lerpf(PI * 1.5, PI * 0.5, i / 12.0)
				outer.append(c + Vector2(r * 0.15 + cos(t) * r * 0.55, sin(t) * r * 0.82))
			InkDraw.polyline(ci, outer, width, seed_value, true, color, 0.8)
		&"eye":
			var lid: PackedVector2Array = PackedVector2Array()
			for i in 9:
				var x: float = lerpf(-r, r, i / 8.0)
				lid.append(c + Vector2(x, -sqrt(maxf(0.0, 1.0 - pow(x / r, 2.0))) * r * 0.55))
			for i in range(7, 0, -1):
				var x: float = lerpf(-r, r, i / 8.0)
				lid.append(c + Vector2(x, sqrt(maxf(0.0, 1.0 - pow(x / r, 2.0))) * r * 0.55))
			InkDraw.polyline(ci, lid, width, seed_value, true, color, 0.8)
			ci.draw_circle(c, r * 0.24, color)
		&"key":
			InkDraw.ellipse(ci, c + Vector2(-r * 0.55, 0), Vector2(r * 0.38, r * 0.38), width, seed_value, Color.TRANSPARENT, color, 0.6)
			InkDraw.line(ci, c + Vector2(-r * 0.17, 0), c + Vector2(r, 0), width, seed_value + 1, color, 0.6)
			InkDraw.line(ci, c + Vector2(r * 0.7, 0), c + Vector2(r * 0.7, r * 0.4), width, seed_value + 2, color, 0.6)
			InkDraw.line(ci, c + Vector2(r * 0.4, 0), c + Vector2(r * 0.4, r * 0.3), width, seed_value + 3, color, 0.6)
		&"hand":
			InkDraw.ellipse(ci, c + Vector2(0, r * 0.35), Vector2(r * 0.5, r * 0.5), width, seed_value, Color.TRANSPARENT, color, 0.6)
			for i in 4:
				var x: float = lerpf(-r * 0.4, r * 0.4, i / 3.0)
				InkDraw.line(ci, c + Vector2(x, -r * 0.05), c + Vector2(x * 1.15, -r * (0.75 + 0.15 * float(i % 3 == 1))), width, seed_value + i, color, 0.6)
			InkDraw.line(ci, c + Vector2(-r * 0.45, r * 0.3), c + Vector2(-r * 0.95, -r * 0.05), width, seed_value + 9, color, 0.6)
		&"spiral":
			var pts: PackedVector2Array = PackedVector2Array()
			for i in 40:
				var t: float = i / 39.0 * TAU * 2.2
				pts.append(c + Vector2(cos(t), sin(t)) * r * (0.08 + 0.92 * i / 39.0))
			InkDraw.polyline(ci, pts, width, seed_value, false, color, 0.6)
		&"house":
			InkDraw.polyline(ci, PackedVector2Array([c + Vector2(-r, -r * 0.1), c + Vector2(0, -r), c + Vector2(r, -r * 0.1)]), width, seed_value, false, color, 0.6)
			InkDraw.rect(ci, Rect2(c + Vector2(-r * 0.75, -r * 0.1), Vector2(r * 1.5, r)), width, seed_value + 1, Color.TRANSPARENT, color, 0.6)
		&"nib":
			# A pen nib, point down: the Artist's mark.
			var nib: PackedVector2Array = PackedVector2Array([c + Vector2(0, r), c + Vector2(-r * 0.55, -r * 0.1),
				c + Vector2(-r * 0.4, -r * 0.8), c + Vector2(r * 0.4, -r * 0.8), c + Vector2(r * 0.55, -r * 0.1)])
			InkDraw.polyline(ci, nib, width, seed_value, true, color, 0.6)
			InkDraw.line(ci, c + Vector2(0, r * 0.95), c + Vector2(0, -r * 0.05), width * 0.7, seed_value + 1, color, 0.4)
			ci.draw_circle(c + Vector2(0, -r * 0.18), r * 0.13, color)
		_:
			InkDraw.ellipse(ci, c, Vector2(r, r), width, seed_value, Color.TRANSPARENT, color)
