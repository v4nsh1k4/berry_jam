extends Node
## Music: synthesized tracks (MusicSynth) rendered a chunk at a time across
## frames after the first click (no stall), played on a "Music" bus that feeds
## Master. Its own volume and mute live in user://settings.cfg [audio].
##   Base track: menu / ch1 / ch2 / ch3, reveal (once), return / erase after
##   the twist, warm after the repair, ending for the epilogue.
##   Layers: intensity follows the noticed meter and the Crawler's nearness;
##   hunt plays while it hunts. Safe rooms (no Crawler) sit near-silent.
##   Stingers: a new room, danger, relief on a return, cutscene cues.
##   Bed: the team's bg_track.wav under Chapters 1-3 rooms (MusicFiles), in
##   place of the ch1-ch3 tracks; the synthesized bed if the file is missing.
##   Menu: a quiet melancholy layer (MusicSynth3) over the menu track.
##   Ending: the team's ending.wav once, then the synthesized ending, quiet.
##   All of it ducks for cutscenes and scares (and a scare's build-up), drops
##   out before a lunge, mutes on focus loss, and is back within ~2 s.

const SETTINGS_PATH: String = "user://settings.cfg"
const BUS: StringName = &"Music"
const BASE_DB: float = -10.0
const SAFE_DB: float = -20.0
const PRIORITY: Array[StringName] = [&"menu", &"menu_sad", &"ch1", &"bed", &"ch2", &"layer_pulse", &"layer_intensity", &"layer_hunt", &"ch3",
	&"reveal", &"return", &"erase", &"warm", &"ending"]
const BED_UNDER: Array[StringName] = [&"ch1", &"ch2", &"ch3"]
const BED_DB: float = -14.0
## The menu's melancholy layer: ~9 dB under the menu track.
const SAD_DB: float = -19.0
const CUES: Dictionary = {&"sting_descent": &"danger", &"sting_heart": &"danger", &"repair": &"relief", &"flashback": &"discover"}

var music_volume: float = 0.6
var music_muted: bool = false

var _renderer: MusicRenderer = MusicRenderer.new()
var _started: bool = false
var _want: StringName = &""
var _playing: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _bed: AudioStreamPlayer
var _sad: AudioStreamPlayer
var _files: MusicFiles = MusicFiles.new()
var _layers: MusicLayers = MusicLayers.new()
var _sting: AudioStreamPlayer
var _stingers: Dictionary = {}
var _stinger_jobs: Dictionary = {}
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
	add_child(_layers)
	_layers.setup(_make_player)
	_bed = _make_player()
	_sad = _make_player()
	_sting = _make_player()
	add_child(_files)
	_files.setup(BUS)
	_load_settings()
	EventBus.game_started.connect(start)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(func() -> void: _choose(&"menu"); _files.stop_all())
	EventBus.sfx_played.connect(_files.on_sfx)
	EventBus.reveal_started.connect(_choose.bind(&"reveal"))
	EventBus.twist_revealed.connect(_choose.bind(&"return"))
	EventBus.comic_repaired.connect(func() -> void: _choose(&"warm"); stinger(&"relief"))
	EventBus.crawler_telegraph.connect(duck.bind(1.0, 0.7))
	EventBus.player_noticed.connect(stinger.bind(&"danger"))
	EventBus.bubble_returned.connect(func(_b: BubbleData, _p: Vector2) -> void: stinger(&"relief"))
	EventBus.cutscene_started.connect(func(_id: StringName) -> void: duck(0.6, 999.0))
	EventBus.cutscene_finished.connect(func(_id: StringName) -> void: duck(0.0, 0.0))
	EventBus.scare.connect(func(_k: StringName, _i: float) -> void: duck(1.0, 1.4))
	EventBus.scare_building.connect(func(_k: StringName, seconds: float) -> void: duck(0.97 if seconds > 0.0 else 0.0, seconds))
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
	_stinger_jobs = MusicSynth2.stinger_jobs()
	_renderer.queue = PRIORITY.duplicate()
	if MusicFiles.bg_exists():
		# bg_track covers these: never render them.
		_renderer.queue = _renderer.queue.filter(func(t: StringName) -> bool: return not (t in BED_UNDER or t == &"bed"))
	if _want == &"":
		_want = &"menu"


func _on_frame_changed(data: FrameData) -> void:
	_safe = data.crawler_spawn == Vector2.INF
	if data.epilogue:
		_choose(&"ending")
		_files.play_ending()
	elif GameState.has_flag(&"comic_repaired"):
		_choose(&"warm")
	elif data.id == &"ch3_heart_return":
		_choose(&"erase")
	elif GameState.twist_revealed:
		_choose(&"return")
	elif GameState.current_chapter != null and MusicSynth.TRACKS.has(GameState.current_chapter.id):
		_choose(GameState.current_chapter.id)
	if not _visited.has(data.id):
		if not _visited.is_empty():
			stinger(&"discover")
		_visited[data.id] = true


func _on_cue(cue: StringName) -> void:
	stinger(CUES.get(cue, &"soft"))


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
	_files.load_step()
	if not _started:
		return
	_renderer.step()
	if not _stinger_jobs.is_empty() and _renderer.streams.has(&"menu"):
		var id: StringName = _stinger_jobs.keys()[0]
		_stingers[id] = (_stinger_jobs[id] as Callable).call()
		_stinger_jobs.erase(id)
	if _want != _playing and (_renderer.streams.has(_want) or _files.holds(_want)):
		_switch(_want)
	if _duck_left > 0.0:
		_duck_left -= delta
		if _duck_left <= 0.0:
			_duck = 0.0
	var duck_db: float = linear_to_db(maxf(1.0 - _duck, 0.0001))
	var base: float = (SAFE_DB if _safe and _playing.begins_with("ch") else BASE_DB) + duck_db
	base -= 6.0 if _playing == &"ending" else 0.0
	for i in _players.size():
		var target: float = base if i == _active and not _files.holds(_playing) else -80.0
		_players[i].volume_db = move_toward(_players[i].volume_db, target, delta * (40.0 if target > -80.0 else 30.0))
	_layers.update(delta, BASE_DB, duck_db, _ensure_layer)
	var bed_on: bool = _want in BED_UNDER and GameState.is_playing
	_files.update(delta, bed_on, duck_db, _duck >= 0.6)
	var bed_db: float = BED_DB + duck_db if bed_on and not _files.has_bg() else -80.0
	_bed.volume_db = move_toward(_bed.volume_db, bed_db, delta * (140.0 if bed_db < _bed.volume_db else 40.0))
	_ensure_layer(_bed, &"bed")
	_sad.volume_db = move_toward(_sad.volume_db, SAD_DB + duck_db if _playing == &"menu" else -80.0, delta * 20.0)
	_ensure_layer(_sad, &"menu_sad")


func _switch(track: StringName) -> void:
	_playing = track
	_active = 1 - _active
	var p: AudioStreamPlayer = _players[_active]
	p.stream = _renderer.streams.get(track)
	p.volume_db = -40.0
	if p.stream != null:
		p.play()
	else:
		p.stop()


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
	var loaded: Array = MusicSynth2.load_setting(SETTINGS_PATH, music_volume, music_muted)
	music_volume = loaded[0]
	music_muted = loaded[1]
	_apply()


func _save_settings() -> void:
	MusicSynth2.save_setting(SETTINGS_PATH, music_volume, music_muted)
