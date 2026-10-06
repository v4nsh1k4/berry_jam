class_name AboutArt
extends RefCounted
## The main menu's About page (Stage 7) as a black-and-white comic page, in
## the Credits page's look: a white gutter, ink-bordered paper panels,
## halftone corners and caption boxes. Left: the premise. Right: the red
## unperson with its empty bubble and three stolen words floating near it.
## It explains the premise WITHOUT the twist (no author, hand, ERASE or
## giving words back).

## Paragraphs separated by "|" (one plain string, split at runtime: see the
## export gotchas in CLAUDE.md §9).
const TEXT: String = "A reader leans too close to an old comic, The Silent House of Hollow Hill, and is pulled in.|Inside, they are an unperson: faceless, drawn in red, the only colour in a black-and-white world, with an empty speech bubble and no words of their own.|To get through the house they steal words from its characters and speak them as power: OPEN a door, PUSH a cabinet, HIDE from what hunts in the dark.|But every stolen word tears the page a little more, and light draws the Ink Crawler. Find the way out of the comic before the story falls apart."
const FONT_SIZE: int = 21
const WORDS: PackedStringArray = ["OPEN", "PUSH", "HIDE"]


static func page(ci: CanvasItem, area: Rect2, tick: int) -> void:
	RevealArt.set_view(ci, Transform2D.IDENTITY)
	ci.draw_rect(area.grow(8), InkDraw.WHITE)
	var g: float = 14.0
	var left: Rect2 = Rect2(area.position, Vector2(area.size.x * 0.66 - g * 0.5, area.size.y))
	var right: Rect2 = Rect2(left.end.x + g, area.position.y, area.end.x - left.end.x - g, area.size.y)
	for r in [left, right]:
		ci.draw_rect(r, InkDraw.PAPER)
	CreditsArt.halftone(ci, right, right.end)
	_text(ci, left, tick)
	_figure(ci, right, tick + 20)
	for i in 2:
		InkDraw.rect(ci, [left, right][i], 7.0, tick + 40 + i, Color.TRANSPARENT, InkDraw.INK, 2.2)


## The caption, then the paragraphs wrapped to the panel.
static func _text(ci: CanvasItem, r: Rect2, tick: int) -> void:
	var font: Font = ThemeDB.fallback_font
	var head: Rect2 = CreditsArt.caption(ci, r.position + Vector2(18, 16), "ABOUT THE GAME", 18, tick)
	var width: float = r.size.x - 64.0
	var y: float = head.end.y + 22.0
	for paragraph in TEXT.split("|"):
		var lines: PackedStringArray = _wrap(font, paragraph, width)
		for line in lines:
			y += font.get_height(FONT_SIZE)
			ci.draw_string(font, Vector2(r.position.x + 32, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, InkDraw.INK)
		y += font.get_height(FONT_SIZE) * 0.55


## Greedy word wrap (the fallback font, `width` px).
static func _wrap(font: Font, text: String, width: float) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var line: String = ""
	for word in text.split(" "):
		var next: String = word if line == "" else line + " " + word
		if line != "" and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > width:
			out.append(line)
			line = word
		else:
			line = next
	if line != "":
		out.append(line)
	return out


## The unperson (red, the only colour) with words drifting round it.
static func _figure(ci: CanvasItem, r: Rect2, tick: int) -> void:
	var feet: Vector2 = Vector2(r.get_center().x - 10, r.end.y - 70)
	InkDraw.line(ci, Vector2(r.position.x + 10, feet.y + 2), Vector2(r.end.x - 10, feet.y + 4), 3.0, tick)
	RevealArt.red_figure(ci, feet, 1.5, tick + 1)
	var tq: float = tick * InkDraw.BOIL_INTERVAL_MS / 1000.0
	for i in WORDS.size():
		var at: Vector2 = Vector2(r.position.x + r.size.x * (0.3 + 0.36 * (i % 2)), r.position.y + 70 + i * 92)
		at.y += sin(tq * 1.3 + i * 2.0) * 4.0
		BubbleArt.draw(ci, at, WORDS[i], BubbleArt.NO_TAIL, tick + 3 + i, 20, 1.0, 3.0)
