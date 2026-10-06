class_name TitleLettering
extends RefCounted
## The title's hand-scrawled lettering (Stage 6): a small stroke font of
## polylines (no font files), thin white strokes with tapered ends, wide and
## uneven letter spacing, a wobbling baseline, loop-and-cross letterforms, a
## faint glow and the odd drip. Each text is built into one triangle array
## (glow + strokes), rebuilt only when the line boil ticks, and drawn with a
## single call. Glyph units: x-height = 1, baseline y = 0, up is negative.

const INK_WHITE: Color = Color(0.97, 0.96, 0.92)
## Glyph: [advance, [stroke, stroke...]], strokes as flat [x, y, x, y, ...].
## Built at runtime (nested constant arrays read back empty in web exports).
static func glyphs() -> Dictionary:
	if _glyphs.is_empty():
		_glyphs = _glyph_table()
	return _glyphs


static var _glyphs: Dictionary = {}


static func _glyph_table() -> Dictionary:
	return {
		"i": [0.42, [[0.12, -0.95, 0.1, -0.4, 0.16, 0.02, 0.3, -0.08], [0.1, -1.42, 0.16, -1.36]]],
		"n": [0.82, [[0.06, -0.98, 0.07, 0.02], [0.07, -0.62, 0.26, -0.98, 0.52, -0.96, 0.6, -0.5, 0.62, 0.0, 0.76, -0.1]]],
		"k": [0.78, [[0.0, -0.05, 0.08, -1.3, 0.28, -1.82, 0.36, -1.6, 0.1, -1.0, 0.07, 0.03],
			[0.62, -1.02, 0.18, -0.58, 0.02, -0.5, 0.2, -0.46, 0.42, -0.3, 0.66, 0.04]]],
		"-": [0.6, [[0.06, -0.52, 0.3, -0.58, 0.5, -0.5]]],
		"b": [0.8, [[0.02, 0.0, 0.1, -1.3, 0.3, -1.84, 0.38, -1.6, 0.1, -1.0, 0.06, -0.1],
			[0.07, -0.6, 0.32, -1.0, 0.6, -0.82, 0.62, -0.25, 0.34, 0.03, 0.06, -0.12]]],
		"l": [0.5, [[0.0, -0.12, 0.16, -0.9, 0.3, -1.6, 0.24, -1.86, 0.1, -1.62, 0.1, -0.4, 0.2, 0.02, 0.38, -0.06]]],
		"e": [0.72, [[0.06, -0.46, 0.56, -0.62, 0.48, -0.96, 0.24, -1.0, 0.04, -0.7, 0.08, -0.14, 0.36, 0.03, 0.62, -0.14]]],
		"d": [0.86, [[0.56, -0.78, 0.3, -1.0, 0.05, -0.76, 0.04, -0.2, 0.3, 0.03, 0.56, -0.32],
			[0.56, 0.04, 0.56, -1.36, 0.7, -1.86, 0.82, -1.7, 0.58, -1.2]]],
		"h": [0.8, [[0.04, 0.03, 0.08, -1.36, 0.26, -1.86, 0.32, -1.62, 0.08, -1.0],
			[0.07, -0.58, 0.3, -1.0, 0.56, -0.9, 0.58, 0.0, 0.7, -0.08]]],
		"o": [0.76, [[0.36, -1.0, 0.08, -0.86, 0.04, -0.24, 0.3, 0.03, 0.6, -0.2, 0.62, -0.8, 0.34, -1.02, 0.16, -0.96, 0.5, -1.18]]],
		"s": [0.68, [[0.56, -0.9, 0.3, -1.02, 0.08, -0.82, 0.2, -0.56, 0.5, -0.4, 0.56, -0.14, 0.3, 0.03, 0.02, -0.14]]],
		"t": [0.6, [[0.24, -1.52, 0.2, -0.2, 0.3, 0.03, 0.5, -0.1], [0.0, -0.98, 0.3, -1.12, 0.54, -1.04]]],
		"u": [0.78, [[0.04, -1.0, 0.05, -0.24, 0.26, 0.03, 0.52, -0.2, 0.56, -1.0], [0.56, -1.0, 0.58, 0.0, 0.7, -0.1]]],
		"f": [0.6, [[0.56, -1.64, 0.36, -1.86, 0.2, -1.6, 0.2, 0.3, 0.12, 0.62], [0.0, -0.98, 0.3, -1.1, 0.52, -1.02]]],
		"w": [0.9, [[0.0, -1.0, 0.12, 0.03, 0.34, -0.7, 0.52, 0.03, 0.72, -1.02, 0.84, -1.12]]],
		"T": [0.94, [[-0.04, -1.6, 0.06, -1.82, 0.5, -1.76, 0.9, -1.86], [0.46, -1.78, 0.42, -0.2, 0.36, 0.03, 0.22, -0.06]]],
		"S": [0.84, [[0.76, -1.6, 0.52, -1.84, 0.16, -1.62, 0.2, -1.12, 0.6, -0.84, 0.72, -0.3, 0.42, 0.03, 0.06, -0.2]]],
		"H": [0.92, [[0.06, -1.82, 0.08, 0.03], [0.68, -1.84, 0.64, 0.03], [-0.06, -0.84, 0.4, -0.98, 0.84, -0.92]]],
		" ": [0.55, []],
	}


## Letters that get a drip, per text (index into the string).
static func _drips(text: String) -> Array:
	return {"ink-bleed": [1, 6], "The Silent House of Hollow Hill": [11, 20]}.get(text, [])

## [tick, text, size] -> [indices, points, colors]
static var _cache: Dictionary = {}


## Draws `text` with its centre at `centre` (baseline), x-height `size` px.
static func draw(ci: CanvasItem, text: String, centre: Vector2, size: float, tick: int, alpha: float = 1.0) -> void:
	var key: String = "%s|%d|%d" % [text, int(size), tick]
	if not _cache.has(key):
		if _cache.size() > 24:
			_cache.clear()
		_cache[key] = _build(text, size, tick)
	var built: Array = _cache[key]
	var colors: PackedColorArray = built[2]
	if alpha < 1.0:
		colors = colors.duplicate()
		for i in colors.size():
			colors[i].a *= alpha
	var xf: Transform2D = Transform2D(0.0, centre)
	RenderingServer.canvas_item_add_set_transform(ci.get_canvas_item(), xf)
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), built[0], built[1], colors)
	RenderingServer.canvas_item_add_set_transform(ci.get_canvas_item(), Transform2D.IDENTITY)


## Width of `text` at x-height `size` (spacing included, before the jitter).
static func width(text: String, size: float) -> float:
	var w: float = 0.0
	for ch in text:
		w += float(glyphs().get(ch, glyphs()[" "])[0]) * 1.28 * size
	return w


static func _build(text: String, size: float, tick: int) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(text)
	var boil: RandomNumberGenerator = RandomNumberGenerator.new()
	boil.seed = tick * 7919 + hash(text)
	var out: Array = [PackedInt32Array(), PackedVector2Array(), PackedColorArray()]
	var glow: Array = [PackedInt32Array(), PackedVector2Array(), PackedColorArray()]
	var x: float = -width(text, size) * 0.5
	var stroke_w: float = maxf(1.3, size * 0.075)
	var drips: Array = _drips(text)
	for n in text.length():
		var glyph: Array = glyphs().get(text[n], glyphs()[" "])
		# Wide, uneven spacing; a wobbling baseline; each letter leans a bit.
		var base: Vector2 = Vector2(x, sin(n * 1.7 + 0.4) * size * 0.12)
		var lean: float = rng.randf_range(-0.12, 0.08)
		for stroke in glyph[1]:
			var pts: PackedVector2Array = PackedVector2Array()
			for i in range(0, (stroke as Array).size(), 2):
				var p: Vector2 = Vector2(stroke[i] - stroke[i + 1] * lean, stroke[i + 1]) * size
				pts.append(base + p + Vector2(boil.randf_range(-1.0, 1.0), boil.randf_range(-1.0, 1.0)) * size * 0.025)
			pts = _smooth(pts)
			_ribbon(glow, pts, stroke_w * 3.2, Color(INK_WHITE, 0.08))
			_ribbon(out, pts, stroke_w, INK_WHITE)
		if n in drips:
			var top: Vector2 = base + Vector2(float(glyph[0]) * 0.4 * size, 0.02 * size)
			var length: float = size * rng.randf_range(0.5, 0.9)
			_ribbon(out, PackedVector2Array([top, top + Vector2(0.5, length)]), stroke_w * 0.7, INK_WHITE)
			_dot(out, top + Vector2(0.5, length + stroke_w), stroke_w * 0.9, INK_WHITE)
		x += float(glyph[0]) * size * rng.randf_range(1.15, 1.42)
	# Glow under the strokes: one array, glow triangles first.
	var n0: int = glow[1].size()
	for i in (out[0] as PackedInt32Array):
		glow[0].append(i + n0)
	glow[1].append_array(out[1])
	glow[2].append_array(out[2])
	return glow


## Catmull-Rom-ish smoothing: 3 points per segment.
static func _smooth(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() == 2:
		# A straight stroke: points along it, so only its ends taper.
		var line: PackedVector2Array = PackedVector2Array()
		for k in 7:
			line.append(pts[0].lerp(pts[1], k / 6.0))
		return line
	if pts.size() < 3:
		return pts
	var out: PackedVector2Array = PackedVector2Array([pts[0]])
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		for k in [0.33, 0.66, 1.0]:
			out.append(p1.cubic_interpolate(p2, p0, p3, k))
	return out


## A tapered ribbon along `pts` (thin at both ends) appended as triangles.
static func _ribbon(arr: Array, pts: PackedVector2Array, w: float, color: Color) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var start: int = (arr[1] as PackedVector2Array).size()
	for i in n:
		var d: Vector2 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var k: float = float(i) / (n - 1)
		var half: float = w * 0.5 * (0.25 + 0.75 * pow(sin(PI * k), 0.6))
		arr[1].append(pts[i] + d.orthogonal() * half)
		arr[1].append(pts[i] - d.orthogonal() * half)
		arr[2].append(color)
		arr[2].append(color)
	for i in n - 1:
		var a: int = start + i * 2
		arr[0].append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])


static func _dot(arr: Array, c: Vector2, r: float, color: Color) -> void:
	var start: int = (arr[1] as PackedVector2Array).size()
	arr[1].append(c)
	arr[2].append(color)
	for i in 8:
		arr[1].append(c + Vector2.from_angle(TAU * i / 8.0) * r)
		arr[2].append(color)
	for i in 8:
		arr[0].append_array([start, start + 1 + i, start + 1 + (i + 1) % 8])
