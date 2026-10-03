extends Node2D
## Chapter 2's one scare: the first time a word is stolen from Mrs. Vane, long
## jointed fingers curl round the pantry doorframe behind her, hold, and
## withdraw. Nothing chases you. Nothing explains it.
# TODO(later): the same fingers are the Artist's hand in Chapter 3.

const FLAG: StringName = &"seen_pantry_fingers"
const OWNER_ID: StringName = &"mrs_vane"
## Inside the pantry doorway; the fingers reach out over its frame onto the
## wall (panel coordinates).
const FRAME_EDGE: Vector2 = Vector2(1092, 150)
const DURATION: float = 2.6
const POSE_FPS: float = 8.0

var _playing: bool = false
var _t: float = 0.0
var _pose_left: float = 0.0
var _seed: int = 0


func _ready() -> void:
	if GameState.has_flag(FLAG):
		queue_free()
		return
	EventBus.bubble_stolen.connect(_on_bubble_stolen)


func _on_bubble_stolen(bubble: BubbleData, _from: Vector2) -> void:
	if _playing or bubble.stolen_from != OWNER_ID:
		return
	_playing = true
	GameState.set_flag(FLAG)
	EventBus.crawler_telegraph.emit()
	EventBus.shake_requested.emit(0.2)


func _process(delta: float) -> void:
	if not _playing:
		return
	_t += delta
	_pose_left -= delta
	if _pose_left <= 0.0:
		_pose_left = 1.0 / POSE_FPS
		_seed = randi()
		queue_redraw()
	if _t >= DURATION:
		queue_free()


func _draw() -> void:
	if not _playing:
		return
	var out: float = smoothstep(0.0, 0.6, _t) * (1.0 - smoothstep(1.9, DURATION, _t))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed
	for i in 3:
		var base: Vector2 = FRAME_EDGE + Vector2(6, 40 + i * 38)
		CrawlerArt.finger(self, base, PI + 0.15 * (i - 1), 30.0 + 110.0 * out, 4, rng.randi(), 5.0, -0.45)
