extends Node
## Root of the game and its flow: click to start -> menu -> chapter intro ->
## chapter -> (next chapter's intro -> ...) -> end card -> menu. Everything
## else talks over EventBus.

## The chapter a new game starts with.
@export var chapter: ChapterData

## Seconds the last panel of a chapter stays up before the next intro.
const CHAPTER_HANDOFF: float = 1.5

@onready var _frame_root: Node2D = $World/FrameRoot
@onready var _player: Player = $World/Player
@onready var _start_layer: CanvasLayer = $StartLayer
@onready var _menu: Control = $MenuLayer/MainMenu
@onready var _intro: Control = $MenuLayer/IntroSequence

## Chapter whose intro is playing; it starts when the intro ends.
var _pending: ChapterData


func _ready() -> void:
	FrameManager.register_world(_frame_root, _player)
	_player.visible = false
	EventBus.game_started.connect(_on_click_to_start)
	EventBus.menu_new_game.connect(_on_new_game)
	EventBus.menu_continue.connect(_on_continue)
	EventBus.intro_finished.connect(_on_intro_finished)
	EventBus.restart_chapter_requested.connect(_on_restart_chapter)
	EventBus.quit_to_menu_requested.connect(_on_quit_to_menu)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.bubble_stolen.connect(_on_progress.unbind(2))
	EventBus.interactable_resolved.connect(_on_progress.unbind(3))


func _on_click_to_start() -> void:
	_start_layer.hide()
	var jump: String = DebugJump.requested_frame()
	var jump_chapter: ChapterData = DebugJump.prepare(jump) if jump != "" else null
	if jump_chapter != null:
		_start_chapter(jump_chapter)
		FrameManager.go_to(StringName(jump))
		return
	_menu.open()


func _on_new_game() -> void:
	GameState.reset()
	GameState.current_chapter = null
	SaveSystem.clear()
	_play_intro(chapter)


func _play_intro(next: ChapterData) -> void:
	_pending = next
	_intro.play(next)


func _on_intro_finished() -> void:
	if _pending != null:
		_start_chapter(_pending)
		_pending = null


## Begins a chapter: remembers the state it started from (for Restart
## Chapter) and applies its look (line wobble).
func _start_chapter(next: ChapterData) -> void:
	GameState.current_chapter = next
	GameState.chapter_start = {}
	GameState.current_frame_id = next.first_frame_id
	GameState.chapter_start = GameState.to_dict()
	_apply_chapter_look()
	_begin(next.first_frame_id)


func _apply_chapter_look() -> void:
	InkDraw.jitter_scale = GameState.current_chapter.line_jitter if GameState.current_chapter != null else 1.0
	EventBus.comic_damage_changed.emit(GameState.comic_damage)


func _on_continue() -> void:
	if GameState.from_dict(SaveSystem.load_game()):
		if GameState.current_chapter == null:
			GameState.current_chapter = chapter
		_apply_chapter_look()
		_begin(GameState.current_frame_id)
	else:
		_on_new_game()


func _begin(frame_id: StringName) -> void:
	GameState.is_playing = true
	_player.visible = true
	_player.controls_enabled = true
	FrameManager.go_to(frame_id)


## Back to how this chapter began: words carried in from earlier chapters
## stay, anything taken in this chapter goes back.
func _on_restart_chapter() -> void:
	var start: Dictionary = GameState.chapter_start
	var current: ChapterData = GameState.current_chapter if GameState.current_chapter != null else chapter
	if start.is_empty() or not GameState.from_dict(start):
		GameState.reset()
	GameState.current_chapter = current
	GameState.chapter_start = start
	GameState.is_playing = true
	_apply_chapter_look()
	FrameManager.go_to(current.first_frame_id, Vector2.INF, ExitData.TransitionStyle.INK_SPLASH)


func _on_quit_to_menu() -> void:
	_on_progress()
	GameState.is_playing = false
	GameState.modal_open = false
	FrameManager.clear()
	_player.visible = false
	InkDraw.jitter_scale = 1.0
	EventBus.interact_prompt_changed.emit("", Vector2.ZERO)
	EventBus.returned_to_menu.emit()


func _on_frame_changed(data: FrameData) -> void:
	_on_progress()
	if data.next_chapter != null and GameState.is_playing:
		_hand_off(data.next_chapter)


## The last panel of a chapter holds for a beat, then the next intro plays.
func _hand_off(next: ChapterData) -> void:
	_player.controls_enabled = false
	await get_tree().create_timer(CHAPTER_HANDOFF).timeout
	if GameState.is_playing:
		_player.controls_enabled = true
		_play_intro(next)


## Checkpoint on every frame, theft and solved object: being caught never
## loses a word (the frame reloads with GameState intact) and Continue picks
## up here.
func _on_progress() -> void:
	if GameState.is_playing:
		GameState.checkpoint()
