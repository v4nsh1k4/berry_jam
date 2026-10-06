class_name MusicFiles
extends Node
## The team's two music files (Stage 6), played on the Music bus for
## MusicManager (its child; MusicManager decides when, from EventBus events):
##   bg_track.wav  the bed of Chapters 1-3 rooms, in place of the synthesized
##                 ch1/ch2/ch3 tracks and the Stage 5 bed (the build-up layers
##                 still play on top). Two players crossfade at the loop point
##                 (the file starts with 0.21 s of silence and ends ~-36 dB
##                 with a step, so a plain loop would gap and click). It keeps
##                 running across rooms and through ducks, dips ~3 dB for
##                 ~0.5 s under a loud sound effect, drops out (~0.3 s) for
##                 cutscenes, scares, the reveal and pre-lunge silences and is
##                 back within ~2 s. Off (and stopped) everywhere else.
##   ending.wav    a ~6 s sting, once, as the epilogue begins (after the
##                 previous track fades); then the synthesized ending carries on.
## Both are loaded a few frames after start-up, one per frame (never on the
## first click). A missing file leaves the synthesized music in its place.
## Stage 7: the bed is soft piano now (MusicSynth4's piano_bed, handed over
## by MusicManager once rendered via set_piano_bed); it loops by itself and
## gets the same level, dip, drop and return as bg_track did. bg_track.wav
## was removed before submission (unused); USE_BG_TRACK only matters if the
## file is put back (a missing file falls back to the piano safely).

## Stage 7: false = the synthesized piano bed under Chapters 1-3; true = the
## team's bg_track.wav again (the only switch needed).
const USE_BG_TRACK: bool = false
const BG_PATH: String = "res://audio/bg_track.wav"
const ENDING_PATH: String = "res://audio/ending.wav"
## bg_track's level: the file is loud (RMS ~-15 dBFS); this keeps it ~8 dB
## under the sound effects.
## Stage 6b: +6 dB (was -17): the music was too quiet.
const BG_DB: float = -11.0
## The piano bed's level: its RMS (~-23 dBFS) lands where bg_track's did
## (RMS ~-15 dBFS at BG_DB -11).
const PIANO_DB: float = -3.0
const ENDING_DB: float = 0.0
const XFADE: float = 2.0
const BG_START: float = 0.21
const DIP_DB: float = 3.0
const DIP_TIME: float = 0.5
## Sounds at least this loud (AudioManager volume_db) dip the bed.
const LOUD_DB: float = -8.0
const OUT_SPEED: float = 160.0
const IN_SPEED: float = 40.0
const ENDING_WAIT: float = 1.0
const LOAD_AT: Array[int] = [8, 16]

enum End { IDLE, WAITING, PLAYING, DONE }

var bg: AudioStream = null
## The bed is MusicSynth4's piano (a looping stream: no crossfade needed).
var piano: bool = false
var ending: AudioStream = null
var level: float = -80.0
var end_state: End = End.IDLE
## Times bg_track has looped (tests).
var loops: int = 0

var _bg: Array[AudioStreamPlayer] = []
var _cur: int = 0
var _time: float = 0.0
var _fading: bool = false
var _dip: float = 0.0
var _idle: float = 0.0
var _frame: int = 0
var _end: AudioStreamPlayer
var _end_time: float = 0.0


func setup(bus: StringName) -> void:
	for i in 3:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = bus
		p.volume_db = -80.0
		add_child(p)
		if i < 2:
			_bg.append(p)
		else:
			_end = p


## True when bg_track is in use and in the project (checked without loading it).
static func bg_exists() -> bool:
	return USE_BG_TRACK and ResourceLoader.exists(BG_PATH)


## The rendered piano bed (MusicManager, once MusicRenderer has it).
func set_piano_bed(stream: AudioStream) -> void:
	bg = stream
	piano = true


## The bed's level when nothing ducks or dips it.
func bed_db() -> float:
	return PIANO_DB if piano else BG_DB


## Called every frame from start-up: loads one file on each of LOAD_AT's frames.
func load_step() -> void:
	_frame += 1
	if _frame == LOAD_AT[0] and USE_BG_TRACK:
		bg = _load(BG_PATH)
	elif _frame == LOAD_AT[1]:
		ending = _load(ENDING_PATH)


func _load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("MusicFiles: %s is missing; the synthesized music plays instead." % path)
		return null
	return load(path) as AudioStream


func has_bg() -> bool:
	return bg != null


## MusicManager's base player stays silent for `track` while a file covers it.
func holds(track: StringName) -> bool:
	if track == &"ending":
		return end_state == End.WAITING or end_state == End.PLAYING
	return bg != null and track in [&"ch1", &"ch2", &"ch3"]


func on_sfx(sound: StringName, volume_db: float) -> void:
	# Footsteps never dip the bed (running steps reach -6 dB since Stage 7):
	# the music would pump on every step.
	if volume_db >= LOUD_DB and sound != &"step":
		_dip = DIP_TIME


## `on`: a Chapter 1-3 room is playing; `duck_db`: MusicManager's duck;
## `drop`: a big moment (cutscene, scare, lunge) takes over fully.
func update(delta: float, on: bool, duck_db: float, drop: bool) -> void:
	_dip = maxf(0.0, _dip - delta)
	_update_ending(delta)
	if bg == null:
		return
	# The SFX dip never stacks on a duck (Stage 6b: -6 dB at most in all).
	var dip: float = DIP_DB * smoothstep(0.0, 0.08, _dip) if _dip > 0.0 and duck_db > -1.0 else 0.0
	var target: float = bed_db() + duck_db - dip if on and not drop else -80.0
	# Big drops fast (~0.3 s), returns within ~2 s, the small dip eased (12 dB/s).
	var speed: float = 12.0
	if target < level - DIP_DB - 0.5:
		speed = OUT_SPEED
	elif target > level + DIP_DB + 0.5:
		speed = IN_SPEED
	level = move_toward(level, target, delta * speed)
	if not on and level <= -79.0:
		_idle += delta
		if _idle > 3.0 and _bg[_cur].playing:
			stop_bg()
		return
	_idle = 0.0
	if piano:
		_update_piano(delta)
		return
	if not _bg[_cur].playing and not _fading:
		_start(_cur, 0.0)
	_time += delta
	# The crossfade ends 0.1 s before the file does (timers drift a little).
	var length: float = bg.get_length() - 0.1
	var x: float = clampf((_time - (length - XFADE)) / XFADE, 0.0, 1.0)
	if x > 0.0 and not _fading:
		_fading = true
		_start(1 - _cur, BG_START)
	if _fading and not _bg[_cur].playing:
		x = 1.0
	_bg[_cur].volume_db = level + linear_to_db(maxf(sqrt(1.0 - x), 0.0001))
	if _fading:
		_bg[1 - _cur].volume_db = level + linear_to_db(maxf(sqrt(x), 0.0001))
	if x >= 1.0:
		_bg[_cur].stop()
		_time = _bg[1 - _cur].get_playback_position() if _bg[1 - _cur].playing else XFADE + BG_START
		_cur = 1 - _cur
		_fading = false
		loops += 1


## The piano bed loops by itself (its seam is folded when it is rendered).
func _update_piano(delta: float) -> void:
	if not _bg[_cur].playing:
		_start(_cur, 0.0)
	_bg[_cur].volume_db = level
	var pos: float = _bg[_cur].get_playback_position()
	if pos + 0.5 < _time:
		loops += 1
	_time = pos if pos > 0.0 else _time + delta


func _start(index: int, from: float) -> void:
	_bg[index].stream = bg
	_bg[index].volume_db = -80.0
	_bg[index].play(from)
	if index == _cur:
		_time = from


func playing_bg() -> bool:
	return _bg[_cur].playing


func stop_bg() -> void:
	for p in _bg:
		p.stop()
	_fading = false
	_time = 0.0
	level = -80.0


## The epilogue begins: once per run, after the previous track fades.
func play_ending() -> void:
	if ending != null and end_state == End.IDLE:
		end_state = End.WAITING
		_end_time = 0.0


func _update_ending(delta: float) -> void:
	if end_state == End.WAITING:
		_end_time += delta
		if _end_time >= ENDING_WAIT:
			_end.stream = ending
			_end.volume_db = ENDING_DB
			_end.play()
			end_state = End.PLAYING
			_end_time = 0.0
	elif end_state == End.PLAYING:
		_end_time += delta
		# A short fade over its last 0.15 s (the file ends loud).
		var left: float = ending.get_length() - _end_time
		_end.volume_db = ENDING_DB + linear_to_db(clampf(left / 0.15, 0.0001, 1.0))
		if left <= 0.0 or not _end.playing:
			_end.stop()
			end_state = End.DONE


## Back to the menu: everything stops; the sting may play again next run.
func stop_all() -> void:
	stop_bg()
	_end.stop()
	end_state = End.IDLE
