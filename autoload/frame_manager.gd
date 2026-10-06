extends Node
## Loads FrameData by id and swaps the active Frame scene, wrapped in a
## TransitionManager effect when one is given.

const FRAME_SCENE: PackedScene = preload("res://scenes/frame.tscn")
const FRAME_DATA_PATH: String = "res://data/frames/%s.tres"

var current_frame: Frame

var _frame_root: Node2D
var _player: Player
var _busy: bool = false


func _ready() -> void:
	EventBus.exit_entered.connect(_on_exit_entered)
	EventBus.player_caught.connect(_on_player_caught)


func register_world(frame_root: Node2D, player: Player) -> void:
	_frame_root = frame_root
	_player = player


func load_frame_data(frame_id: StringName) -> FrameData:
	var path: String = FRAME_DATA_PATH % frame_id
	if not ResourceLoader.exists(path):
		push_error("FrameManager: no frame data at %s" % path)
		return null
	var data: FrameData = load(path) as FrameData
	if OS.is_debug_build() and data != null:
		_validate(data)
	return data


## Catches data mistakes that would otherwise loop or strand the player.
func _validate(data: FrameData) -> void:
	for exit in data.exits:
		if exit.area.has_point(data.player_spawn):
			push_warning("%s: default spawn is inside an exit area" % data.id)
		if not ResourceLoader.exists(FRAME_DATA_PATH % exit.target_frame_id):
			push_warning("%s: exit leads to missing frame '%s'" % [data.id, exit.target_frame_id])
	if not data.walk_area.has_point(data.player_spawn):
		push_warning("%s: spawn is outside the walk area" % data.id)


## Moves the player into another frame. `spawn_override` is in panel
## coordinates (Vector2.INF = the frame's default). A negative style swaps
## instantly.
func go_to(frame_id: StringName, spawn_override: Vector2 = Vector2.INF, style: int = -1) -> void:
	if _busy:
		return
	var data: FrameData = load_frame_data(frame_id)
	if data == null:
		return
	var spawn: Vector2 = data.player_spawn if spawn_override == Vector2.INF else spawn_override

	if style < 0:
		_swap_to(data, spawn)
		return

	_busy = true
	var controls_were_enabled: bool = _player.controls_enabled
	_player.controls_enabled = false
	var from_focus: Vector2 = _player.get_global_transform_with_canvas().origin + Vector2(0, -60)
	var to_focus: Vector2 = Frame.PANEL_RECT.position + spawn + Vector2(0, -60)
	await TransitionManager.play(style, _swap_to.bind(data, spawn), from_focus, to_focus)
	_player.controls_enabled = controls_were_enabled
	_busy = false


func clear() -> void:
	if current_frame != null:
		_frame_root.remove_child(current_frame)
		current_frame.queue_free()
		current_frame = null


func _on_exit_entered(exit: ExitData) -> void:
	# ExitZone only reports open exits (and gives the locked-exit caption).
	if exit.required_flag != &"" and not GameState.has_flag(exit.required_flag):
		return
	go_to(exit.target_frame_id, exit.target_spawn, exit.transition_style)


## Caught by the Crawler: back to this frame's spawn. Inventory and flags
## live in GameState, so nothing stolen is lost.
func _on_player_caught() -> void:
	go_to(GameState.current_frame_id, Vector2.INF, ExitData.TransitionStyle.INK_SPLASH)


func _swap_to(data: FrameData, spawn: Vector2) -> void:
	if current_frame != null:
		# Remove right away so its CanvasModulate stops affecting the new frame.
		_frame_root.remove_child(current_frame)
		current_frame.queue_free()

	current_frame = FRAME_SCENE.instantiate() as Frame
	current_frame.position = Frame.PANEL_RECT.position
	_frame_root.add_child(current_frame)
	current_frame.setup(data)

	_player.global_position = current_frame.to_global(spawn)
	_player.velocity = Vector2.ZERO
	_player.walk_area = Rect2(current_frame.to_global(data.walk_area.position), data.walk_area.size)

	GameState.current_frame_id = data.id
	EventBus.frame_changed.emit(data)
