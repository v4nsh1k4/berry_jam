extends Control
## The twist, drawn in code (about 35 s). Plays when the last word (a
## story_final bubble) is stolen, or when a save resumes in the Ink Heart with
## it stolen but the reveal unseen. One idea per caption, each on its beat:
##   the Shadow resolves into a hand holding a pen -> pull back: the panel is
##   a drawing on a page -> the Artist's desk -> back in on the red figure ->
##   the hand swaps to an eraser and rubs the figure out -> the cost: the
##   characters you robbed, the page tearing, and what mends it.
## Then twist_revealed is set, Restart Chapter is re-anchored to the start of
## the return phase, and the player lands there with the goal line showing.
## Skippable (click / Space) only once it has been seen in full before.

const START_DELAY: float = 0.5
const T_RESOLVE: float = 1.4
const T_PULL: float = 5.5
const T_WIDE: float = 9.5
const T_DESK: float = 11.0
const T_DESK_HOLD: float = 13.0
const T_FIGURE: float = 15.0
const T_ERASE: float = 17.4
const T_COST: float = 24.0
const T_TEAR: float = 27.8
const T_MEND: float = 30.8
const T_FADE: float = 34.2
const T_END: float = 35.6
const CAPTIONS: PackedStringArray = [
	"The hand holds a pen.",
	"This comic has an Artist.",
	"Everyone here says only what the Artist wrote.",
	"I was never written. I am a stray mark, a mistake in the ink.",
	"The Artist is erasing me. The monster was never a monster.",
	"It was the Artist's hand.",
	"And every word I stole was a line the Artist drew.",
	"Every theft tore the page.",
	"To mend it, I must give it all back.",
]
const CAPTION_AT: PackedFloat32Array = [2.0, 5.9, 9.8, 13.4, 17.6, 21.3, 24.3, 27.9, 30.9]
const GOAL: String = "Give back what you took."
## Wrist of the Artist's hand, in desk space (RevealArt), and its size.
const WRIST: Vector2 = Vector2(1180, 1130)
const HAND_SIZE: float = 900.0
## Where the red figure stands in the drawn panel (0..1 across), just left of
## the pen's nib so the hand never hides it.
const FIGURE_X: float = 0.36

var _t: float = -1.0
var _skippable: bool = false
var _owners: Array = []
var _finishing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiTheme.make_screen(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
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


func _process(delta: float) -> void:
	if _t < 0.0 or not visible:
		return
	if get_tree().paused:
		_t += delta
	modulate.a = clampf(_t / T_RESOLVE, 0.0, 1.0) if not _finishing else modulate.a
	if _t >= T_END and not _finishing:
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
	_t = maxf(_t, T_END)
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


## Fits desk-space rect `r` to the screen.
func _view_for(r: Rect2) -> Transform2D:
	var s: float = minf(size.x / r.size.x, size.y / r.size.y)
	return Transform2D(0.0, Vector2(s, s), 0.0, size * 0.5 - r.get_center() * s)


func _camera() -> Rect2:
	var panel: Rect2 = RevealArt.HEART_PANEL
	var page: Rect2 = RevealArt.PAGE.grow(90)
	var desk: Rect2 = Rect2(-900, -500, 3300, 3000)
	var feet: Vector2 = RevealArt.HEART_PANEL.position + Vector2(RevealArt.HEART_PANEL.size.x * FIGURE_X, 500)
	var figure: Rect2 = Rect2(feet - Vector2(380, 300), Vector2(760, 400))
	if _t < T_PULL:
		return panel
	if _t < T_WIDE:
		return _lerp_rect(panel, page, smoothstep(T_PULL, T_WIDE, _t))
	if _t < T_DESK_HOLD:
		return _lerp_rect(page, desk, smoothstep(T_WIDE, T_DESK, _t))
	# Back in on the only coloured thing on the page.
	return _lerp_rect(desk, figure, smoothstep(T_DESK_HOLD, T_FIGURE, _t))


static func _lerp_rect(a: Rect2, b: Rect2, w: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, w), a.size.lerp(b.size, w))


func _draw() -> void:
	if _t < 0.0:
		return
	var tick: int = InkDraw.boil_tick()
	if _t >= T_COST:
		RevealArt.cost(self, size, _owners, clampf((_t - T_COST) / 0.25, 0.0, 1.0), tick)
		RevealArtTear.tear(self, size, smoothstep(T_TEAR, T_TEAR + 2.0, _t), smoothstep(T_MEND, T_MEND + 2.5, _t), tick)
	else:
		RevealArt.set_view(self, _view_for(_camera()))
		RevealArt.desk(self, tick)
		var rubbed: float = 0.25 * smoothstep(T_DESK_HOLD, T_FIGURE, _t) + 0.75 * smoothstep(T_ERASE, T_COST - 0.6, _t)
		RevealArt.page(self, FIGURE_X, rubbed, tick)
		_draw_hand(tick)
		RevealArt.set_view(self, Transform2D.IDENTITY)
	for i in CAPTIONS.size():
		var shown: float = _t - CAPTION_AT[i]
		var until: float = CAPTION_AT[i + 1] - 0.25 if i + 1 < CAPTIONS.size() else T_FADE
		var alpha: float = clampf(shown / 0.4, 0.0, 1.0) * clampf((until - _t) / 0.3, 0.0, 1.0)
		RevealArt.caption(self, CAPTIONS[i], Vector2(size.x * 0.5, 70.0), alpha, tick + i)
	if _t > T_FADE:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clampf((_t - T_FADE) / (T_END - T_FADE), 0.0, 1.0)))
	if _skippable and _t > T_RESOLVE:
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, size.y - 24), "click / space: skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.5))


## The Shadow resolves into the Artist's hand with a pen; later it swaps to
## the eraser, comes down on the red figure and rubs, shedding dust.
func _draw_hand(tick: int) -> void:
	var feet: Vector2 = RevealArt.HEART_PANEL.position + Vector2(RevealArt.HEART_PANEL.size.x * FIGURE_X, 500)
	var shadow: float = 1.0 - smoothstep(T_RESOLVE, T_PULL - 1.0, _t)
	if _t < T_FIGURE + 0.8:
		HandArt.draw(self, WRIST + Vector2(sin(_t * 0.8) * 12.0, 0), HAND_SIZE, tick * 7, 0.0, &"pen", shadow)
		return
	# Smaller than the pen shot so the eraser rubs the legs and the figure
	# stays readable above it.
	var hand_size: float = HAND_SIZE * 0.42
	var rub_target: Vector2 = feet + Vector2(75.0 + sin(_t * 9.0) * 30.0, 12.0)
	var arrive: float = smoothstep(T_FIGURE + 0.8, T_ERASE, _t)
	var lift: float = smoothstep(T_COST - 1.0, T_COST - 0.2, _t)
	var tip: Vector2 = (feet + Vector2(500, -700)).lerp(rub_target, arrive * (1.0 - lift))
	HandArt.draw(self, tip - HandArt.tool_tip(hand_size, &"eraser"), hand_size, tick * 7, 0.0, &"eraser")
	if _t > T_ERASE:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 909
		var since: float = _t - T_ERASE
		for i in 40:
			var born: float = rng.randf_range(0.0, T_COST - T_ERASE)
			var age: float = since - born
			var start: Vector2 = feet + Vector2(rng.randf_range(-70, 70), rng.randf_range(-90, -20))
			if age > 0.0 and age < 2.0:
				draw_rect(Rect2(start + Vector2(rng.randf_range(-20, 20) * age, 60.0 * age), Vector2(6, 4)), RevealArt.SMUDGE)
