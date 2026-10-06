class_name GrandfatherClock
extends Interactable
## The Clock Room's grandfather clock (kind "clock", revealed_by_light). Its
## face shows three marks under the torch, placed at twelve, four and eight
## o'clock (data.symbols in clockwise order from twelve). While the pendulum
## swings the face shudders and the marks only hold still as it passes the
## middle; WAIT on the pendulum holds them steady. Reading them (lit and
## steady for READ_TIME) resolves it (sets_flag, caption): the answer is
## entered at the dial box on its case, a separate symbol_lock.

const READ_TIME: float = 0.5

## 0..1 how still the face is (1 = pendulum frozen or passing the middle).
var steady: float = 0.0
var _pendulum: Pendulum
var _read: float = 0.0


func setup(interactable: InteractableData) -> void:
	super.setup(interactable)
	_pendulum = Pendulum.new()
	_pendulum.position = Vector2(data.size.x * 0.5, data.size.y * 0.42)
	add_child(_pendulum)


func _process(delta: float) -> void:
	super._process(delta)
	steady = _pendulum.steadiness()
	if resolved or reveal < 0.6 or steady < 0.5:
		return
	_read += delta
	if _read >= READ_TIME:
		resolve()
		if data.caption != "":
			EventBus.caption_requested.emit(data.caption, 4.5)
