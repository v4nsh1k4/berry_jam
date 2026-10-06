extends Node
## The "noticed" meter. Fills in about FILL_TIME seconds while the light is on
## in a frame with a Crawler, and by STEP_NOISE for every running (loud) step
## within the Crawler's hearing (InkCrawler.HEARING, 430 px; walking makes no
## noise). Drains in the dark. Full -> player_noticed, back to empty ->
## player_lost. EventBus.notice_sources tells the HUD which is feeding it.
# While concealed (hiding spot or HIDE) it drains 3x faster and light only
# raises it at a quarter of the rate.

const FILL_TIME: float = 3.0
const DRAIN_TIME: float = 5.0
## One running step near the Crawler (a run there fills it in about 3 s).
const STEP_NOISE: float = 0.07
const NOISE_SHOW: float = 0.45

var notice: float = 0.0

var _active: bool = false
var _alerted: bool = false
var _hush_left: float = 0.0
var _concealed: bool = false
var _noise_left: float = 0.0
var _sources: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.crawler_hushed.connect(_on_crawler_hushed)
	EventBus.player_concealed_changed.connect(_on_concealed_changed)
	EventBus.footstep.connect(_on_footstep)


## A running step the Crawler can hear raises the meter.
func _on_footstep(loud: bool) -> void:
	if not _active or not loud or _hush_left > 0.0:
		return
	var crawler: Node2D = get_tree().get_first_node_in_group(&"crawler") as Node2D
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if crawler == null or player == null or crawler.global_position.distance_to(player.global_position) > InkCrawler.HEARING:
		return
	_noise_left = NOISE_SHOW
	_set_notice(clampf(notice + STEP_NOISE * (0.25 if _concealed else 1.0), 0.0, 1.0))
	Hints.once("shift_loud", "Shift is loud. Walk near it.", 4.0, true)

## HUSH: wipe the meter and keep it empty for `duration` seconds.
func _on_crawler_hushed(duration: float) -> void:
	_hush_left = duration
	_set_notice(0.0)
	if _alerted:
		_alerted = false
		EventBus.player_lost.emit()


func _on_concealed_changed(concealed: bool) -> void:
	_concealed = concealed


func _on_frame_changed(data: FrameData) -> void:
	# The meter only matters once the player can make light.
	_active = data.crawler_spawn != Vector2.INF and LightingSystem.has_flashlight()
	_alerted = false
	_set_notice(0.0)


func _process(delta: float) -> void:
	if not _active or TransitionManager.is_playing:
		return
	if _hush_left > 0.0:
		_hush_left -= delta
		return
	var rate: float = -delta / DRAIN_TIME * (3.0 if _concealed else 1.0)
	if LightingSystem.is_light_on:
		rate = delta / FILL_TIME * LightingSystem.light_intensity * (0.25 if _concealed else 1.0)
		Hints.once("light_draws", "Light draws it. The blot fills. When it is full, it hunts you.", 6.0, true)
		if notice > 0.5:
			Hints.once("half_full", "Switch the light off and stay still to be safe.", 5.0, true)
	_noise_left = maxf(0.0, _noise_left - delta)
	if _noise_left > 0.0 and rate < 0.0:
		rate = 0.0
	var sources: Vector2i = Vector2i(int(LightingSystem.is_light_on), int(_noise_left > 0.0))
	if sources != _sources:
		_sources = sources
		EventBus.notice_sources.emit(sources.x == 1, sources.y == 1)
	_set_notice(clampf(notice + rate, 0.0, 1.0))
	if notice >= 1.0 and not _alerted:
		_alerted = true
		EventBus.player_noticed.emit()
	elif notice <= 0.0 and _alerted:
		_alerted = false
		EventBus.player_lost.emit()


func _set_notice(value: float) -> void:
	if value != notice:
		notice = value
		EventBus.notice_changed.emit(value)
