class_name RevealBeats
extends RefCounted
## The reveal's beats, one idea each (RevealSequence runs the clock). Each
## caption is held for its reading time (at least MIN_READ seconds).
##   morph    the Shadow's silhouette melts into the Artist's hand (no words)
##   artist   pull back: the panel is a page on a desk  "This comic has an Artist."
##   monster  the monster's ghost over the hand         "The monster was never a monster."
##   hand     close on the hand + label card            "It was the Artist's hand."
##   erase    the pencil turned eraser-down rubs the red figure out
##   stole / tore / mend   the robbed characters, the page tearing, stitching
##   recap    a plain three-line card

const MIN_READ: float = 2.5
## Built at runtime (typed constant arrays of containers misbehave in exports).
static func beats() -> Array:
	return [
	{id = &"morph", text = "", hold = 3.6},
	{id = &"artist", text = "This comic has an Artist."},
	{id = &"monster", text = "The monster was never a monster."},
	{id = &"hand", text = "It was the Artist's hand.", hold = 4.0},
	{id = &"erase", text = "It was erasing me. I was never written. I am a mistake on the page."},
	{id = &"stole", text = "And every word I stole was a line the Artist drew."},
	{id = &"tore", text = "Every theft tore the page."},
	{id = &"mend", text = "To mend it, I must give it all back."},
	{id = &"recap", text = "", hold = 6.5},
	]
const LABEL: String = "THE MONSTER WAS THE ARTIST'S HAND."
const RECAP: PackedStringArray = ["The monster = the Artist's hand.", "I am the mistake it is erasing.", "My thefts broke the comic."]


## Seconds a beat is held: its own `hold`, or reading time for its caption.
static func duration(beat: Dictionary) -> float:
	var read: float = 1.0 + String(beat.text).length() * 0.065
	return maxf(beat.get("hold", 0.0), maxf(MIN_READ, read))


## Start time of every beat, plus the total as the last entry.
static func schedule(start: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var t: float = start
	for beat in beats():
		out.append(t)
		t += duration(beat)
	out.append(t)
	return out


## The comic caption box for the plain-words label.
static func label_card(ci: CanvasItem, screen: Vector2, alpha: float, tick: int) -> void:
	if alpha <= 0.01:
		return
	var font: Font = ThemeDB.fallback_font
	var w: float = font.get_string_size(LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	var box: Rect2 = Rect2(Vector2(screen.x * 0.5 - w * 0.5 - 34, screen.y - 190), Vector2(w + 68, 84))
	InkDraw.rect(ci, box, 6.0, tick, Color(1.0, 0.97, 0.86, alpha), Color(InkDraw.INK, alpha))
	BubbleArt.draw_bold(ci, box.position + Vector2(34, 56), LABEL, 40, Color(InkDraw.INK, alpha))


## The recap: three short lines on a plain card, appearing one by one.
static func recap(ci: CanvasItem, screen: Vector2, k: float, tick: int) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, screen), InkDraw.WHITE)
	var card: Rect2 = Rect2(screen * 0.5 - Vector2(420, 170), Vector2(840, 340))
	InkDraw.rect(ci, card, 7.0, tick, InkDraw.PAPER)
	var font: Font = ThemeDB.fallback_font
	for i in RECAP.size():
		var a: float = clampf((k * 6.5 - 0.4 - i * 1.0) / 0.5, 0.0, 1.0)
		ci.draw_string(font, card.position + Vector2(60, 100 + i * 80), RECAP[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color(InkDraw.INK, a))
		if i == 0 and a > 0.0:
			InkDraw.line(ci, card.position + Vector2(56, 112), card.position + Vector2(56 + 380 * a, 114), 3.0, tick + 9, Color(InkDraw.INK, a))


## Smaller than the pen shot: the pencil turned eraser-down rubs the legs,
## shedding dust, and the figure stays readable above it.
static func eraser_hand(ci: CanvasItem, figure_x: float, hand_full: float, k: float, now: float, tick: int) -> void:
	var feet: Vector2 = RevealArt.HEART_PANEL.position + Vector2(RevealArt.HEART_PANEL.size.x * figure_x, 500)
	var hand_size: float = hand_full * 0.42
	var rub_target: Vector2 = feet + Vector2(75.0 + sin(now * 9.0) * 30.0, 12.0)
	var arrive: float = smoothstep(0.0, 0.3, k)
	var tip: Vector2 = (feet + Vector2(500, -700)).lerp(rub_target, arrive)
	HandArt.draw(ci, tip - HandArt.tool_tip(hand_size, &"eraser"), hand_size, tick * 7, 0.0, &"eraser")
	if k < 0.3:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 909
	for i in 40:
		var age: float = fmod(now * 0.8 + rng.randf() * 2.0, 2.0)
		var start: Vector2 = feet + Vector2(rng.randf_range(-70, 70), rng.randf_range(-90, -20))
		ci.draw_rect(Rect2(start + Vector2(rng.randf_range(-20, 20) * age, 60.0 * age), Vector2(6, 4)), RevealArt.SMUDGE)





## Desk-space rect the camera frames for beat `id` at progress `k`.
static func camera(id: StringName, k: float, wrist: Vector2, figure_x: float) -> Rect2:
	var panel: Rect2 = RevealArt.HEART_PANEL
	var page: Rect2 = RevealArt.PAGE.grow(90)
	var desk: Rect2 = Rect2(-900, -500, 3300, 3000)
	var hand: Rect2 = Rect2(wrist + Vector2(-700, -120), Vector2(1100, 640))
	var feet: Vector2 = panel.position + Vector2(panel.size.x * figure_x, 500)
	var figure: Rect2 = Rect2(feet - Vector2(380, 300), Vector2(760, 400))
	match id:
		&"morph":
			return _lerp(panel, hand, smoothstep(0.35, 1.0, k))
		&"artist":
			return _lerp(hand, page, smoothstep(0.0, 0.55, k)) if k < 0.55 else _lerp(page, desk, smoothstep(0.55, 1.0, k))
		&"monster":
			return _lerp(desk, page, smoothstep(0.0, 0.4, k))
		&"hand":
			return _lerp(desk, hand, smoothstep(0.0, 0.5, k))
		_:
			return _lerp(hand, figure, smoothstep(0.0, 0.3, k))


static func _lerp(a: Rect2, b: Rect2, w: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, w), a.size.lerp(b.size, w))
