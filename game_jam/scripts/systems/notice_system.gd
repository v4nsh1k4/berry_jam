extends Node
## The "noticed" meter. Fills in about FILL_TIME seconds while the light is on
## in a frame with a Crawler, drains in the dark. Full -> player_noticed,
## back to empty -> player_lost.
# While concealed (hiding spot or HIDE) it drains 3x faster and light only
# raises it at a quarter of the rate.

const FILL_TIME: float = 3.0
const DRAIN_TIME: float = 5.0

var notice: float = 0.0

var _active: bool = false
var _alerted: bool = false
var _hush_left: float = 0.0
var _concealed: bool = false


func _ready() -> void:
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.crawler_hushed.connect(_on_crawler_hushed)
	EventBus.player_concealed_changed.connect(_on_concealed_changed)


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
