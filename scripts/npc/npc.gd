class_name Npc
extends Node2D
## A comic character built from NpcData. Speaks one SpeechBubble per bubble.
## The more of their words are stolen, the more "unfinished" they are drawn,
## and they react (a caption) when the player comes close again. In Chapter 3
## before the twist they plead (plea_lines); after it, a word of theirs that
## was somehow lost goes home by itself when the player comes near.

const REACT_DISTANCE: float = 220.0
## Outline share left out when every word is gone.
const MAX_GAP: float = 0.5

var data: NpcData

var _reacted_count: int = 0
var _player_near: bool = false
var _pleas: int = 0
var _tick: int = -1


func setup(npc: NpcData) -> void:
	data = npc
	position = npc.position
	scale = Vector2.ONE * npc.scale
	if npc.visual_style == &"none":
		# A word held by an enemy is drawn over it, so it reads as gripped.
		z_index = 3
	_reacted_count = GameState.stolen_from_count(npc.id)
	var spots: PackedVector2Array = npc.bubble_offsets if not npc.bubble_offsets.is_empty() else NpcArt.default_bubble_spots(npc.visual_style)
	var mouth: Vector2 = NpcArt.mouth(npc.visual_style)
	var reach: Vector2 = global_position + Vector2(0, npc.reach_y)
	for i in npc.bubbles.size() if npc.show_bubbles else 0:
		var speech: SpeechBubble = SpeechBubble.new()
		add_child(speech)
		speech.position = spots[i % spots.size()]
		var line: String = npc.lines[i] if i < npc.lines.size() else ""
		var broken: String = npc.broken_lines[i] if i < npc.broken_lines.size() else ""
		speech.setup(npc.bubbles[i], line, broken, mouth + Vector2(0, -8) - speech.position, reach, npc.words_stealable)
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.bubble_returned.connect(_on_bubble_returned)


func _on_bubble_stolen(_bubble: BubbleData, _from: Vector2) -> void:
	queue_redraw()


## One of this character's words came home: relief, and they are drawn a
## little more complete (the gap ratio follows stolen_from_count).
func _on_bubble_returned(bubble: BubbleData, _pos: Vector2) -> void:
	if bubble.stolen_from != data.id:
		return
	_reacted_count = GameState.stolen_from_count(data.id)
	queue_redraw()
	if data.relief_lines.is_empty():
		return
	var given: int = 0
	for word in data.bubbles:
		if GameState.is_bubble_returned(word.id):
			given += 1
	var line: String = data.relief_lines[clampi(given, 1, data.relief_lines.size()) - 1]
	EventBus.caption_requested.emit("%s: \"%s\"" % [data.display_name, line], 3.5)


func _process(_delta: float) -> void:
	_check_reaction()
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


## On coming near: a "stolen-from" line once per theft, or (Chapter 3,
## before the twist) a plea for what was taken.
func _check_reaction() -> void:
	if data == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var near: bool = player.global_position.distance_to(global_position + Vector2(0, data.reach_y)) < REACT_DISTANCE
	if near and not _player_near:
		var stolen: int = GameState.stolen_from_count(data.id)
		if stolen > _reacted_count and not data.reactions.is_empty():
			_reacted_count = stolen
			var line: String = data.reactions[mini(stolen, data.reactions.size()) - 1]
			EventBus.caption_requested.emit("%s: \"%s\"" % [data.display_name, line], 3.5)
		elif stolen > 0 and not GameState.twist_revealed and not data.plea_lines.is_empty():
			var plea: String = data.plea_lines[_pleas % data.plea_lines.size()]
			_pleas += 1
			EventBus.caption_requested.emit("%s: \"%s\"" % [data.display_name, plea], 3.5)
		if GameState.can_return():
			_restore_lost_words()
	_player_near = near


## A word marked stolen that the player no longer has can never come back by
## hand, so it finds its own way home (no owner stays broken forever).
func _restore_lost_words() -> void:
	for word in data.bubbles:
		if GameState.is_bubble_stolen(word.id) and not GameState.inventory.has(word):
			GameState.restore_lost_word(word)
			EventBus.caption_requested.emit("%s's lost word found its own way home." % data.display_name, 3.5)


func _draw() -> void:
	if data == null:
		return
	var total: int = data.bubbles.size()
	if total > 0:
		var chapter_scale: float = GameState.current_chapter.damage_visual_scale if GameState.current_chapter != null else 1.0
		InkDraw.gap_ratio = minf(0.75, MAX_GAP * chapter_scale * GameState.stolen_from_count(data.id) / float(total))
	NpcArt.draw(self, data.visual_style, _tick)
	InkDraw.gap_ratio = 0.0
