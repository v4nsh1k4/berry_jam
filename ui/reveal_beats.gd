class_name RevealBeats
extends RefCounted
## The reveal's beats, one idea each (RevealSequence runs the clock). Each
## caption is held for its reading time (at least MIN_READ seconds).
##   morph    the Shadow's silhouette melts into the author's hand (no words)
##   artist   pull back: the panel is a page on a desk  "This comic has an author."
##   monster  the monster's ghost over the hand         "The monster was never a monster."
##   hand     close on the hand + label card            "It was, in fact, the author's hand."
##   erase    the pencil turned eraser-down rubs the red figure out
##   stole    the robbed characters, then the page tearing (the broken story)
##   you      held near-silence: the hand stills over the page, the red
##            figure alone                              "You were the monster."
##   recap    a plain three-line card
## Player-facing text says "author"; ids and class names keep "artist".

const MIN_READ: float = 2.5
## Built at runtime (typed constant arrays of containers misbehave in exports).
static func beats() -> Array:
	return [
	{id = &"morph", text = "", hold = 3.6},
	{id = &"artist", text = "This comic has an author."},
	{id = &"monster", text = "The monster was never a monster."},
	{id = &"hand", text = "It was, in fact, the author's hand.", hold = 4.0},
	{id = &"erase", text = "To the author, you were the anomaly. A glitch. A mistake."},
	{id = &"stole", text = "You starved the characters of their words, and broke the story."},
	{id = &"you", text = "You were the monster.", hold = 6.5},
	{id = &"recap", text = "", hold = 6.5},
	]
## Index of the "stole" beat (the cost + tear drawing keys off its start).
const STOLE: int = 5
## Share of the "stole" beat before the page starts to tear.
const TEAR_FROM: float = 0.45
const LABEL: String = "THE AUTHOR'S HAND."
const RECAP: PackedStringArray = ["The monster was the author's hand.", "I was the glitch it was erasing.", "My theft broke the story."]


## Sound cues inside beats; returns whether the held beat's hush is done.
## The team's recorded cry, cut short, as the eraser rubs the figure out;
## near silence (music and ambience) for "You were the monster."
static func sounds(id: StringName, k: float, left: float, hushed: bool) -> bool:
	if id == &"erase" and k > 0.12:
		AudioManager.play_cry(&"thin", -9.0, 0.0, &"cry_reveal")
	if id == &"you" and not hushed:
		MusicManager.duck(0.97, left)
		AudioManager.hush(left)
		return true
	return hushed


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
			var w: float = font.get_string_size(RECAP[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
			InkDraw.line(ci, card.position + Vector2(56, 112), card.position + Vector2(56 + w * a, 114), 3.0, tick + 9, Color(InkDraw.INK, a))


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



## "You were the monster.": the hand comes to rest over the page, eraser
## down but not touching, and stills; the red figure stands alone under it.
static func still_hand(ci: CanvasItem, figure_x: float, hand_full: float, k: float, now: float, tick: int) -> void:
	var feet: Vector2 = RevealArt.HEART_PANEL.position + Vector2(RevealArt.HEART_PANEL.size.x * figure_x, 500)
	var hand_size: float = hand_full * 0.42
	var settle: float = 1.0 - smoothstep(0.0, 0.45, k)
	var tip: Vector2 = feet + Vector2(130, -240) + Vector2(sin(now * 3.0), cos(now * 2.3)) * 14.0 * settle
	HandArt.draw(ci, tip - HandArt.tool_tip(hand_size, &"eraser"), hand_size, tick * 7 if settle > 0.05 else 7, 0.0, &"eraser")
	# The page around the figure darkens: it stands alone.
	_vignette(ci, feet + Vector2(0, -90), Vector2(170, 190), smoothstep(0.2, 0.8, k) * 0.6)


## A smooth dark vignette: clear inside `radii`, `dark` from twice that out
## (one triangle array, per-vertex alpha).
static func _vignette(ci: CanvasItem, c: Vector2, radii: Vector2, dark: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var idx: PackedInt32Array = PackedInt32Array()
	var rings: Array = [[1.0, 0.0], [2.2, dark], [30.0, dark]]
	var seg: int = 40
	for ring in rings:
		for i in seg:
			pts.append(c + Vector2.from_angle(TAU * i / seg) * radii * float(ring[0]))
			cols.append(Color(0, 0, 0, float(ring[1])))
	for r in rings.size() - 1:
		for i in seg:
			var a0: int = r * seg + i
			var a1: int = r * seg + (i + 1) % seg
			idx.append_array([a0, a1, a0 + seg, a1, a1 + seg, a0 + seg])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)


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
		&"you":
			return _lerp(page, figure.grow(120), smoothstep(0.0, 0.7, k))
		_:
			return _lerp(hand, figure, smoothstep(0.0, 0.3, k))


static func _lerp(a: Rect2, b: Rect2, w: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, w), a.size.lerp(b.size, w))
