class_name SpeechBubble
extends Node2D
## A character's line hanging in the world. The stealable word is shown in
## an ink box; hold E to take it. Once stolen, the bubble stays with what is
## left of the line, drawn unfinished. Position is the bubble centre.

const WORD_TOKEN: String = "{word}"
const FONT_SIZE: int = 18
const STEAL_RING_RADIUS: float = 26.0

var data: BubbleData
var stolen: bool = false
## Set by the Interactor while this is the bubble E would steal.
var targeted: bool = false:
	set(value):
		targeted = value
		queue_redraw()
var steal_progress: float = 0.0:
	set(value):
		steal_progress = value
		queue_redraw()

var _line: String = ""
var _broken_line: String = ""
var _tail_tip: Vector2
var _reach_point: Vector2
var _tick: int = -1
var _bob_time: float = randf() * TAU


## `line` holds WORD_TOKEN where the word sits; empty means the word alone.
func setup(bubble: BubbleData, line: String, broken_line: String, tip: Vector2, reach: Vector2) -> void:
	data = bubble
	_line = line if line != "" else WORD_TOKEN
	_broken_line = broken_line if broken_line != "" else "..."
	_tail_tip = tip
	_reach_point = reach
	stolen = GameState.is_bubble_stolen(bubble.id)
	if not stolen:
		add_to_group(&"stealable")


func get_interact_point() -> Vector2:
	return _reach_point


func get_prompt() -> String:
	return "Hold E: steal \"%s\"" % data.text


func steal() -> void:
	stolen = true
	targeted = false
	steal_progress = 0.0
	remove_from_group(&"stealable")
	scale = Vector2(1.2, 1.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_bob_time += delta
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var font: Font = ThemeDB.fallback_font
	var bob: Vector2 = Vector2(0, sin(_bob_time * 2.0) * 3.0)
	var s: int = _tick * 11
	if stolen:
		InkDraw.gap_ratio = 0.4
		BubbleArt.draw(self, bob, _broken_line, _tail_tip, s, FONT_SIZE, 0.85, 2.0)
		InkDraw.gap_ratio = 0.0
		return

	var parts: PackedStringArray = _line.split(WORD_TOKEN, true, 1)
	var before: String = parts[0]
	var after: String = parts[1] if parts.size() > 1 else ""
	var word: String = data.text
	var full: String = before + word + after
	var size: Vector2 = BubbleArt.size_for(full, FONT_SIZE) + Vector2(12, 4)
	BubbleArt.draw_shell(self, bob, size, _tail_tip, s, 1.0, 4.5 if targeted else 3.0)

	var full_width: float = font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var baseline: Vector2 = BubbleArt.baseline_for(bob, full_width, FONT_SIZE)
	var before_width: float = font.get_string_size(before, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var word_width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	BubbleArt.draw_bold(self, baseline, before, FONT_SIZE, InkDraw.INK)
	var word_pos: Vector2 = baseline + Vector2(before_width, 0)
	var box: Rect2 = Rect2(word_pos + Vector2(-4, -font.get_ascent(FONT_SIZE) - 3), Vector2(word_width + 8, font.get_height(FONT_SIZE) + 4))
	draw_rect(box, InkDraw.INK)
	BubbleArt.draw_bold(self, word_pos, word, FONT_SIZE, InkDraw.WHITE)
	BubbleArt.draw_bold(self, word_pos + Vector2(word_width, 0), after, FONT_SIZE, InkDraw.INK)

	if steal_progress > 0.0:
		var ring_center: Vector2 = box.get_center()
		draw_arc(ring_center, STEAL_RING_RADIUS + word_width * 0.4, -PI * 0.5, -PI * 0.5 + TAU * clampf(steal_progress, 0.0, 1.0), 40, InkDraw.RED, 5.0, true)
