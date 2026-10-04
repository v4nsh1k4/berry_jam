extends Node
## Music: synthesized tracks (MusicSynth) rendered a chunk at a time across
## frames after the first click (no stall), played on a "Music" bus that feeds
## Master. Its own volume and mute live in user://settings.cfg [audio].
##   Base track by situation: menu / ch1 / ch2 / ch3, reveal (once), warm after
##   the twist and through the repair, ending for the epilogue.
##   Layers: intensity follows the noticed meter and the Crawler's nearness;
##   hunt plays while it hunts. Safe rooms (no Crawler) sit near-silent.
##   Stingers: a new room, danger, relief on a return, cutscene cues.
##   Ducks under cutscenes and scares, drops out before a lunge, and mutes
##   when the window loses focus.

const SETTINGS_PATH: String = "user://settings.cfg"
const BUS: StringName = &"Music"
const BASE_DB: float = -10.0
const SAFE_DB: float = -20.0
const PRIORITY: Array[StringName] = [&"menu", &"ch1", &"ch2", &"ch3", &"layer_intensity", &"layer_hunt", &"warm", &"reveal", &"ending"]

var music_volume: float = 0.6
var music_muted: bool = false

var _renderer: MusicRenderer = MusicRenderer.new()
var _started: bool = false
var _want: StringName = &""
var _playing: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _intensity: AudioStreamPlayer
var _hunt: AudioStreamPlayer
var _sting: AudioStreamPlayer
var _stingers: Dictionary = {}
var _stinger_jobs: Dictionary = {}
var _notice: float = 0.0
var _near: float = 0.0
var _hunting: bool = false
var _safe: bool = false
var _duck: float = 0.0
var _duck_left: float = 0.0
var _visited: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, BUS)
		AudioServer.set_bus_send(index, &"Master")
	for i in 2:
		_players.append(_make_player())
	_intensity = _make_player()
	_hunt = _make_player()
	_sting = _make_player()
	_load_settings()
	EventBus.game_started.connect(start)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(_choose.bind(&"menu"))
	EventBus.reveal_started.connect(_choose.bind(&"reveal"))
	EventBus.twist_revealed.connect(_choose.bind(&"warm"))
	EventBus.notice_changed.connect(func(v: float) -> void: _notice = v)
	EventBus.crawler_proximity.connect(func(v: float, _m: bool) -> void: _near = v)
	EventBus.crawler_state_changed.connect(_on_crawler_state)
	EventBus.crawler_telegraph.connect(duck.bind(1.0, 0.7))
	EventBus.player_noticed.connect(stinger.bind(&"danger"))
	EventBus.bubble_returned.connect(func(_b: BubbleData, _p: Vector2) -> void: stinger(&"relief"))
	EventBus.cutscene_started.connect(func(_id: StringName) -> void: duck(0.6, 999.0))
	EventBus.cutscene_finished.connect(func(_id: StringName) -> void: duck(0.0, 0.0))
	EventBus.scare.connect(func(_k: StringName, _i: float) -> void: duck(1.0, 1.4))
	EventBus.music_cue.connect(_on_cue)


func _make_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = BUS
	p.volume_db = -80.0
	add_child(p)
	return p


func start() -> void:
	if _started:
		return
	_started = true
	# Stingers are built one per frame once the first track is ready.
	_stinger_jobs = {
		&"soft": _short.bind([[0.0, 45], [0.0, 88]], 0.16),
		&"discover": _short.bind([[0.0, 81], [0.18, 76]], 0.10),
		&"relief": _short.bind([[0.0, 69], [0.06, 73], [0.12, 76]], 0.12),
		&"danger": SfxSynth2.sting,
	}
	_renderer.queue = PRIORITY.duplicate()
	if _want == &"":
		_want = &"menu"


## Short music-box stingers, rendered at once.
func _short(notes: Array, amp: float) -> AudioStreamWAV:
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(1.6 * MusicSynth.RATE))
	for n in notes:
		MusicSynth._pluck(buf, 0, buf.size(), n[0], MusicSynth.hz(n[1]), amp, 0.8, true)
	return SfxSynth._to_wav(buf)


func _on_frame_changed(data: FrameData) -> void:
	_safe = data.crawler_spawn == Vector2.INF
	_hunting = false
	if data.epilogue:
		_choose(&"ending")
	elif GameState.twist_revealed:
		_choose(&"warm")
	elif GameState.current_chapter != null and MusicSynth.TRACKS.has(GameState.current_chapter.id):
		_choose(GameState.current_chapter.id)
	if not _visited.has(data.id):
		if not _visited.is_empty():
			stinger(&"discover")
		_visited[data.id] = true


func _on_crawler_state(state: StringName) -> void:
	_hunting = state in [&"HUNTING", &"TELEGRAPH", &"LUNGE"]


func _on_cue(cue: StringName) -> void:
	match cue:
		&"sting_descent", &"sting_heart":
			stinger(&"danger")
		&"repair":
			stinger(&"relief")
		&"flashback":
			stinger(&"discover")
		_:
			stinger(&"soft")


func stinger(id: StringName) -> void:
	if _started and _stingers.has(id):
		_sting.stream = _stingers[id]
		_sting.volume_db = BASE_DB + 2.0
		_sting.play()


## Lowers the music by `amount` (0..1, 1 = silent) for `seconds`.
func duck(amount: float, seconds: float) -> void:
	_duck = amount
	_duck_left = seconds


func _choose(track: StringName) -> void:
	_want = track
	_renderer.prioritise(track)


func _process(delta: float) -> void:
	if not _started:
		return
	_renderer.step()
	if not _stinger_jobs.is_empty() and _renderer.streams.has(&"menu"):
		var id: StringName = _stinger_jobs.keys()[0]
		_stingers[id] = (_stinger_jobs[id] as Callable).call()
		_stinger_jobs.erase(id)
	if _want != _playing and _renderer.streams.has(_want):
		_switch(_want)
	if _duck_left > 0.0:
		_duck_left -= delta
		if _duck_left <= 0.0:
			_duck = 0.0
	var duck_db: float = linear_to_db(maxf(1.0 - _duck, 0.0001))
	var base: float = (SAFE_DB if _safe and _playing.begins_with("ch") else BASE_DB) + duck_db
	var speed: float = delta * 30.0
	for i in _players.size():
		var target: float = base if i == _active else -80.0
		_players[i].volume_db = move_toward(_players[i].volume_db, target, delta * (40.0 if i == _active else 20.0))
	var level: float = clampf(maxf(_notice, _near), 0.0, 1.0)
	_intensity.volume_db = move_toward(_intensity.volume_db, lerpf(-60.0, BASE_DB, level) + duck_db, speed)
	_hunt.volume_db = move_toward(_hunt.volume_db, (BASE_DB if _hunting else -70.0) + duck_db, speed)
	_ensure_layer(_intensity, &"layer_intensity")
	_ensure_layer(_hunt, &"layer_hunt")


func _switch(track: StringName) -> void:
	_playing = track
	_active = 1 - _active
	var p: AudioStreamPlayer = _players[_active]
	p.stream = _renderer.streams[track]
	p.volume_db = -40.0
	p.play()


func _ensure_layer(p: AudioStreamPlayer, track: StringName) -> void:
	if not p.playing and _renderer.streams.has(track):
		p.stream = _renderer.streams[track]
		p.play()


func is_ready(track: StringName) -> bool:
	return _renderer.streams.has(track)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save_settings()


func set_music_muted(value: bool) -> void:
	music_muted = value
	_apply()
	_save_settings()


func _apply(focus_lost: bool = false) -> void:
	var index: int = AudioServer.get_bus_index(BUS)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(index, music_muted or focus_lost)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_apply(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply(false)


func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_volume = float(config.get_value("audio", "music_volume", music_volume))
		music_muted = bool(config.get_value("audio", "music_muted", music_muted))
	_apply()


func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "music_muted", music_muted)
	config.save(SETTINGS_PATH)
