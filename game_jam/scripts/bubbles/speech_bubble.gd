class_name SpeechBubble
extends Node2D
## A character's line hanging in the world. Three states:
## - whole: the word sits in an ink box; hold E to steal it (if allowed);
## - stolen: what is left of the line, drawn unfinished. In chapters that
##   allow it, hold E with the right word selected to give it back;
## - returned: the full line again, for good. It can never be stolen again.
## Position is the bubble centre.

const WORD_TOKEN: String = "{word}"
const FONT_SIZE: int = 18
const STEAL_RING_RADIUS: float = 26.0

var data: BubbleData
var stolen: bool = false
var returned: bool = false
## Set by the Interactor while this is the bubble E would act on.
var targeted: bool = false:
	set(value):
		targeted = value
		queue_redraw()
## 0..1 progress of a hold-E steal or give-back.
var steal_progress: float = 0.0:
	set(value):
		steal_progress = value
		queue_redraw()

var _line: String = ""
var _broken_line: String = ""
var _tail_tip: Vector2
var _reach_point: Vector2
var _can_steal: bool = true
var _wiggle: float = 0.0
var _tick: int = -1
var _bob_time: float = randf() * TAU


## `line` holds WORD_TOKEN where the word sits; empty means the word alone.
## `can_steal` false: a whole bubble just talks (Chapter 3).
func setup(bubble: BubbleData, line: String, broken_line: String, tip: Vector2, reach: Vector2, can_steal: bool = true) -> void:
	data = bubble
	_line = line if line != "" else WORD_TOKEN
	_broken_line = broken_line if broken_line != "" else "..."
	_tail_tip = tip
	_reach_point = reach
	_can_steal = can_steal
	stolen = GameState.is_bubble_stolen(bubble.id)
	returned = GameState.is_bubble_returned(bubble.id)
	_update_groups()
	EventBus.bubble_returned.connect(_on_bubble_returned)


func _update_groups() -> void:
	_set_group(&"stealable", not stolen and not returned and _can_steal)
	_set_group(&"returnable", stolen and GameState.can_return())


func _set_group(group: StringName, member: bool) -> void:
	if member and not is_in_group(group):
		add_to_group(group)
	elif not member and is_in_group(group):
		remove_from_group(group)


func is_returnable() -> bool:
	return is_in_group(&"returnable")


func get_interact_point() -> Vector2:
	return _reach_point


func get_prompt() -> String:
	if is_returnable():
		var word: BubbleData = GameState.selected_bubble()
		return "Hold E: give back \"%s\"" % word.text if word != null else "Pick a word (1-6, Q / R) to give back"
	return "Hold E: steal \"%s\"" % data.text


func steal() -> void:
	stolen = true
	targeted = false
	steal_progress = 0.0
	_update_groups()
	_pop()


## Wrong word offered: a shake, nothing breaks.
func refuse() -> void:
	var tween: Tween = create_tween()
	for offset in [7.0, -6.0, 4.0, 0.0]:
		tween.tween_property(self, "_wiggle", offset, 0.05)


func _on_bubble_returned(bubble: BubbleData, _pos: Vector2) -> void:
	if bubble.id != data.id:
		return
	stolen = false
	returned = true
	targeted = false
	steal_progress = 0.0
	_update_groups()
	_pop()


func _pop() -> void:
	scale = Vector2(1.2, 1.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_bob_time += delta
	var tick: int = InkDraw.boil_tick()
	if tick != _tick or _wiggle != 0.0:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var bob: Vector2 = Vector2(_wiggle, sin(_bob_time * 2.0) * 3.0)
	var s: int = _tick * 11
	if stolen:
		InkDraw.gap_ratio = 0.4
		BubbleArt.draw(self, bob, _broken_line, _tail_tip, s, FONT_SIZE, 0.85, 4.0 if targeted else 2.0)
		InkDraw.gap_ratio = 0.0
		_draw_ring(bob, InkDraw.WHITE if is_returnable() else InkDraw.RED, 30.0)
		return
	var stealable: bool = is_in_group(&"stealable")
	var parts: PackedStringArray = _line.split(WORD_TOKEN, true, 1)
	var before: String = parts[0]
	var after: String = parts[1] if parts.size() > 1 else ""
	var full: String = before + data.text + after
	var size: Vector2 = BubbleArt.size_for(full, FONT_SIZE) + Vector2(12, 4)
	BubbleArt.draw_shell(self, bob, size, _tail_tip, s, 1.0, 4.5 if targeted else 3.0)
	var font: Font = ThemeDB.fallback_font
	var baseline: Vector2 = BubbleArt.baseline_for(bob, font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x, FONT_SIZE)
	if not stealable:
		# Whole and safe: just the words, nothing to take.
		BubbleArt.draw_bold(self, baseline, full, FONT_SIZE, InkDraw.INK)
		return
	var before_width: float = font.get_string_size(before, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var word_width: float = font.get_string_size(data.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	BubbleArt.draw_bold(self, baseline, before, FONT_SIZE, InkDraw.INK)
	var word_pos: Vector2 = baseline + Vector2(before_width, 0)
	var box: Rect2 = Rect2(word_pos + Vector2(-4, -font.get_ascent(FONT_SIZE) - 3), Vector2(word_width + 8, font.get_height(FONT_SIZE) + 4))
	draw_rect(box, InkDraw.INK)
	BubbleArt.draw_bold(self, word_pos, data.text, FONT_SIZE, InkDraw.WHITE)
	BubbleArt.draw_bold(self, word_pos + Vector2(word_width, 0), after, FONT_SIZE, InkDraw.INK)
	_draw_ring(box.get_center(), InkDraw.RED, STEAL_RING_RADIUS + word_width * 0.4)


func _draw_ring(center: Vector2, color: Color, radius: float) -> void:
	if steal_progress <= 0.0:
		return
	draw_arc(center, radius + 2.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(steal_progress, 0.0, 1.0), 40, InkDraw.INK, 8.0, true)
	draw_arc(center, radius + 2.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(steal_progress, 0.0, 1.0), 40, color, 5.0, true)
