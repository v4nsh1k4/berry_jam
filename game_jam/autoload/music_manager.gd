extends Node
## Music: synthesized tracks (MusicSynth) rendered a chunk at a time across
## frames after the first click (no stall), played on a "Music" bus that feeds
## Master. Its own volume and mute live in user://settings.cfg [audio].
##   Base track: menu / ch1 / ch2 / ch3, reveal (once), return / erase after
##   the twist, warm after the repair, ending for the epilogue.
##   Layers: intensity follows the noticed meter and the Crawler's nearness;
##   hunt plays while it hunts. Safe rooms (no Crawler) sit near-silent.
##   Stingers: a new room, danger, relief on a return, cutscene cues.
##   Bed (Stage 7): soft piano (MusicSynth4 piano_bed) under Chapters 1-3
##   rooms, played by MusicFiles in place of the ch1-ch3 tracks with
##   bg_track.wav's level / dip / drop / return (MusicFiles.USE_BG_TRACK
##   switches back to the file). Menu: a soft piano piece (MusicSynth4).
##   Ending: the team's ending.wav once over the synthesized ending for the
##   epilogue; then the End Card's own piano piece (piano_end).
##   Volume / mute / focus: the MusicSettings child (split out in Stage 7).
##   All of it ducks for cutscenes and scares (and a scare's build-up), drops
##   out before a lunge, mutes on focus loss, and is back within ~2 s.

const BUS: StringName = &"Music"
## Stage 6b: every music level +6 dB (and the slider default +3 dB): it was
## too quiet. Was -10 / -20.
const BASE_DB: float = -4.0
const SAFE_DB: float = -14.0
## Stingers keep their old level (BASE_DB + 2 before Stage 6b).
const STING_DB: float = -8.0
## Render order: the menu first (ready right after the first click), then
## the piano bed. The ch1-ch3 tracks and the Stage 5 bed are never rendered:
## the bed (piano or bg_track) covers those rooms.
const PRIORITY: Array[StringName] = [&"menu", &"piano_bed", &"layer_pulse", &"layer_intensity", &"layer_hunt",
	&"reveal", &"return", &"erase", &"warm", &"ending", &"piano_end"]
const BED_UNDER: Array[StringName] = [&"ch1", &"ch2", &"ch3"]
const CUES: Dictionary = {&"sting_descent": &"danger", &"sting_heart": &"danger", &"repair": &"relief", &"flashback": &"discover"}

var music_volume: float:
	get:
		return _settings.volume
var music_muted: bool:
	get:
		return _settings.muted

var _renderer: MusicRenderer = MusicRenderer.new()
var _started: bool = false
var _want: StringName = &""
var _playing: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _settings: MusicSettings = MusicSettings.new()
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
	_sting = _make_player()
	add_child(_files)
	_files.setup(BUS)
	add_child(_settings)
	_settings.setup(BUS)
	# Stage 7: rendering starts at boot (CPU only, a chunk per frame), so the
	# menu's piano is ready by the first click; playback waits for the click.
	_renderer.queue = PRIORITY.duplicate()
	if MusicFiles.bg_exists():
		# bg_track is the bed: the piano bed isn't needed.
		_renderer.queue.erase(&"piano_bed")
	EventBus.game_started.connect(start)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.returned_to_menu.connect(func() -> void: _choose(&"menu"); _files.stop_all())
	EventBus.sfx_played.connect(_files.on_sfx)
	EventBus.reveal_started.connect(_choose.bind(&"reveal"))
	EventBus.twist_revealed.connect(_choose.bind(&"return"))
	EventBus.comic_repaired.connect(func() -> void: _choose(&"warm"); stinger(&"relief"))
	# The End Card's own piece once the epilogue (and ending.wav) is over.
	EventBus.epilogue_finished.connect(_choose.bind(&"piano_end"))
	# Stage 6b: ducks are softer (-6 dB at most) and short; only the cellar
	# build and the reveal's silent beat still go near-silent.
	EventBus.crawler_telegraph.connect(duck.bind(0.5, 0.7))
	EventBus.player_noticed.connect(stinger.bind(&"danger"))
	EventBus.bubble_returned.connect(func(_b: BubbleData, _p: Vector2) -> void: stinger(&"relief"))
	EventBus.cutscene_started.connect(func(_id: StringName) -> void: duck(0.5, 999.0))
	EventBus.cutscene_finished.connect(func(_id: StringName) -> void: duck(0.0, 0.0))
	EventBus.scare.connect(func(_k: StringName, _i: float) -> void: duck(0.5, 0.8))
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
		_sting.volume_db = STING_DB
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
	_renderer.step()
	if not _started:
		return
	if not _stinger_jobs.is_empty() and _renderer.streams.has(&"menu"):
		var id: StringName = _stinger_jobs.keys()[0]
		_stingers[id] = (_stinger_jobs[id] as Callable).call()
		_stinger_jobs.erase(id)
	if not _files.has_bg() and _renderer.streams.has(&"piano_bed"):
		_files.set_piano_bed(_renderer.streams[&"piano_bed"])
	# A chapter room never keeps the previous track while the bed renders.
	if _want != _playing and (_renderer.streams.has(_want) or _files.holds(_want) or _want in BED_UNDER):
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
	_files.update(delta, bed_on, duck_db, _duck >= 0.9)


func _switch(track: StringName) -> void:
	_playing = track
	_active = 1 - _active
	var p: AudioStreamPlayer = _players[_active]
	p.stream = null if _files.holds(track) or track in BED_UNDER else _renderer.streams.get(track)
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
	_settings.set_volume(value)


func set_music_muted(value: bool) -> void:
	_settings.set_muted(value)
