extends Node2D
## The game's scares (art in ScareArt). Each fires ONCE per run: its id goes
## into GameState.seen (saved, kept across deaths and Restart Chapter). A scare
## is triggered by a flag in its room (EventBus.flag_set), then WAITS (never
## dropped) until it is fair: no menu, cutscene, page turn or dial UI; no
## Crawler chasing or stalking; not mid-hop; at least COOLDOWN seconds since
## the last scare. Never in the return phase. Each: 0.3-0.5 s of art, a loud
## sting, a hard shake and one short red flash, then normal play.
##   scare_hallway   lights die, the face beside you    (hall ink door clears)
##   scare_gallery   a portrait snaps its face round   (gallery lever)
##   scare_passage   the wardrobe flies open on a face (the stalker gives up)
##   scare_clock     the Crawler's face, then it hunts (the clock face read)
##   scare_hand      the Hand slams a nib stab across the page (lens lit)
## `intensity` (0..1, settings.cfg [accessibility] scare_intensity) scales
## shake and flash for Stage 5's "reduce shake and flashing" option.

const SETTINGS_PATH: String = "user://settings.cfg"
const FLASH_TIME: float = 0.15
const COOLDOWN: float = 60.0
## Give up waiting for a fair moment after this long (left the room etc.).
const PATIENCE: float = 25.0

static var intensity: float = 1.0

var _kind: StringName = &""
var _art: StringName = &""
var _length: float = 0.4
var _t: float = 0.0
var _seed: int = 0
var _pending: Dictionary = {}
var _wait_left: float = 0.0
var _since_last: float = 999.0
var _debug_index: int = -1


## Built at runtime (typed constant arrays of containers misbehave in exports).
static func scares() -> Array:
	return [
		{id = &"scare_hallway", frame = &"ch2_long_hallway", flag = &"hall_panel_open", delay = 1.0, art = &"lights", length = 0.5},
		{id = &"scare_gallery", frame = &"ch2_gallery", flag = &"gallery_lever", delay = 1.2, art = &"portrait", length = 0.4},
		{id = &"scare_passage", frame = &"ch2_servants_passage", flag = &"survived_passage", delay = 2.0, art = &"wardrobe", length = 0.45},
		{id = &"scare_clock", frame = &"ch2_clock_room", flag = &"clock_read", delay = 0.6, art = &"face", length = 0.35},
		{id = &"scare_hand", frame = &"ch3_gallery_words", flag = &"spread_lens", delay = 1.5, art = &"hand", length = 0.45},
	]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		intensity = clampf(float(cfg.get_value("accessibility", "scare_intensity", 1.0)), 0.0, 1.0)
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.frame_changed.connect(func(_d: FrameData) -> void: _pending = {})


func _on_flag_set(flag: StringName) -> void:
	for s in scares():
		if s.flag == flag and not GameState.seen.has(s.id) and FrameManager.current_frame != null \
				and FrameManager.current_frame.data.id == s.frame and not GameState.twist_revealed:
			_pending = s
			_wait_left = s.delay
			return


func _fair() -> bool:
	if not GameState.is_playing or GameState.modal_open or TransitionManager.is_playing or get_tree().paused:
		return false
	if CutsceneSystem.is_playing or _since_last < COOLDOWN or GameState.twist_revealed:
		return false
	for c in get_tree().get_nodes_in_group(&"crawler"):
		if c.get("state") != null and int(c.state) in [InkCrawler.State.STALKING, InkCrawler.State.HUNTING,
				InkCrawler.State.TELEGRAPH, InkCrawler.State.LUNGE, InkCrawler.State.SEARCHING]:
			return false
	var spread: Node = FrameManager.current_frame.get_node("Props").get_child(0) if FrameManager.current_frame != null else null
	if spread is SpreadController and ((spread as SpreadController).hopping or (spread as SpreadController).airborne):
		return false
	return true


func _process(delta: float) -> void:
	_since_last += delta
	if not _pending.is_empty():
		_wait_left -= delta
		if _wait_left <= 0.0 and _fair():
			_fire(_pending)
			_pending = {}
		elif _wait_left < -PATIENCE:
			_pending = {}
	if _kind != &"":
		_t += delta
		queue_redraw()
		if _t > _length:
			_kind = &""
			queue_redraw()


func _fire(s: Dictionary) -> void:
	if not GameState.seen.has(s.id):
		GameState.seen.append(s.id)
	_kind = s.id
	_art = s.art
	_length = s.length
	_t = 0.0
	_seed = randi()
	_since_last = 0.0
	EventBus.scare.emit(_kind, intensity)
	AudioManager.play(&"scare_hit", 0.0, 0.0)
	EventBus.shake_requested.emit((0.9 if _kind == &"scare_clock" else 0.7) * intensity)
	if _kind == &"scare_clock":
		_crawler_strikes()
	queue_redraw()


## Debug (F7): plays the next scare in the list right here, even if seen.
func debug_next() -> StringName:
	var list: Array = scares()
	_debug_index = (_debug_index + 1) % list.size()
	_since_last = COOLDOWN
	_fire(list[_debug_index])
	return list[_debug_index].id


## Plays one scare by id now (tests, debug), even if seen.
func play(id: StringName) -> void:
	for s in scares():
		if s.id == id:
			_fire(s)


## The Clock Room's gameplay half: the Crawler is there, a few steps behind.
func _crawler_strikes() -> void:
	var crawler: InkCrawler = get_tree().get_first_node_in_group(&"crawler") as InkCrawler
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if crawler == null or player == null or crawler.is_frozen() or player.is_concealed():
		return
	var at: Vector2 = crawler.get_parent().to_local(player.global_position)
	crawler.appear_at(at + Vector2(-330.0 if at.x > 420.0 else 330.0, 0.0))
	crawler.wake_to(true, 3.0)


func _draw() -> void:
	if _kind == &"":
		return
	var screen: Vector2 = get_viewport_rect().size
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var player_pos: Vector2 = player.get_global_transform_with_canvas().origin if player != null else screen * 0.5
	ScareArt.draw(self, _art, screen, _t, _seed, player_pos)
	if _t < FLASH_TIME:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(InkDraw.RED, 0.45 * intensity * (1.0 - _t / FLASH_TIME)))
