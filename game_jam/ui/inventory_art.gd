class_name InventoryArt
extends RefCounted
## Drawing helpers for the inventory strip (kept apart to keep the strip short).


## Largest font size (max 20) whose bubble fits inside a slot.
static func fit_font_size(text: String, max_width: float) -> int:
	var font_size: int = 20
	while font_size > 11 and BubbleArt.size_for(text, font_size).x * 1.12 > max_width:
		font_size -= 1
	return font_size


static func any_cooling() -> bool:
	for bubble in GameState.inventory:
		if AbilityRegistry.cooldown_left(bubble.ability_id) > 0.0:
			return true
	return false


## Clock-wipe of ink over a slot whose word is recharging, plus seconds left.
static func draw_cooldown(ci: CanvasItem, r: Rect2, ability_id: StringName) -> void:
	var ratio: float = AbilityRegistry.cooldown_ratio(ability_id)
	if ratio <= 0.0:
		return
	var center: Vector2 = r.get_center()
	var pie: PackedVector2Array = PackedVector2Array([center])
	for i in 33:
		var t: float = -PI * 0.5 + TAU * ratio * i / 32.0
		pie.append(center + Vector2(cos(t), sin(t)) * r.size.length() * 0.5)
	for poly in Geometry2D.intersect_polygons(pie, InkDraw.rect_points(r.grow(-3))):
		ci.draw_colored_polygon(poly, Color(InkDraw.INK, 0.45))
	var font: Font = ThemeDB.fallback_font
	var label: String = "%ds" % ceili(AbilityRegistry.cooldown_left(ability_id))
	ci.draw_string_outline(font, r.end - Vector2(34, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, InkDraw.WHITE)
	ci.draw_string(font, r.end - Vector2(34, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, InkDraw.INK)


## Small ink arrow with a count of words hidden on that side.
static func draw_more_arrow(ci: CanvasItem, x: float, dir: float, hidden: int) -> void:
	var y: float = 60.0
	var tip: Vector2 = Vector2(x + 14.0 * dir, y)
	ci.draw_colored_polygon(PackedVector2Array([tip, Vector2(x, y - 12), Vector2(x, y + 12)]), InkDraw.INK)
	var font: Font = ThemeDB.fallback_font
	var label: String = "+%d" % hidden
	var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	ci.draw_string(font, Vector2(x + dir * 8.0 - w * 0.5, y + 28), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, InkDraw.INK)


## [title, body] for a word: its ability and what it does (with cooldown),
## or after the twist whose it is and how to give it back.
static func describe(bubble: BubbleData) -> PackedStringArray:
	var ability: AbilityData = AbilityRegistry.get_ability(bubble.ability_id)
	var title: String = "\"%s\"  -  %s" % [bubble.text, ability.display_name if ability != null else "?"]
	var body: String = ability.description if ability != null else ""
	if ability != null and ability.cooldown > 0.0:
		body += "  (rests %ds after use)" % int(ability.cooldown)
	if ability == null and bubble.story_final:
		title = "\"%s\"" % bubble.text
		body = "The Shadow's last word. It does nothing in your hands."
	if GameState.can_return() and bubble.owner_name != "":
		body = "Taken from %s. Hold E under their broken bubble to give it back." % bubble.owner_name
	return PackedStringArray([title, body])


## Word, ability name and what it does, above a slot (mouse hover).
static func draw_tooltip(ci: Control, slot: Rect2, bubble: BubbleData, tick: int) -> void:
	var lines: PackedStringArray = describe(bubble)
	var font: Font = ThemeDB.fallback_font
	var width: float = maxf(font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x, font.get_string_size(lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x) + 28.0
	var box: Rect2 = Rect2(Vector2(clampf(slot.get_center().x - width * 0.5, -40.0, ci.size.x - width), -64), Vector2(width, 58))
	InkDraw.rect(ci, box, 3.0, tick * 3, InkDraw.WHITE)
	ci.draw_string(font, box.position + Vector2(14, 24), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, InkDraw.INK)
	ci.draw_string(font, box.position + Vector2(14, 46), lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(InkDraw.INK, 0.75))


## The selected word's name and effect, always shown just above the strip
## (keyboard players see it without hovering).
static func draw_selected_line(ci: Control, bubble: BubbleData) -> void:
	if bubble == null:
		return
	var lines: PackedStringArray = describe(bubble)
	var text: String = lines[0] + ":  " + lines[1]
	var font: Font = ThemeDB.fallback_font
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var box: Rect2 = Rect2(Vector2(110, -20), Vector2(w + 20, 20))
	ci.draw_rect(box, Color(InkDraw.PAPER, 0.92))
	ci.draw_string(font, box.position + Vector2(10, 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, InkDraw.INK)


## "x2" when two stolen bubbles share a word.
static func draw_badge(ci: CanvasItem, r: Rect2, count: int) -> void:
	if count < 2:
		return
	var c: Vector2 = Vector2(r.end.x - 18, r.position.y + 16)
	ci.draw_circle(c, 13.0, InkDraw.INK)
	ci.draw_string(ThemeDB.fallback_font, c + Vector2(-10, 5), "x%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, InkDraw.WHITE)
