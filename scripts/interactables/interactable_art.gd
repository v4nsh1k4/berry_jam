class_name InteractableArt
extends RefCounted
## Procedural drawing for each Interactable kind, in its local space.

const WOOD: Color = Color(0.78, 0.75, 0.68)
const DARK_WOOD: Color = Color(0.2, 0.19, 0.22)
const VOID: Color = Color(0.04, 0.04, 0.05)


static func draw(item: Interactable, tick: int) -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, item.data.size)
	var s: int = tick * 29
	match item.data.kind:
		&"door":
			_door(item, r, s)
		&"drawer":
			_drawer(item, r, s)
		&"pushable":
			_cabinet(item, r, s)
		&"memory":
			_memory(item, r, s)
		&"pickup":
			_flashlight_table(item, r, s)
		&"symbol_lock":
			_symbol_lock(item, r, s)
		&"inspect":
			pass
		_:
			InkDraw.rect(item, r, 3.0, s, WOOD)


static func _door(ci: Interactable, r: Rect2, s: int) -> void:
	InkDraw.rect(ci, r.grow(10), 5.0, s + 1, DARK_WOOD)
	if ci.resolved:
		InkDraw.rect(ci, r, 3.0, s + 2, VOID)
		var leaf: PackedVector2Array = PackedVector2Array([
			Vector2(0, 0), Vector2(30, 22), Vector2(30, r.size.y - 18), Vector2(0, r.size.y)])
		InkDraw.shape(ci, leaf, 3.0, s + 3, WOOD)
		return
	var mid: float = r.size.x * 0.5
	InkDraw.rect(ci, r, 4.0, s + 4, WOOD)
	InkDraw.line(ci, Vector2(mid, 4), Vector2(mid, r.size.y - 4), 3.0, s + 5)
	# Just handles: the padlock (if any) is what says it's locked.
	ci.draw_circle(Vector2(mid - 10, r.size.y * 0.5), 5.0, InkDraw.INK)
	ci.draw_circle(Vector2(mid + 10, r.size.y * 0.5), 5.0, InkDraw.INK)
	padlock(ci, Vector2(mid, r.size.y * 0.5 + 34), s)


## A padlock on a bolted door (requires_flag not yet set). When the flag
## comes true it drops off and fades (Interactable.unbolt); then it's gone
## for good, so the change shows on every revisit.
static func padlock(ci: Interactable, at: Vector2, s: int) -> void:
	var bolted: bool = ci.data.requires_flag != &"" and not GameState.has_flag(ci.data.requires_flag)
	if not bolted and ci.unbolt <= 0.0:
		return
	var fall: float = 1.0 - ci.unbolt if not bolted else 0.0
	var p: Vector2 = at + Vector2(fall * 18.0, fall * fall * 140.0)
	var a: float = 1.0 - fall
	InkDraw.ellipse(ci, p + Vector2(0, -14), Vector2(11, 12), 4.0, s + 8, Color.TRANSPARENT, Color(InkDraw.INK, a))
	InkDraw.rect(ci, Rect2(p + Vector2(-16, -6), Vector2(32, 26)), 3.0, s + 9, Color(0.55, 0.53, 0.5, a), Color(InkDraw.INK, a))
	ci.draw_circle(p + Vector2(0, 6), 3.5, Color(InkDraw.INK, a))


## Small chest of drawers; the top drawer is locked until OPEN.
static func _drawer(ci: Interactable, r: Rect2, s: int) -> void:
	InkDraw.rect(ci, r, 4.0, s + 1, WOOD)
	var h: float = r.size.y / 3.0
	for i in 3:
		var d: Rect2 = Rect2(8, 6 + i * h, r.size.x - 16, h - 12)
		if i == 0 and ci.resolved:
			d = Rect2(d.position + Vector2(-14, -4), d.size + Vector2(28, 8))
			InkDraw.rect(ci, d, 3.0, s + 2 + i, VOID)
			continue
		InkDraw.rect(ci, d, 2.5, s + 2 + i, WOOD)
		ci.draw_circle(d.get_center(), 4.0, InkDraw.INK)
	if not ci.resolved:
		InkDraw.rect(ci, Rect2(r.size.x * 0.5 - 7, 10, 14, 12), 2.0, s + 9, InkDraw.INK)


## Heavy cabinet: tall, hatched, too big to move without a word.
static func _cabinet(ci: Interactable, r: Rect2, s: int) -> void:
	InkDraw.rect(ci, r, 5.0, s + 1, WOOD)
	InkDraw.line(ci, Vector2(r.size.x * 0.5, 14), Vector2(r.size.x * 0.5, r.size.y - 30), 3.0, s + 2)
	InkDraw.rect(ci, Rect2(10, 14, r.size.x - 20, r.size.y - 44), 2.0, s + 3)
	ci.draw_circle(Vector2(r.size.x * 0.5 - 10, r.size.y * 0.45), 4.0, InkDraw.INK)
	ci.draw_circle(Vector2(r.size.x * 0.5 + 10, r.size.y * 0.45), 4.0, InkDraw.INK)
	InkDraw.hatch(ci, Rect2(12, r.size.y * 0.6, r.size.x - 24, r.size.y * 0.4 - 32), 9.0, 1.2, s + 4)
	for x in [8.0, r.size.x - 8.0]:
		InkDraw.line(ci, Vector2(x, r.size.y - 2), Vector2(x, r.size.y + 8), 6.0, s + 5)


## Ghostly sketch in a dashed frame. Invisible until memory_alpha > 0.
static func _memory(ci: Interactable, r: Rect2, s: int) -> void:
	var a: float = ci.memory_alpha
	if a <= 0.01:
		return
	var ink: Color = Color(InkDraw.INK, a)
	var pts: PackedVector2Array = InkDraw.wobble(InkDraw.rect_points(r), 2.5, s, true)
	for i in pts.size() - 1:
		if i % 2 == 0:
			ci.draw_line(pts[i], pts[i + 1], ink, 2.0, true)
	var symbols: PackedStringArray = ci.data.symbols
	var cell: float = r.size.x / maxf(symbols.size(), 1.0)
	for i in symbols.size():
		var center: Vector2 = Vector2(cell * (i + 0.5), r.size.y * 0.5)
		SymbolArt.draw(ci, StringName(symbols[i]), center, minf(cell, r.size.y) * 0.34, s + i * 5, ink)
	if ci.data.points_to != Vector2.ZERO:
		# A dashed ink arrow to the lock it opens.
		var from: Vector2 = r.get_center() + ci.data.points_to.normalized() * (r.size.x * 0.6)
		var to: Vector2 = r.get_center() + ci.data.points_to
		for k in 8:
			if k % 2 == 0:
				ci.draw_line(from.lerp(to, k / 8.0), from.lerp(to, (k + 1) / 8.0), ink, 3.0, true)
		var d: Vector2 = (to - from).normalized()
		InkDraw.polyline(ci, PackedVector2Array([to - d * 16 + d.orthogonal() * 10, to, to - d * 16 - d.orthogonal() * 10]), 3.0, s + 40, false, ink)


## Small table; the torch lies on it until taken.
static func _flashlight_table(ci: Interactable, r: Rect2, s: int) -> void:
	var top: float = r.size.y * 0.35
	InkDraw.rect(ci, Rect2(0, top, r.size.x, 12), 3.0, s + 1, WOOD)
	for x in [10.0, r.size.x - 10.0]:
		InkDraw.line(ci, Vector2(x, top + 12), Vector2(x, r.size.y + 20), 4.0, s + 2)
	if ci.resolved:
		return
	var torch: Rect2 = Rect2(r.size.x * 0.5 - 26, top - 14, 44, 14)
	InkDraw.rect(ci, torch, 2.5, s + 3, InkDraw.INK)
	InkDraw.shape(ci, PackedVector2Array([torch.end - Vector2(0, 14), torch.end + Vector2(10, -19), torch.end + Vector2(10, 5), torch.end]), 2.5, s + 4, InkDraw.WHITE)


## A door in the panelling with three symbol dials; swings open once solved.
static func _symbol_lock(ci: Interactable, r: Rect2, s: int) -> void:
	if ci.data.text == "panel":
		InteractableArt2.lock_panel(ci, r, s)
		return
	if ci.resolved:
		_door(ci, r, s)
		return
	InkDraw.rect(ci, r.grow(10), 5.0, s + 1, DARK_WOOD)
	InkDraw.rect(ci, r, 4.0, s + 2, WOOD)
	var plate: Rect2 = Rect2(10, r.size.y * 0.36, r.size.x - 20, 48)
	InkDraw.rect(ci, plate, 3.0, s + 3, InkDraw.WHITE)
	for i in 3:
		var c: Vector2 = Vector2(plate.position.x + plate.size.x * (i + 0.5) / 3.0, plate.get_center().y)
		InkDraw.ellipse(ci, c, Vector2(15, 15), 2.5, s + 4 + i)
		ci.draw_string(ThemeDB.fallback_font, c + Vector2(-5, 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, InkDraw.INK)
	padlock(ci, Vector2(r.size.x * 0.5, plate.end.y + 40), s)
