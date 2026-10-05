extends Control
## The twist, drawn in code (about 40 s; beats and captions in RevealBeats).
## Plays when the last word (a story_final bubble) is stolen, or when a save
## resumes in the Ink Heart with it stolen but the reveal unseen. The Shadow
## melts into the Artist's hand ("THE MONSTER WAS THE ARTIST'S HAND."), the
## hand turns its pencil eraser-down and rubs the red figure, then the cost,
## the tearing page, what mends it, and a three-line recap card.
## Then twist_revealed is set, Restart Chapter is re-anchored to the start of
## the return phase, and the player lands there with the goal line showing.
## Skippable (click / Space) only once it has been seen in full before.

const START_DELAY: float = 0.5
const T_RESOLVE: float = 1.4
const FADE: float = 1.4
const GOAL: String = "Give back what you took."
## Wrist of the Artist's hand, in desk space (RevealArt), and its size.
const WRIST: Vector2 = Vector2(1180, 1130)
const HAND_SIZE: float = 900.0
## Where the red figure stands in the drawn panel (0..1 across).
const FIGURE_X: float = 0.36
## Where the monster's silhouette stands over the hand (desk space).
const GHOST_FEET: Vector2 = Vector2(1060, 1720)
const GHOST_SCALE: float = 2.6

var _t: float = -1.0
var _skippable: bool = false
var _owners: Array = []
var _finishing: bool = false
var _beats: Array = []
var _starts: PackedFloat32Array = PackedFloat32Array()
var _ghost: Ghost


## The Ink Shadow's silhouette, drawn under a transform (crossfaded by alpha).
class Ghost:
	extends Node2D
	var t: float = 0.0

	func _draw() -> void:
		CrawlerArt.draw(self, 1.0, int(t * 8.0), -1.0, 0.0, 0.0, 0.7, t, CrawlerArt.PALE, false)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiTheme.make_screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ghost = Ghost.new()
	add_child(_ghost)
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(_abort)
	hide()


func _on_bubble_stolen(bubble: BubbleData, _from: Vector2) -> void:
	if bubble.story_final and not GameState.twist_revealed:
		_start()


## Continue from a save made between the theft and the end of the reveal.
func _on_frame_changed(_data: FrameData) -> void:
	if _t >= 0.0 or GameState.twist_revealed:
		return
	for bubble in GameState.inventory:
		if bubble.story_final:
			_start.call_deferred()
			return


func _start() -> void:
	if _t >= 0.0:
		return
	_t = 0.0
	_finishing = false
	_beats = RevealBeats.beats()
	_starts = RevealBeats.schedule(T_RESOLVE)
	_skippable = SaveSystem.get_progress("seen_reveal")
	_owners = RevealArt.robbed_owners()
	GameState.modal_open = true
	LightingSystem.set_light(false)
	EventBus.interact_prompt_changed.emit("", Vector2.ZERO)
	EventBus.reveal_started.emit()
	modulate.a = 0.0
	show()
	await get_tree().create_timer(START_DELAY, true, false, true).timeout
	# Everything freezes.
	get_tree().paused = true
	AudioManager.play(&"growl", -2.0, 0.0)


func total() -> float:
	return _starts[_starts.size() - 1] + FADE if not _starts.is_empty() else 0.0


func _process(delta: float) -> void:
	if _t < 0.0 or not visible:
		return
	if get_tree().paused:
		_t += delta
	_update_ghost()
	var at: Array = _beat()
	if at[0] >= 0 and _beats[at[0]].id == &"erase" and at[1] > 0.12:
		# The team's recorded cry, cut short as the eraser rubs the figure out.
		AudioManager.play_cry(&"thin", -9.0, 0.0, &"cry_reveal")
	modulate.a = clampf(_t / T_RESOLVE, 0.0, 1.0) if not _finishing else modulate.a
	if _t >= total() and not _finishing:
		_finish()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		accept_event()
		_try_skip()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_try_skip()


func _try_skip() -> void:
	if _skippable and _t > T_RESOLVE and not _finishing:
		_finish()


## Into the return phase: the twist is known, words can go back.
func _finish() -> void:
	_finishing = true
	_t = maxf(_t, total())
	SaveSystem.set_progress("seen_reveal")
	GameState.reveal_twist()
	var target: StringName = GameState.current_chapter.return_frame_id if GameState.current_chapter != null else &""
	if target == &"":
		target = GameState.current_frame_id
	GameState.current_frame_id = target
	GameState.chapter_start = {}
	GameState.chapter_start = GameState.to_dict()
	get_tree().paused = false
	GameState.modal_open = false
	FrameManager.go_to(target)
	EventBus.goal_changed.emit(GOAL)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_callback(_reset)


func _abort() -> void:
	if _t >= 0.0:
		get_tree().paused = false
	_reset()


func _reset() -> void:
	_t = -1.0
	_finishing = false
	hide()


## The beat playing now and how far into it (0..1).
func _beat() -> Array:
	for i in range(_beats.size() - 1, -1, -1):
		if _t >= _starts[i]:
			return [i, clampf((_t - _starts[i]) / (_starts[i + 1] - _starts[i]), 0.0, 1.0)]
	return [-1, 0.0]


## Fits desk-space rect `r` to the screen.
func _view_for(r: Rect2) -> Transform2D:
	var s: float = minf(size.x / r.size.x, size.y / r.size.y)
	return Transform2D(0.0, Vector2(s, s), 0.0, size * 0.5 - r.get_center() * s)


## The monster's silhouette: standing in its panel, it swells toward the hand
## and dissolves into it (morph); later a faint ghost over the hand (monster).
func _update_ghost() -> void:
	var at: Array = _beat()
	var id: StringName = _beats[maxi(at[0], 0)].id if not _beats.is_empty() else &""
	var k: float = at[1]
	var alpha: float = 0.0
	var grow: float = 1.0
	if id == &"morph":
		alpha = 1.0 - smoothstep(0.55, 0.95, k)
		grow = smoothstep(0.2, 0.9, k)
	elif id == &"monster":
		alpha = 0.6 * sin(k * PI)
	_ghost.visible = alpha > 0.01
	if not _ghost.visible:
		return
	var panel_feet: Vector2 = RevealArt.HEART_PANEL.position + Vector2(940, 520)
	var feet: Vector2 = panel_feet.lerp(GHOST_FEET, grow)
	var scale: float = lerpf(1.0, GHOST_SCALE, grow)
	_ghost.modulate.a = alpha
	_ghost.t = _t
	_ghost.transform = _view_for(RevealBeats.camera(id, k, WRIST, FIGURE_X)) * Transform2D(0.0, Vector2(scale, scale), 0.0, feet)
	_ghost.queue_redraw()


func _draw() -> void:
	if _t < 0.0 or _beats.is_empty():
		return
	var tick: int = InkDraw.boil_tick()
	var at: Array = _beat()
	var index: int = maxi(at[0], 0)
	var k: float = at[1]
	var id: StringName = _beats[index].id
	match id:
		&"stole", &"tore", &"mend":
			RevealArt.cost(self, size, _owners, clampf((_t - _starts[5]) / 0.25, 0.0, 1.0), tick)
			RevealArtTear.tear(self, size, clampf((_t - _starts[6]) / 2.0, 0.0, 1.0), clampf((_t - _starts[7]) / 2.5, 0.0, 1.0), tick)
		&"recap":
			RevealBeats.recap(self, size, k, tick)
		_:
			_draw_desk(id, k, tick)
	var text: String = _beats[index].text if at[0] >= 0 else ""
	var alpha: float = clampf((_t - _starts[index]) / 0.4, 0.0, 1.0) * clampf((_starts[index + 1] - _t) / 0.3, 0.0, 1.0)
	if text != "":
		RevealArt.caption(self, text, Vector2(size.x * 0.5, 70.0), alpha, tick + index)
	if id == &"hand":
		RevealBeats.label_card(self, size, clampf((k - 0.15) / 0.15, 0.0, 1.0), tick + 20)
	var fade_from: float = _starts[_starts.size() - 1]
	if _t > fade_from:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clampf((_t - fade_from) / FADE, 0.0, 1.0)))
	if _skippable and _t > T_RESOLVE:
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, size.y - 24), "click / space: skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.5))


## The desk, the page, the hand (and the monster's ghost melting into it).
func _draw_desk(id: StringName, k: float, tick: int) -> void:
	var view: Transform2D = _view_for(RevealBeats.camera(id, k, WRIST, FIGURE_X))
	RevealArt.set_view(self, view)
	RevealArt.desk(self, tick)
	var rubbed: float = k * 0.9 if id == &"erase" else 0.0
	RevealArt.page(self, FIGURE_X, rubbed, tick)
	if id == &"erase":
		RevealBeats.eraser_hand(self, FIGURE_X, HAND_SIZE, k, _t, tick)
	else:
		var hand_alpha: float = smoothstep(0.45, 0.9, k) if id == &"morph" else 1.0
		var shadow: float = 1.0 - smoothstep(0.5, 1.0, k) if id == &"morph" else 0.0
		HandArt.draw(self, WRIST + Vector2(sin(_t * 0.8) * 12.0, 0), HAND_SIZE, tick * 7, 0.0, &"pen", shadow, hand_alpha)
	RevealArt.set_view(self, Transform2D.IDENTITY)
