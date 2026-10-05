extends Node2D
## The game's scares (art in ScareArt). Each fires ONCE per run: its id goes
## into GameState.seen (saved, kept across deaths and Restart Chapter). A scare
## is triggered by a flag in its room (EventBus.flag_set), then WAITS (never
## dropped) until it is fair: no menu, cutscene, page turn or dial UI; no
## Crawler chasing or stalking; not mid-hop; at least COOLDOWN seconds since
## the last scare. Never in the return phase. Each: 0.3-0.5 s of art, a loud
## sting, a hard shake and one short red flash, then normal play.
## A scare with `build` seconds (Stage 5's cellar scare) first goes quiet:
## EventBus.scare_building drops the music and ambience, the team's recorded
## cry (low variant) grows from far to near, the panel's light flickers out
## (and the torch with it), then the hit. A menu, cutscene, page turn or
## leaving the room during the build calls it off; it waits to try again.
##   scare_hallway   lights die, the face beside you    (hall ink door clears)
##   scare_gallery   a portrait snaps its face round   (gallery lever)
##   scare_passage   the wardrobe flies open on a face (the stalker gives up)
##   scare_clock     the Crawler's face, then it hunts (the clock face read)
##   scare_hand      the Hand slams a nib stab across the page (lens lit)
##   scare_cellar    silence, a cry, lights out, then a huge distorted face
##                   (the cellar's shadow puzzle solved: the player relaxes)
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
var _building: Dictionary = {}
var _build_t: float = 0.0


## Built at runtime (typed constant arrays of containers misbehave in exports).
static func scares() -> Array:
	return [
		{id = &"scare_hallway", frame = &"ch2_long_hallway", flag = &"hall_panel_open", delay = 1.0, art = &"lights", length = 0.5},
		{id = &"scare_gallery", frame = &"ch2_gallery", flag = &"gallery_lever", delay = 1.2, art = &"portrait", length = 0.4},
		{id = &"scare_passage", frame = &"ch2_servants_passage", flag = &"survived_passage", delay = 2.0, art = &"wardrobe", length = 0.45},
		{id = &"scare_clock", frame = &"ch2_clock_room", flag = &"clock_read", delay = 0.6, art = &"face", length = 0.35},
		{id = &"scare_hand", frame = &"ch3_gallery_words", flag = &"spread_lens", delay = 1.5, art = &"hand", length = 0.45},
		{id = &"scare_cellar", frame = &"ch2_cellar", flag = &"cellar_dials_set", delay = 1.2, art = &"cry_face", length = 0.5,
			build = 3.0, patience = 90.0},
	]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		intensity = clampf(float(cfg.get_value("accessibility", "scare_intensity", 1.0)), 0.0, 1.0)
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.frame_changed.connect(func(_d: FrameData) -> void: _pending = {}; _abort_build(false))


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
		elif _wait_left < -float(_pending.get("patience", PATIENCE)):
			_pending = {}
	if not _building.is_empty():
		_step_build(delta)
	if _kind != &"":
		_t += delta
		queue_redraw()
		if _t > _length:
			_kind = &""
			queue_redraw()


func _fire(s: Dictionary) -> void:
	if float(s.get("build", 0.0)) > 0.0:
		_start_build(s)
	else:
		_hit(s)


func _hit(s: Dictionary) -> void:
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
	EventBus.shake_requested.emit((1.0 if _kind == &"scare_cellar" else 0.9 if _kind == &"scare_clock" else 0.7) * intensity)
	if _kind == &"scare_cellar":
		AudioManager.stop_cry()
		AudioManager.play(&"scare_low", 2.0, 0.0)
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


## The build-up: quiet, the cry growing, the light flickering out.
func _start_build(s: Dictionary) -> void:
	_building = s
	_build_t = 0.0
	_seed = randi()
	EventBus.scare_building.emit(s.id, s.build)
	AudioManager.play_cry(&"low", -3.0, float(s.build) * 0.85, &"cry_scare")


func _step_build(delta: float) -> void:
	if not GameState.is_playing or GameState.modal_open or get_tree().paused or CutsceneSystem.is_playing or TransitionManager.is_playing:
		_abort_build(true)
		return
	_build_t += delta
	var k: float = _build_t / float(_building.build)
	# The torch dies with the room's light: a few flickers, then off.
	if k > 0.6 and LightingSystem.is_light_on != ScareArt.lit(k, _build_t):
		LightingSystem.set_light(ScareArt.lit(k, _build_t))
	queue_redraw()
	if k >= 1.0:
		var s: Dictionary = _building
		_building = {}
		_hit(s)


## Called off mid-build (a menu, a cutscene, a page turn): undo the quiet and
## wait for another fair moment (unless the player left the room).
func _abort_build(retry: bool) -> void:
	if _building.is_empty():
		return
	AudioManager.stop_cry()
	GameState.seen.erase(&"cry_scare")
	EventBus.scare_building.emit(_building.id, 0.0)
	if retry:
		_pending = _building
		_wait_left = 1.0
	_building = {}
	queue_redraw()


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
	if not _building.is_empty():
		ScareArt.blackout(self, Frame.PANEL_RECT, _build_t / float(_building.build), _build_t)
	if _kind == &"":
		return
	var screen: Vector2 = get_viewport_rect().size
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var player_pos: Vector2 = player.get_global_transform_with_canvas().origin if player != null else screen * 0.5
	ScareArt.draw(self, _art, screen, _t, _seed, player_pos)
	if _t < FLASH_TIME:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(InkDraw.RED, 0.45 * intensity * (1.0 - _t / FLASH_TIME)))
