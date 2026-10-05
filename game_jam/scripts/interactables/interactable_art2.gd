class_name InteractableArt2
extends RefCounted
## Drawing for the Chapter 2 kinds: hiding spots, light-revealed writing, the
## grandfather clock, the hidden latch, the secret panel door, the dial box.

const WOOD: Color = Color(0.78, 0.75, 0.68)
const DARK_WOOD: Color = Color(0.2, 0.19, 0.22)
const VOID: Color = Color(0.04, 0.04, 0.05)
const KINDS: Array[StringName] = [&"hiding_spot", &"writing", &"clock", &"secret_door", &"latch", &"return_spot"]


static func handles(kind: StringName) -> bool:
	return KINDS.has(kind)


static func draw(item: Interactable, tick: int) -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, item.data.size)
	var s: int = tick * 31
	match item.data.kind:
		&"hiding_spot":
			_hiding_spot(item, r, s)
		&"writing":
			_writing(item, r, s)
		&"clock":
			_clock(item, r, s)
		&"secret_door":
			_secret_door(item, r, s)
		&"latch":
			_latch(item, r, s)
		&"return_spot":
			_return_spot(item, r, s)


static func _hiding_spot(ci: Interactable, r: Rect2, s: int) -> void:
	if (ci as HidingSpot) != null and (ci as HidingSpot).erased:
		# Only a smear of ink is left where it was.
		InkDraw.fill(ci, PackedVector2Array([Vector2(0, r.size.y), Vector2(r.size.x * 0.3, r.size.y - 14), Vector2(r.size.x, r.size.y - 4), Vector2(r.size.x, r.size.y)]), InkDraw.INK)
		return
	match ci.data.text:
		"curtain":
			InkDraw.line(ci, Vector2(-10, 0), Vector2(r.size.x + 10, 0), 5.0, s)
			var folds: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0)])
			for i in 7:
				folds.append(Vector2(r.size.x - i * r.size.x / 6.0, r.size.y + (8.0 if i % 2 == 0 else -4.0)))
			InkDraw.shape(ci, folds, 3.0, s + 1, Color(0.3, 0.28, 0.31))
			for i in 5:
				var x: float = r.size.x * (i + 1) / 6.0
				InkDraw.line(ci, Vector2(x, 8), Vector2(x + 4, r.size.y - 6), 1.5, s + 2 + i)
		"table":
			InkDraw.rect(ci, Rect2(0, 0, r.size.x, 14), 3.0, s, WOOD)
			var cloth: PackedVector2Array = PackedVector2Array([Vector2(-6, 6), Vector2(r.size.x + 6, 6), Vector2(r.size.x + 2, r.size.y), Vector2(-2, r.size.y)])
			InkDraw.shape(ci, cloth, 3.0, s + 1, InkDraw.PAPER)
			InkDraw.hatch(ci, Rect2(4, r.size.y * 0.55, r.size.x - 8, r.size.y * 0.42), 9.0, 1.0, s + 2)
		_:
			InkDraw.rect(ci, r, 4.0, s, WOOD)
			InkDraw.line(ci, Vector2(r.size.x * 0.5, 10), Vector2(r.size.x * 0.5, r.size.y - 10), 2.5, s + 1)
			ci.draw_circle(Vector2(r.size.x * 0.5 - 9, r.size.y * 0.5), 4.0, InkDraw.INK)
			ci.draw_circle(Vector2(r.size.x * 0.5 + 9, r.size.y * 0.5), 4.0, InkDraw.INK)
			InkDraw.hatch(ci, Rect2(6, r.size.y * 0.7, r.size.x - 12, r.size.y * 0.28), 8.0, 1.0, s + 2)
	var spot: HidingSpot = ci as HidingSpot
	if spot != null and spot.erased:
		return
	if spot != null and spot.erase_progress > 0.0:
		# The Ink Shadow scribbling it out: black zigzags piling up.
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = s
		for i in int(spot.erase_progress * 14.0):
			var y: float = r.size.y * (i + 0.5) / 14.0
			InkDraw.line(ci, Vector2(rng.randf_range(-10, 10), y), Vector2(r.size.x + rng.randf_range(-10, 10), y + rng.randf_range(-24, 24)), 6.0, s + i)
	if spot != null and spot.occupied:
		# A sliver of red where the player crouches inside.
		ci.draw_rect(Rect2(r.size.x * 0.5 - 2, r.size.y * 0.35, 4, r.size.y * 0.3), Color(InkDraw.RED, 0.8))


## Ink scrawl on the wall, only there while the light is on it.
static func _writing(ci: Interactable, r: Rect2, s: int) -> void:
	if ci.reveal <= 0.02:
		return
	var font: Font = ThemeDB.fallback_font
	var ink: Color = Color(InkDraw.INK, ci.reveal * 0.9)
	var lines: PackedStringArray = ci.data.text.split("\n")
	for i in lines.size():
		var pos: Vector2 = Vector2(4, 30 + i * 34)
		ci.draw_string_outline(font, pos, lines[i], HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 26, 2, ink)
		ci.draw_string(font, pos, lines[i], HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 26, ink)
		InkDraw.line(ci, pos + Vector2(0, 6), pos + Vector2(minf(r.size.x, 24.0 * lines[i].length()), 9), 1.5, s + i, ink, 2.0)


## Grandfather clock with no hands; its face's three marks show in light.
static func _clock(ci: Interactable, r: Rect2, s: int) -> void:
	var w: float = r.size.x
	InkDraw.shape(ci, PackedVector2Array([Vector2(10, 0), Vector2(w - 10, 0), Vector2(w, 30), Vector2(w, r.size.y), Vector2(0, r.size.y), Vector2(0, 30)]), 4.0, s, DARK_WOOD)
	var face_c: Vector2 = Vector2(w * 0.5, 66)
	InkDraw.ellipse(ci, face_c, Vector2(44, 44), 4.0, s + 1, Color(0.85, 0.83, 0.77))
	InkDraw.rect(ci, Rect2(16, 128, w - 32, r.size.y - 150), 3.0, s + 2, VOID)
	# XII at the top: the clock is read from twelve.
	ci.draw_string(ThemeDB.fallback_font, face_c + Vector2(-8, -30), "XII", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(InkDraw.INK, 0.8))
	if ci.reveal > 0.02:
		var steady: float = (ci as GrandfatherClock).steady if ci is GrandfatherClock else 1.0
		var marks: PackedStringArray = ci.data.symbols
		for i in marks.size():
			# The face shudders while the pendulum swings: the marks jitter and fade.
			var a: float = -PI * 0.5 + TAU * i / maxf(marks.size(), 1.0) + (1.0 - steady) * sin(s * 0.37 + i) * 0.9
			var alpha: float = ci.reveal * lerpf(0.25, 1.0, steady)
			SymbolArt.draw(ci, StringName(marks[i]), face_c + Vector2(cos(a), sin(a)) * 25.0, 11.0, s + 3 + i, Color(InkDraw.INK, alpha), 2.5)
	else:
		ci.draw_string(ThemeDB.fallback_font, face_c + Vector2(-5, 8), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(InkDraw.INK, 0.5))


## Looks like wall panelling until its flag is set, then a dark doorway.
static func _secret_door(ci: Interactable, r: Rect2, s: int) -> void:
	if ci.resolved:
		InkDraw.rect(ci, r, 4.0, s, VOID)
		InkDraw.shape(ci, PackedVector2Array([r.position, r.position + Vector2(-28, 16), Vector2(-28, r.size.y - 12), Vector2(0, r.size.y)]), 3.0, s + 1, WOOD)
		return
	InkDraw.rect(ci, Rect2(8, 30, r.size.x - 16, r.size.y * 0.4), 2.0, s + 2)
	InkDraw.rect(ci, Rect2(8, r.size.y * 0.52, r.size.x - 16, r.size.y * 0.4), 2.0, s + 3)


## Small brass latch hidden in the panelling.
static func _latch(ci: Interactable, r: Rect2, s: int) -> void:
	var a: float = ci.reveal if ci.data.revealed_by_light else 1.0
	if a <= 0.02:
		return
	var ink: Color = Color(InkDraw.INK, a)
	InkDraw.rect(ci, r.grow(-8), 3.0, s, Color(WOOD, a), ink)
	ci.draw_circle(r.get_center(), 7.0, ink)
	InkDraw.line(ci, r.get_center(), r.get_center() + (Vector2(0, -16) if not ci.resolved else Vector2(16, 0)), 4.0, s + 1, ink)


## Wall box with three dials (symbol_lock with text "panel").
static func lock_panel(ci: Interactable, r: Rect2, s: int) -> void:
	InkDraw.rect(ci, r, 4.0, s, DARK_WOOD)
	for i in 3:
		var c: Vector2 = Vector2(r.size.x * (i + 0.5) / 3.0, r.size.y * 0.5)
		InkDraw.ellipse(ci, c, Vector2(13, 13), 2.5, s + 1 + i, InkDraw.PAPER)
		var label: String = "ok" if ci.resolved else "?"
		ci.draw_string(ThemeDB.fallback_font, c + Vector2(-5 if not ci.resolved else -8, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, InkDraw.INK)


## Where an owner's words go back: a painting of them (text "painting") or
## the old drawer. Missing words show as dashed ghost bubbles until returned.
static func _return_spot(ci: Interactable, r: Rect2, s: int) -> void:
	var missing: int = GameState.stolen_from_count(ci.data.owner_id)
	if ci.data.text == "painting":
		InkDraw.rect(ci, r, 6.0, s, Color(0.3, 0.28, 0.3))
		InkDraw.rect(ci, r.grow(-12), 2.0, s + 1, InkDraw.PAPER)
		var head: Vector2 = Vector2(r.size.x * 0.5, r.size.y * 0.42)
		InkDraw.gap_ratio = 0.25 * missing
		InkDraw.ellipse(ci, head, Vector2(24, 30), 3.0, s + 2, InkDraw.WHITE)
		InkDraw.polyline(ci, PackedVector2Array([head + Vector2(-40, 70), head + Vector2(-22, 34), head + Vector2(22, 34), head + Vector2(40, 70)]), 3.0, s + 3)
		InkDraw.gap_ratio = 0.0
		ci.draw_string(ThemeDB.fallback_font, Vector2(16, r.size.y - 16), ci.data.caption, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32, 14, InkDraw.INK)
	else:
		InkDraw.rect(ci, r, 4.0, s, WOOD)
		InkDraw.rect(ci, Rect2(10, 8, r.size.x - 20, r.size.y * 0.4), 2.5, s + 1, VOID if missing > 0 else WOOD)
		InkDraw.rect(ci, Rect2(10, r.size.y * 0.5, r.size.x - 20, r.size.y * 0.4), 2.5, s + 2, WOOD)
	for i in missing:
		InkDraw.gap_ratio = 0.5
		InkDraw.ellipse(ci, Vector2(r.size.x * 0.5 + (i - (missing - 1) * 0.5) * 34.0, -26), Vector2(15, 10), 2.0, s + 10 + i, Color(1, 1, 1, 0.7))
		InkDraw.gap_ratio = 0.0
