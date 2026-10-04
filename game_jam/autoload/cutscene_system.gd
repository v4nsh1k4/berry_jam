extends CanvasLayer
## Short comic-page cutscenes between story beats (CutsceneData files in
## data/cutscenes/, drawn by CutsceneView + CutsceneArt). Each plays once per
## run: its id goes into GameState.seen (saved, and kept across Restart
## Chapter and deaths). It pauses the game; Space / click skips (if allowed).
## Triggers: "first_steal", "resolved:<id>", "frame:<id>", "repaired".

const CUTSCENE_PATHS: PackedStringArray = [
	"res://data/cutscenes/c1_first_steal.tres",
	"res://data/cutscenes/c2_torch.tres",
	"res://data/cutscenes/c3_flashback.tres",
	"res://data/cutscenes/c4_descent.tres",
	"res://data/cutscenes/c5_before_final.tres",
	"res://data/cutscenes/c6_repair.tres",
]
## Ignore skip presses for this long into a cutscene (no accidental skips).
const SKIP_GRACE: float = 0.6

var is_playing: bool = false

var _by_trigger: Dictionary = {}
var _by_id: Dictionary = {}
var _queue: Array[CutsceneData] = []
var _current: CutsceneData
var _beat: int = -1
var _beat_t: float = 0.0
var _total_t: float = 0.0
var _view: CutsceneView


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in CUTSCENE_PATHS:
		var data: CutsceneData = load(path) as CutsceneData
		if data != null:
			_by_trigger[data.trigger] = data
			_by_id[data.id] = data
	_view = CutsceneView.new()
	add_child(_view)
	_view.hide()
	_view.skip_requested.connect(_try_skip)
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.interactable_resolved.connect(_on_resolved)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.comic_repaired.connect(trigger.bind("repaired"))
	EventBus.returned_to_menu.connect(_stop)


func ids() -> PackedStringArray:
	return PackedStringArray(_by_id.keys())


func _on_bubble_stolen(bubble: BubbleData, _from: Vector2) -> void:
	if not bubble.story_final and GameState.stolen_bubble_count == 1:
		# Let the SNATCH! land first.
		await get_tree().create_timer(0.8).timeout
		trigger("first_steal")


func _on_resolved(id: StringName, _kind: StringName, _pos: Vector2) -> void:
	trigger("resolved:%s" % id)


func _on_frame_changed(data: FrameData) -> void:
	trigger("frame:%s" % data.id)


## Plays the cutscene for `key` if there is one and it hasn't been seen.
func trigger(key: String) -> void:
	var data: CutsceneData = _by_trigger.get(key) as CutsceneData
	if data != null and not GameState.seen.has(data.id) and GameState.is_playing:
		play(data)


## Debug: play a cutscene by id even if seen.
func play_id(id: StringName) -> void:
	if _by_id.has(id):
		play(_by_id[id])


func play(data: CutsceneData) -> void:
	if is_playing:
		if not _queue.has(data) and _current != data:
			_queue.append(data)
		return
	is_playing = true
	_current = data
	if not GameState.seen.has(data.id):
		GameState.seen.append(data.id)
	# Never on top of a page turn or the reveal.
	while TransitionManager.is_playing or get_tree().paused:
		await get_tree().process_frame
	if not GameState.is_playing:
		is_playing = false
		return
	_beat = -1
	_total_t = 0.0
	GameState.modal_open = true
	EventBus.interact_prompt_changed.emit("", Vector2.ZERO)
	get_tree().paused = true
	EventBus.cutscene_started.emit(data.id)
	if data.music_cue != &"":
		EventBus.music_cue.emit(data.music_cue)
	_view.show()
	_next_beat()


func _process(delta: float) -> void:
	if not is_playing or _beat < 0:
		return
	_beat_t += delta
	_total_t += delta
	var beat: CutsceneBeat = _current.beats[_beat]
	_view.set_time(_beat_t, _current.skippable and _total_t > SKIP_GRACE)
	if _beat_t >= beat.duration:
		_next_beat()


func _next_beat() -> void:
	_beat += 1
	if _beat >= _current.beats.size():
		_finish()
		return
	_beat_t = 0.0
	var beat: CutsceneBeat = _current.beats[_beat]
	_view.set_beat(beat)
	if beat.page_turn and beat.sfx != &"swoosh":
		AudioManager.play(&"swoosh", -6.0, 0.05)
	if beat.sfx != &"":
		AudioManager.play(beat.sfx, -5.0, 0.0)


func _try_skip() -> void:
	if is_playing and _current != null and _current.skippable and _total_t > SKIP_GRACE:
		_finish()


func _finish() -> void:
	var id: StringName = _current.id
	_view.hide()
	is_playing = false
	_current = null
	_beat = -1
	get_tree().paused = false
	GameState.modal_open = false
	EventBus.cutscene_finished.emit(id)
	if GameState.is_playing:
		GameState.checkpoint()
	if not _queue.is_empty():
		play(_queue.pop_front())


func _stop() -> void:
	_queue.clear()
	if is_playing:
		_view.hide()
		is_playing = false
		_current = null
		get_tree().paused = false
		GameState.modal_open = false
