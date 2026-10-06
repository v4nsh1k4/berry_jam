class_name LightPuzzleArt
extends RefCounted
## Drawing for the flashlight puzzle kinds (LightPuzzle) and the lever.

const KINDS: Array[StringName] = [&"light_ink", &"lens", &"lit_writing", &"shadow_puzzle", &"lever"]
const PALE: Color = Color(0.92, 0.9, 0.82)
const IRON: Color = Color(0.25, 0.24, 0.27)
## shadow_puzzle: the outline on the wall, above the object (local coords).
const OUTLINE_LIFT: float = 170.0
const OUTLINE_R: float = 34.0


static func handles(kind: StringName) -> bool:
	return KINDS.has(kind)


static func draw(item: Interactable, tick: int) -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, item.data.size)
	var s: int = tick * 31
	match item.data.kind:
		&"light_ink":
			_light_ink(item as LightPuzzle, r, s)
		&"lens":
			_lens(item as LightPuzzle, r, s)
		&"lit_writing":
			InteractableArt2._writing(item, r, s)
		&"shadow_puzzle":
			_shadow_puzzle(item as LightPuzzle, r, s)
		&"lever":
			_lever(item, r, s)


## Ink that the light burns back: a hanging sheet (door), a floor pool, or
## thorny growth. Pale eyes blink in it; it hisses while lit.
static func _light_ink(item: LightPuzzle, r: Rect2, s: int) -> void:
	var left: float = 1.0 - item.progress
	if left <= 0.01:
		return
	var look: StringName = StringName(item.data.text)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2024
	match look:
		&"pool":
			var c: Vector2 = Vector2(r.size.x * 0.5, r.size.y * 0.7)
			item.draw_colored_polygon(InkDraw.ellipse_points(c, Vector2(r.size.x * 0.5, r.size.y * 0.3) * left, 22), InkDraw.INK)
		&"growth":
			for i in 9:
				var base: Vector2 = Vector2(rng.randf_range(0.0, r.size.x), r.size.y)
				var tip: Vector2 = base + Vector2(rng.randf_range(-40, 40), -r.size.y * rng.randf_range(0.6, 1.0) * left)
				InkDraw.line(item, base, tip, 10.0 * left + 3.0, s + i, InkDraw.INK, 3.0)
				InkDraw.line(item, base + Vector2(4, 0), tip + Vector2(2, 0), 1.5, s + 60 + i, Color(PALE, 0.55), 3.0)
				CrawlerArt.nib(item, tip, (tip - base).angle(), 7.0)
			item.draw_rect(Rect2(0, r.size.y - 18.0 * left, r.size.x, 18.0 * left), InkDraw.INK)
		_:
			var h: float = r.size.y * left
			var sheet: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0)])
			for i in 7:
				var x: float = r.size.x * (1.0 - i / 6.0)
				sheet.append(Vector2(x, h + sin(i * 2.1 + s * 0.01) * 10.0 * left))
			item.draw_colored_polygon(sheet, InkDraw.INK)
			InkDraw.polyline(item, sheet.slice(1), 2.0, s + 70, false, Color(PALE, 0.5), 2.5)
			for i in 4:
				var x2: float = rng.randf_range(10, r.size.x - 10)
				InkDraw.line(item, Vector2(x2, h - 4), Vector2(x2, h + rng.randf_range(10, 40) * left), 4.0, s + 20 + i, InkDraw.INK, 1.0)
	var eye_y: float = r.size.y * (0.35 if look != &"pool" else 0.68)
	if (s / 31) % 9 != 0:
		for i in 2:
			item.draw_circle(Vector2(r.size.x * 0.5 + (i * 2 - 1) * 9.0, eye_y), 3.5 * left + 1.0, Color(PALE, left))
	if item.lit_now:
		for i in 6:
			var p: Vector2 = Vector2(rng.randf_range(0, r.size.x), rng.randf_range(r.size.y * 0.1, r.size.y))
			InkDraw.line(item, p, p + Vector2(rng.randf_range(-6, 6), -18), 2.0, s + 40 + i, Color(PALE, 0.7), 3.0)


## A round glass on a bracket. Lit, it warms; done, it throws a beam along
## push_offset (towards whatever it lights in another place).
static func _lens(item: LightPuzzle, r: Rect2, s: int) -> void:
	var c: Vector2 = r.get_center()
	InkDraw.line(item, c, Vector2(c.x, r.size.y), 4.0, s, IRON)
	var glow: Color = Color(1.0, 0.95, 0.7, 0.25 + 0.65 * item.progress)
	InkDraw.ellipse(item, c, Vector2(r.size.x, r.size.y) * 0.32, 4.0, s + 1, glow, IRON)
	if item.resolved:
		var to: Vector2 = c + item.data.push_offset
		item.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), to + Vector2(0, -40), to + Vector2(0, 40), c + Vector2(0, 8)]),
			Color(1.0, 0.95, 0.7, 0.22))


## The iron shape on its stand, the chalk mark to stand on, the outline on
## the wall, and (lit) the shadow sliding towards the outline.
static func _shadow_puzzle(item: LightPuzzle, r: Rect2, s: int) -> void:
	var symbol: StringName = StringName(item.data.symbols[0]) if not item.data.symbols.is_empty() else &"key"
	var top: Vector2 = Vector2(r.size.x * 0.5, r.size.y * 0.3)
	InkDraw.line(item, Vector2(top.x, r.size.y), top, 5.0, s, IRON)
	InkDraw.line(item, Vector2(top.x - 26, r.size.y), Vector2(top.x + 26, r.size.y), 5.0, s + 1, IRON)
	SymbolArt.draw(item, symbol, top, 26.0, s + 2, IRON, 6.0)
	# The chalk X where the light must come from.
	var spot: Rect2 = item.data.stand_spot
	var x: Vector2 = spot.get_center() - item.data.position
	var chalk: Color = Color(1.0, 1.0, 0.95)
	InkDraw.line(item, x + Vector2(-22, -10), x + Vector2(22, 10), 5.0, s + 3, chalk)
	InkDraw.line(item, x + Vector2(-22, 10), x + Vector2(22, -10), 5.0, s + 4, chalk)
	var outline_c: Vector2 = top + Vector2(0, -OUTLINE_LIFT)
	var done: bool = item.resolved
	InkDraw.rect(item, Rect2(outline_c - Vector2(56, 56), Vector2(112, 112)), 3.0, s + 5, Color(0.5, 0.42, 0.3, 0.5), IRON)
	SymbolArt.draw(item, symbol, outline_c, OUTLINE_R, s + 6, Color(0.95, 0.9, 0.75, 0.9) if done else Color(PALE, 0.7), 4.0)
	if done or not item.lit_now:
		return
	# Off the mark the shadow is stretched and slides away from the outline.
	var off: float = item.shadow_offset
	var c: Vector2 = outline_c + Vector2(off * 220.0, absf(off) * 30.0)
	var stretch: float = 1.0 + absf(off) * 0.8
	item.draw_set_transform(c, off * 0.6, Vector2(stretch, 1.0 / stretch))
	SymbolArt.draw(item, symbol, Vector2.ZERO, OUTLINE_R, s + 7, Color(0, 0, 0, 0.55 + 0.35 * item.progress), 8.0)
	item.draw_set_transform(Vector2.ZERO)


## A wall lever, only visible in the light until pulled.
static func _lever(item: Interactable, r: Rect2, s: int) -> void:
	if item.data.requires_flag != &"" and not GameState.has_flag(item.data.requires_flag):
		return
	var a: float = 1.0 if item.resolved or not item.data.revealed_by_light else item.reveal
	if a <= 0.02:
		return
	var plate: Rect2 = Rect2(r.size.x * 0.25, r.size.y * 0.3, r.size.x * 0.5, r.size.y * 0.6)
	InkDraw.rect(item, plate, 3.0, s, Color(IRON, a), Color(InkDraw.INK, a))
	var pivot: Vector2 = plate.get_center()
	var angle: float = (0.7 if item.resolved else -0.7) - PI * 0.5
	var tip: Vector2 = pivot + Vector2.from_angle(angle) * r.size.y * 0.5
	InkDraw.line(item, pivot, tip, 6.0, s + 1, Color(InkDraw.INK, a))
	item.draw_circle(tip, 8.0, Color(Color(0.8, 0.7, 0.4) if not item.resolved else IRON, a))
