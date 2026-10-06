class_name MusicLayers
extends Node
## MusicManager's build-up layers (split out in Stage 6, behaviour unchanged):
## a low pulse once the Crawler is up (or you're noticed, or the hand
## erases), the string swell with the noticed meter / nearness / the hand's
## erasing, and the hunt rhythm on top while it hunts.

var _intensity: AudioStreamPlayer
var _hunt: AudioStreamPlayer
var _pulse: AudioStreamPlayer
## The Crawler is up (any state but dormant): the first build-up layer.
var _risen: bool = false
## Jumps each time the Artist's hand erases; decays (the final room).
var _erase_boost: float = 0.0
var _notice: float = 0.0
var _near: float = 0.0
var _hunting: bool = false


func setup(make_player: Callable) -> void:
	_intensity = make_player.call()
	_hunt = make_player.call()
	_pulse = make_player.call()
	EventBus.hand_erase.connect(func(_p: Vector2) -> void: _erase_boost = minf(_erase_boost + 0.35, 1.0))
	EventBus.notice_changed.connect(func(v: float) -> void: _notice = v)
	EventBus.crawler_proximity.connect(func(v: float, _m: bool) -> void: _near = v)
	EventBus.crawler_state_changed.connect(_on_crawler_state)
	EventBus.frame_changed.connect(func(_d: FrameData) -> void: _hunting = false; _risen = false)


func _on_crawler_state(state: StringName) -> void:
	_hunting = state in [&"HUNTING", &"TELEGRAPH", &"LUNGE"]
	_risen = state != &"DORMANT"


## `base` = MusicManager.BASE_DB; `ensure` starts a layer once it's rendered.
func update(delta: float, base: float, duck_db: float, ensure: Callable) -> void:
	var speed: float = delta * 30.0
	_erase_boost = maxf(0.0, _erase_boost - delta * 0.08)
	var pulse_on: bool = _risen or _notice > 0.1 or _erase_boost > 0.05
	_pulse.volume_db = move_toward(_pulse.volume_db, (base - 3.0 if pulse_on else -70.0) + duck_db, speed)
	var level: float = clampf(maxf(maxf(_notice, _near), _erase_boost), 0.0, 1.0)
	_intensity.volume_db = move_toward(_intensity.volume_db, lerpf(-60.0, base, level) + duck_db, speed)
	_hunt.volume_db = move_toward(_hunt.volume_db, (base if _hunting else -70.0) + duck_db, speed)
	ensure.call(_pulse, &"layer_pulse")
	ensure.call(_intensity, &"layer_intensity")
	ensure.call(_hunt, &"layer_hunt")
