class_name MusicRenderer
extends RefCounted
## Turns MusicSynth tracks into looping AudioStreamWAVs a chunk at a time, so
## no frame stalls: render the samples, fold the loop seam, then encode to
## 16-bit, all within a small per-call time budget. MusicManager calls
## `step()` every frame and reads finished streams from `streams`.

const BUDGET_MS: int = 4
const CHUNK: int = 2048

var streams: Dictionary = {}
var queue: Array[StringName] = []

var _job: StringName = &""
var _buf: PackedFloat32Array
var _bytes: PackedByteArray
var _pos: int = 0
var _encoding: bool = false


## Render this track next.
func prioritise(track: StringName) -> void:
	if queue.has(track):
		queue.erase(track)
		queue.push_front(track)


func step() -> void:
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < BUDGET_MS:
		if _job == &"":
			if queue.is_empty():
				return
			_job = queue.pop_front()
			if streams.has(_job):
				_job = &""
				continue
			_buf = PackedFloat32Array()
			_buf.resize(MusicSynth.total_samples(_job))
			_pos = 0
		if _encoding:
			var stop: int = mini(_pos + CHUNK * 4, _buf.size())
			for i in range(_pos, stop):
				_bytes.encode_s16(i * 2, int(clampf(_buf[i], -1.0, 1.0) * 32767.0))
			_pos = stop
			if _pos >= _buf.size():
				_finish()
				return
			continue
		var end: int = mini(_pos + CHUNK, _buf.size())
		MusicSynth.render(_job, _buf, _pos, end)
		_pos = end
		if _pos >= _buf.size():
			_buf = MusicSynth.fold_loop(_job, _buf)
			_bytes = PackedByteArray()
			_bytes.resize(_buf.size() * 2)
			_pos = 0
			_encoding = true


func _finish() -> void:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MusicSynth.RATE
	wav.data = _bytes
	if MusicSynth.loops(_job):
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = _buf.size()
	streams[_job] = wav
	_job = &""
	_encoding = false
