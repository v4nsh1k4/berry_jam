extends Node
## Root of the game and its flow: click to start -> menu -> (New Game: intro
## cinematic) -> chapter intro -> chapter -> (next chapter's intro -> ...) ->
## Chapter 3: final steal -> reveal -> return phase -> escape -> epilogue ->
## end card -> menu. Everything else talks over EventBus.

## The chapter a new game starts with.
@export var chapter: ChapterData

@onready var _frame_root: Node2D = $World/FrameRoot
@onready var _player: Player = $World/Player
@onready var _start_layer: CanvasLayer = $StartLayer
@onready var _menu: Control = $MenuLayer/MainMenu
@onready var _intro: Control = $MenuLayer/IntroSequence
@onready var _cinematic: Control = $MenuLayer/IntroCinematic

## Chapter whose intro is playing; it starts when the intro ends.
## Debug builds: which cutscene F6 plays next.
var _debug_cutscene: int = -1
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
	EventBus.intro_cinematic_finished.connect(_on_cinematic_finished)
	EventBus.game_completed.connect(_on_game_completed)
	EventBus.comic_repaired.connect(_on_comic_repaired)


func _on_click_to_start() -> void:
	_start_layer.hide()
	var jump: String = DebugJump.requested_frame()
	if jump != "" and _debug_jump(jump):
		return
	_menu.open()


func _on_new_game() -> void:
	GameState.reset()
	GameState.current_chapter = null
	SaveSystem.clear()
	# The controls first: nothing starts until the player presses OK.
	var card: ControlsCard = $MenuLayer/ControlsCard
	card.open()
	await card.accepted
	_cinematic.call("play")


func _on_cinematic_finished() -> void:
	_play_intro(chapter)


func _play_intro(next: ChapterData) -> void:
	_pending = next
	_intro.play(next)


func _on_intro_finished() -> void:
	if _pending != null:
		_start_chapter(_pending)
		_pending = null


## Begins a chapter: remembers the state it started from (for Restart
## Chapter) and applies its look (line wobble). `frame_id` overrides the
## chapter's first frame (debug jumps).
func _start_chapter(next: ChapterData, frame_id: StringName = &"") -> void:
	GameState.modal_open = false
	GameState.current_chapter = next
	GameState.chapter_start = {}
	GameState.current_frame_id = frame_id if frame_id != &"" else next.first_frame_id
	GameState.chapter_start = GameState.to_dict()
	_apply_chapter_look()
	_begin(GameState.current_frame_id)


func _apply_chapter_look() -> void:
	InkDraw.jitter_scale = GameState.current_chapter.line_jitter if GameState.current_chapter != null else 1.0
	if GameState.has_flag(&"comic_repaired"):
		InkDraw.jitter_scale = 1.0
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
	# Cutscenes already watched stay watched: restarting never replays them.
	var seen: Array[StringName] = GameState.seen.duplicate()
	var current: ChapterData = GameState.current_chapter if GameState.current_chapter != null else chapter
	var frame_id: StringName = current.first_frame_id
	if start.is_empty() or not GameState.from_dict(start):
		GameState.reset()
	else:
		# After the reveal the snapshot points at the start of the return phase.
		frame_id = GameState.current_frame_id
	GameState.current_chapter = current
	GameState.chapter_start = start
	GameState.seen = seen
	GameState.is_playing = true
	_apply_chapter_look()
	FrameManager.go_to(frame_id, Vector2.INF, ExitData.TransitionStyle.INK_SPLASH)


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


## The last panel of a chapter hands straight over to the next chapter's
## title card. Stage 7: no walkable hold any more. The player used to get 1.5 s
## (and more) in the hand-off panel, because FrameManager restores the
## controls when its page turn ends; now the card waits only for that page
## turn and for a chapter-end cutscene (C4), the player is held by modal_open
## throughout (FrameManager's restore can't undo that), and only
## _start_chapter gives control back.
func _hand_off(next: ChapterData) -> void:
	GameState.modal_open = true
	_player.controls_enabled = false
	while TransitionManager.is_playing:
		await get_tree().process_frame
	_player.controls_enabled = false
	# A chapter-end cutscene plays first; the next intro waits for it.
	while CutsceneSystem.is_playing:
		await EventBus.cutscene_finished
	if GameState.is_playing:
		_player.controls_enabled = false
		_play_intro(next)


## Checkpoint on every frame, theft and solved object: being caught never
## loses a word (the frame reloads with GameState intact) and Continue picks
## up here.
func _on_progress() -> void:
	if GameState.is_playing:
		GameState.checkpoint()


## The last word went home: the lines stop shaking.
func _on_comic_repaired() -> void:
	create_tween().tween_method(func(value: float) -> void: InkDraw.jitter_scale = value, InkDraw.jitter_scale, 1.0, 2.5)


## Walked out of the page: nothing left to continue. The menu's Continue
## button disappears; a new game starts from the beginning.
func _on_game_completed() -> void:
	GameState.is_playing = false
	_player.controls_enabled = false
	SaveSystem.clear()
	SaveSystem.set_progress("completed")


## Debug builds only (see DebugJump):
##   F6  play the next cutscene (C1..C6, even if seen)
##   F7  play the next jumpscare right here (cycles through all six)
##   F8  the reveal (jumps to the Ink Heart and takes ERASE)
##   F9  the next Chapter 3 room, with the words a player would have there
##   F10 the page spread (Gallery of Words)
func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if not OS.is_debug_build() or key == null or not key.pressed or key.echo:
		return
	if not GameState.is_playing or TransitionManager.is_playing or CutsceneSystem.is_playing:
		return
	match key.keycode:
		KEY_F6:
			var ids: PackedStringArray = CutsceneSystem.ids()
			ids.sort()
			_debug_cutscene = (_debug_cutscene + 1) % ids.size()
			CutsceneSystem.play_id(StringName(ids[_debug_cutscene]))
		KEY_F7:
			EventBus.caption_requested.emit("DEBUG: %s" % $FXLayer/JumpscareOverlay.debug_next(), 2.0)
		KEY_F8:
			if _debug_jump("ch3_ink_heart"):
				await get_tree().create_timer(1.5).timeout
				GameState.add_bubble(load("res://data/bubbles/hand_erase.tres"))
		KEY_F9:
			var next: String = DebugJump.next_room(String(GameState.current_frame_id))
			if _debug_jump(next):
				EventBus.caption_requested.emit("DEBUG: %s" % next, 2.0)
		KEY_F10:
			_debug_jump("ch3_gallery_words")


func _debug_jump(frame_id: String) -> bool:
	var jump_chapter: ChapterData = DebugJump.prepare(frame_id)
	if jump_chapter == null:
		return false
	_start_chapter(jump_chapter, StringName(frame_id))
	return true
