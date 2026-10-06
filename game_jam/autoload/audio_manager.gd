extends Node
## Procedural sound. Nothing plays until the first "Click to start" (browsers
## block audio before a user gesture). Listens to EventBus for game sounds.
## Master volume and mute live on the Master bus and persist in user://.

const SETTINGS_PATH: String = "user://settings.cfg"
const VOICES: int = 6

var master_volume: float = 0.7
var muted: bool = false

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _drone: AudioStreamPlayer
var _rumble: AudioStreamPlayer
var _started: bool = false
# Crawler dread: heartbeat speeds up with the noticed meter / its nearness.
var _notice: float = 0.0
var _near: float = 0.0
var _beat_left: float = 0.0
var _skitter_left: float = 0.0
var _whisper_left: float = 3.0
var _pending: Dictionary = {}
# A held breath before a lunge: after the growl, everything drops out.
var _hush_in: float = -1.0
var _hush: float = 0.0
var _cry: CryBank = CryBank.new()
## The last sound asked for (tests check door creaks with it).
var last_played: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	EventBus.game_started.connect(start)
	EventBus.footstep.connect(_on_footstep)
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.ability_failed.connect(_on_ability_failed)
	EventBus.player_caught.connect(play.bind(&"splat", -6.0))
	EventBus.notice_changed.connect(_on_notice_changed)
	EventBus.crawler_proximity.connect(_on_crawler_proximity)
	EventBus.crawler_telegraph.connect(_on_telegraph)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.bubble_returned.connect(_on_bubble_returned)
	EventBus.hiding_spot_erased.connect(play.bind(&"scribble", -6.0, 0.1).unbind(1))
	EventBus.hand_erase.connect(play.bind(&"rub", -4.0, 0.1).unbind(1))
	EventBus.reveal_started.connect(_on_frame_changed.bind(null))
	EventBus.scare_building.connect(func(_k: StringName, seconds: float) -> void: hush(seconds))


func start() -> void:
	if _started:
		return
	_started = true
	_streams = {
		&"step": SfxSynth.footstep(), &"steal": SfxSynth.steal(),
		&"thud": SfxSynth.thud(), &"chime": SfxSynth.chime(), &"click": SfxSynth.click(),
		&"splat": SfxSynth.splat(), &"heartbeat": SfxSynth.heartbeat(), &"skitter": SfxSynth.skitter(),
		&"growl": SfxSynth3.growl(), &"scribble": SfxSynth.scribble(), &"rub": SfxSynth.rub(),
		&"slam": SfxSynth.slam(),
	}
	# Later sounds are built one per frame so the first click doesn't stall
	# (a job object's next() returns null until it is done: again next frame).
	_pending = {
		&"swoosh": SfxSynth2.swoosh, &"nib": SfxSynth2.nib, &"whisper": SfxSynth2.whisper,
		&"sting": SfxSynth2.sting, &"scare_hit": SfxSynth2.scare_hit, &"scare_low": SfxSynth2.scare_low,
		&"door_creak_0": SfxSynth2.door_creak.bind(11), &"door_creak_1": SfxSynth2.door_creak.bind(29),
		&"door_creak_2": SfxSynth2.door_creak.bind(47), &"groan": SfxSynth3.Groan.new(3),
		&"moan": SfxSynth3.moan,
	}
	var cry_player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(cry_player)
	_cry.start(cry_player)
	for i in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_drone = AudioStreamPlayer.new()
	_drone.stream = SfxSynth.drone()
	_drone.volume_db = -20.0
	add_child(_drone)
	_drone.play()
	_rumble = AudioStreamPlayer.new()
	_rumble.stream = SfxSynth.rumble()
	_rumble.volume_db = -60.0
	add_child(_rumble)
	_rumble.play()


func _on_notice_changed(amount: float) -> void:
	_notice = amount


func _on_crawler_proximity(amount: float, moving: bool) -> void:
	_near = amount
	if moving and amount > 0.05 and _skitter_left <= 0.0:
		_skitter_left = 0.25
		play(&"skitter", lerpf(-24.0, -8.0, amount), 0.2)
		if randf() < 0.3:
			play(&"nib", lerpf(-26.0, -12.0, amount), 0.15)


func _on_telegraph() -> void:
	play(&"growl", -4.0, 0.05)
	_hush_in = 0.3


func _on_frame_changed(_data: FrameData) -> void:
	_notice = 0.0
	_near = 0.0


func _process(delta: float) -> void:
	if not _started:
		return
	if not _pending.is_empty():
		var id: StringName = _pending.keys()[0]
		var job: Variant = _pending[id]
		var built: AudioStream = (job as Callable).call() if job is Callable else job.next()
		if built != null:
			_streams[id] = built
			_pending.erase(id)
	_cry.step()
	_skitter_left -= delta
	if _hush_in > 0.0:
		_hush_in -= delta
		if _hush_in <= 0.0:
			_hush = 0.4
	if _hush > 0.0:
		_hush -= delta
		_rumble.volume_db = -60.0
		_drone.volume_db = -60.0
		return
	_drone.volume_db = move_toward(_drone.volume_db, -20.0, delta * 60.0)
	_whisper_left -= delta
	if _near > 0.5 and _whisper_left <= 0.0:
		_whisper_left = randf_range(3.5, 6.5)
		play(&"whisper", lerpf(-20.0, -9.0, _near), 0.12)
	_rumble.volume_db = lerpf(_rumble.volume_db, linear_to_db(maxf(_near * 0.9, 0.0001)), minf(delta * 4.0, 1.0))
	var dread: float = maxf(_notice, _near)
	_beat_left -= delta
	if dread > 0.08 and _beat_left <= 0.0:
		_beat_left = lerpf(1.15, 0.36, dread)
		play(&"heartbeat", lerpf(-22.0, -5.0, dread), 0.0)
		EventBus.heartbeat.emit(dread)


func play(sound: StringName, volume_db: float = -8.0, pitch_jitter: float = 0.06) -> void:
	if not _started or not _streams.has(sound):
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = _streams[sound]
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()
	last_played = sound
	EventBus.sfx_played.emit(sound, volume_db)


## Doors, exits and secret doors opening: one of three wooden creaks, pitch
## jittered, so no two sound alike.
func play_door_creak(volume_db: float = -5.0) -> void:
	play(StringName("door_creak_%d" % randi_range(0, 2)), volume_db, 0.08)


## The team's recorded cry (CryBank.play): raw / low / thin, once per
## `once_id` per run.
func play_cry(variant: StringName, volume_db: float = -10.0, fade_in: float = 0.0, once_id: StringName = &"") -> void:
	if _started and _cry.play(variant, volume_db, fade_in, once_id):
		last_played = StringName("cry_%s" % variant)


func stop_cry() -> void:
	_cry.stop()


## Drops the drone, rumble and heartbeat out for `seconds` (a held breath).
func hush(seconds: float) -> void:
	_hush = maxf(_hush, seconds)


func _on_footstep(loud: bool) -> void:
	play(&"step", -10.0 if loud else -16.0, 0.15)


func play_ui_click() -> void:
	play(&"click", -10.0)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save_settings()


func set_muted(value: bool) -> void:
	muted = value
	_apply()
	_save_settings()


func _apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, muted)


func _on_bubble_stolen(_bubble: BubbleData, _from: Vector2) -> void:
	play(&"steal", -7.0)


## Softer and lower than the "word worked" chime: a warm two-note chime. The
## last word gets a slower, deeper one.
func _on_bubble_returned(bubble: BubbleData, _pos: Vector2) -> void:
	if not _started:
		return
	var low: float = 0.5 if bubble.story_final else 0.75
	play(&"chime", -8.0, 0.0)
	_voices[(_next_voice + VOICES - 1) % VOICES].pitch_scale = low
	await get_tree().create_timer(0.16).timeout
	play(&"chime", -10.0, 0.0)
	_voices[(_next_voice + VOICES - 1) % VOICES].pitch_scale = low * 1.26


func _on_ability_used(_bubble: BubbleData, _target_id: StringName) -> void:
	play(&"chime", -10.0)


func _on_ability_failed(_bubble: BubbleData, _target_id: StringName) -> void:
	play(&"thud", -5.0)


func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		master_volume = float(config.get_value("audio", "master_volume", master_volume))
		muted = bool(config.get_value("audio", "muted", muted))
	_apply()


func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "muted", muted)
	config.save(SETTINGS_PATH)
