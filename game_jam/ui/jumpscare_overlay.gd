extends Node2D
## The game's two scares, each once per run (ids in GameState.seen, so a
## restart or death never replays them), never while a menu, cutscene or
## page turn is up.
##   scare_clock  (major, Chapter 2) just after the clock is read: the
##                Crawler's face fills the screen for 0.35 s with a sting, a
##                hard shake and one short red flash, then it is really there,
##                close, and hunting: run for the unbolted door or hide.
##   scare_margin (minor, Chapter 3) the Artist's hand slams across the page
##                with a pen-nib stab.
## `intensity` (0..1, settings.cfg [accessibility] scare_intensity) scales the
## shake and the flash for Stage 5's "reduce shake and flashing" option.

const SETTINGS_PATH: String = "user://settings.cfg"
const FACE_TIME: float = 0.35
const FLASH_TIME: float = 0.15
const HAND_TIME: float = 0.45
const CLOCK_DELAY: float = 0.6
const MARGIN_DELAY: float = 1.6

static var intensity: float = 1.0

var _kind: StringName = &""
var _t: float = 0.0
var _seed: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		intensity = clampf(float(cfg.get_value("accessibility", "scare_intensity", 1.0)), 0.0, 1.0)
	EventBus.interactable_resolved.connect(_on_resolved)
	EventBus.frame_changed.connect(_on_frame_changed)


func _on_resolved(id: StringName, _kind_name: StringName, _pos: Vector2) -> void:
	if id == &"grandfather_clock":
		_after(CLOCK_DELAY, &"scare_clock")


func _on_frame_changed(data: FrameData) -> void:
	if data.id == &"ch3_margin":
		_after(MARGIN_DELAY, &"scare_margin")


func _after(delay: float, kind: StringName) -> void:
	if GameState.seen.has(kind):
		return
	await get_tree().create_timer(delay).timeout
	play(kind)


## Plays a scare now (debug: even if seen).
func play(kind: StringName) -> void:
	if not GameState.is_playing or GameState.modal_open or TransitionManager.is_playing or get_tree().paused:
		return
	if not GameState.seen.has(kind):
		GameState.seen.append(kind)
	_kind = kind
	_t = 0.0
	_seed = randi()
	EventBus.scare.emit(kind, intensity)
	if kind == &"scare_clock":
		AudioManager.play(&"scare_hit", 0.0, 0.0)
		EventBus.shake_requested.emit(0.9 * intensity)
		_crawler_strikes()
	else:
		AudioManager.play(&"slam", -2.0, 0.05)
		AudioManager.play(&"nib", 0.0, 0.0)
		EventBus.shake_requested.emit(0.4 * intensity)
	queue_redraw()


## The gameplay half: the Crawler is there, a few steps behind, hunting.
func _crawler_strikes() -> void:
	var crawler: InkCrawler = get_tree().get_first_node_in_group(&"crawler") as InkCrawler
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if crawler == null or player == null or crawler.is_frozen() or player.is_concealed():
		return
	var at: Vector2 = crawler.get_parent().to_local(player.global_position)
	crawler.appear_at(at + Vector2(-330.0 if at.x > 420.0 else 330.0, 0.0))
	crawler.wake_to(true, 3.0)


func _process(delta: float) -> void:
	if _kind == &"":
		return
	_t += delta
	queue_redraw()
	if _t > (FACE_TIME if _kind == &"scare_clock" else HAND_TIME):
		_kind = &""
		queue_redraw()


func _draw() -> void:
	if _kind == &"scare_clock":
		_draw_face()
	elif _kind == &"scare_margin":
		_draw_hand()


func _draw_face() -> void:
	var screen: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), InkDraw.PAPER)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed
	var c: Vector2 = screen * 0.5 + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10))
	var grow: float = 1.0 + _t * 0.6
	# A pen attack: strokes slashing out from the face.
	for i in 26:
		var a: float = rng.randf() * TAU
		var from: Vector2 = c + Vector2.from_angle(a) * rng.randf_range(120, 220) * grow
		InkDraw.line(self, from, from + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * rng.randf_range(200, 600), rng.randf_range(4, 14), i, InkDraw.INK, 6.0)
	var head: PackedVector2Array = PackedVector2Array()
	for i in 22:
		var a: float = TAU * i / 22.0
		head.append(c + Vector2(cos(a) * 300.0, sin(a) * 330.0) * grow * rng.randf_range(0.82, 1.12))
	InkDraw.fill(self, head, InkDraw.INK)
	var eyes: Array[Vector3] = [Vector3(-120, -90, 46), Vector3(95, -110, 30), Vector3(10, -10, 24), Vector3(170, 20, 14), Vector3(-200, 10, 12)]
	for e in eyes:
		var at: Vector2 = c + Vector2(e.x, e.y) * grow
		draw_circle(at, e.z * grow, CrawlerArt.PALE)
		draw_circle(at + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)), e.z * 0.22 * grow, InkDraw.INK)
	# The torn mouth, ringed with pen nibs.
	var mouth: PackedVector2Array = PackedVector2Array()
	for i in 12:
		mouth.append(c + Vector2(-230 + i * 42, 110 + rng.randf_range(-14, 14)) * grow)
	for i in range(11, -1, -1):
		mouth.append(c + Vector2(-230 + i * 42, 230 + rng.randf_range(-30, 30) - absf(i - 5.5) * 8.0) * grow)
	InkDraw.fill(self, mouth, Color(0.85, 0.82, 0.76))
	for i in 11:
		CrawlerArt.nib(self, c + Vector2(-210 + i * 42, 128) * grow, PI * 0.5, 16.0 * grow)
		CrawlerArt.nib(self, c + Vector2(-210 + i * 42, 205) * grow, -PI * 0.5, 14.0 * grow)
	if _t < FLASH_TIME:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(InkDraw.RED, 0.45 * intensity * (1.0 - _t / FLASH_TIME)))


func _draw_hand() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var k: float = ease(clampf(_t / (HAND_TIME * 0.5), 0.0, 1.0), 0.3)
	var at: Vector2 = Vector2(screen.x * 1.2, -screen.y * 0.4).lerp(Vector2(screen.x * 0.62, screen.y * 0.18), k)
	HandArt.draw(self, at, 760.0, _seed, 0.0, &"pen", 0.6, clampf(1.6 - _t / HAND_TIME * 1.6, 0.0, 1.0))
