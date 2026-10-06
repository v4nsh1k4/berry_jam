class_name UnlockFeedback
extends Node2D
## One "it opened" feedback for everything (FXLayer, screen space). Three
## sources, all on EventBus:
##   unlocked(data, pos)        an object resolved (door, lock, lever, latch,
##                              light puzzle, secret door, drawer), or a door
##                              whose requires_flag just came true (unbolted)
##   exit_unlocked(exit, pos)   a gated exit's flag came true
## Each shows a short caption at the top (InteractableData.unlock_caption, or
## a default per kind), an onomatopoeia pop-up, a sound and a pulse ring at
## the thing. If the thing is far from the player (or in another spread
## panel) the caption says "somewhere nearby" and an arrow points at it.
## Events arriving together (a lever that opens a door) show the most
## important caption only: an opened way beats an unbolted door beats the
## object itself.

const DEFAULTS: Dictionary = {
	&"door": "The door opened!", &"symbol_lock": "Unlocked!", &"lever": "Clunk!",
	&"latch": "The latch gives.", &"secret_door": "A hidden door opened!", &"drawer": "The drawer opened!",
	&"light_ink": "The ink shrinks away!", &"lens": "The glass throws the light!",
	&"shadow_puzzle": "The shadow fits. Click!", &"pushable": "Shoved aside.",
}
const WORDS: Dictionary = {
	&"door": "CREAK!", &"symbol_lock": "CLICK!", &"lever": "CLUNK!", &"latch": "CLICK!", &"secret_door": "CREAK!",
	&"drawer": "CLACK!", &"light_ink": "HISS!", &"lens": "SHINE!", &"shadow_puzzle": "CLICK!", &"pushable": "SCRAPE",
	&"exit": "CREAK!", &"unbolt": "CLACK!",
}
const PULSE_TIME: float = 0.9
const ARROW_TIME: float = 2.2

var _pending: String = ""
var _priority: int = -1
var _pending_left: float = 0.0
## [screen position, seconds left] for each pulse ring.
var _pulses: Array = []
var _arrow_to: Vector2 = Vector2.INF
var _arrow_left: float = 0.0
## The last few [kind, sound] it played (tests read it).
var heard: Array = []


func _ready() -> void:
	EventBus.unlocked.connect(_on_unlocked)
	EventBus.exit_unlocked.connect(_on_exit_unlocked)


func _fx() -> Node:
	return get_parent().get_node_or_null("FeedbackFx")


func _on_unlocked(data: InteractableData, pos: Vector2) -> void:
	var unbolt: bool = data.requires_flag != &"" and GameState.has_flag(data.requires_flag) \
		and not (data.sets_flag != &"" and GameState.has_flag(data.sets_flag))
	var kind: StringName = &"unbolt" if unbolt else data.kind
	var text: String = data.unlock_caption
	if text == "" and unbolt:
		text = "The %s is unbolted." % ("door" if data.kind != &"symbol_lock" else "lock")
	if text == "" and data.kind in [&"lever", &"light_ink", &"lens", &"shadow_puzzle"]:
		text = data.caption
	if text == "":
		text = DEFAULTS.get(data.kind, "")
	_announce(text, kind, pos, 2 if unbolt else 1)


func _on_exit_unlocked(_exit: ExitData, pos: Vector2) -> void:
	_announce("The door opened! The way on is open.", &"exit", pos, 3)


func _announce(text: String, kind: StringName, pos: Vector2, priority: int) -> void:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var player_pos: Vector2 = player.get_global_transform_with_canvas().origin if player != null else pos
	var far: bool = _out_of_view(pos, player_pos)
	if far:
		text = "A door opened somewhere nearby." if kind in [&"exit", &"unbolt", &"door"] else text
		_arrow_to = pos
		_arrow_left = ARROW_TIME
	var fx: Node = _fx()
	if fx != null and WORDS.has(kind):
		fx.call("popup", WORDS[kind], pos + Vector2(60, -80))
		fx.call("splash", pos, 12)
	# A way opening creaks; everything else (a padlock dropping, a latch, a
	# dial box) clicks.
	if kind in [&"door", &"exit", &"secret_door"]:
		AudioManager.play_door_creak()
	else:
		AudioManager.play(&"click", -6.0, 0.08)
	heard.append([kind, AudioManager.last_played])
	if heard.size() > 24:
		heard.pop_front()
	_pulses.append([pos, PULSE_TIME])
	if text != "" and priority >= _priority:
		_pending = text
		_priority = priority
		_pending_left = 0.15


## Off the panel, or in another panel of a spread page than the player.
func _out_of_view(pos: Vector2, player_pos: Vector2) -> bool:
	if not Frame.PANEL_RECT.has_point(pos):
		return true
	var frame: Frame = FrameManager.current_frame
	if frame == null or frame.data == null or frame.data.spread == null:
		return false
	for panel in frame.data.spread.panels:
		var r: Rect2 = Rect2(panel.rect.position + Frame.PANEL_RECT.position, panel.rect.size)
		if r.has_point(player_pos) != r.has_point(pos):
			return true
	return false


func _process(delta: float) -> void:
	if _pending_left > 0.0:
		_pending_left -= delta
		if _pending_left <= 0.0:
			EventBus.caption_requested.emit(_pending, 3.0)
			_pending = ""
			_priority = -1
	for p in _pulses:
		p[1] -= delta
	_pulses = _pulses.filter(func(p: Array) -> bool: return p[1] > 0.0)
	_arrow_left = maxf(0.0, _arrow_left - delta)
	queue_redraw()


func _draw() -> void:
	for p in _pulses:
		var k: float = 1.0 - p[1] / PULSE_TIME
		draw_arc(p[0], 30.0 + k * 90.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.7, (1.0 - k) * 0.9), 6.0 * (1.0 - k) + 1.0)
	if _arrow_left <= 0.0 or _arrow_to == Vector2.INF:
		return
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var from: Vector2 = player.get_global_transform_with_canvas().origin + Vector2(0, -170)
	var dir: Vector2 = (_arrow_to - from).normalized()
	var tip: Vector2 = from + dir * 70.0
	var alpha: float = minf(_arrow_left, 1.0)
	draw_line(from, tip, Color(InkDraw.INK, alpha), 6.0, true)
	draw_colored_polygon(PackedVector2Array([tip + dir * 18.0, tip + dir.orthogonal() * 12.0, tip - dir.orthogonal() * 12.0]), Color(InkDraw.INK, alpha))
