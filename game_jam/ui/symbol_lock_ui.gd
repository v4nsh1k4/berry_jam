extends Control
## Three symbol dials for a symbol_lock. Left/right picks a dial, up/down (or
## clicking a dial's top / bottom half) turns it, Esc or E closes. Solving
## emits EventBus.symbol_lock_solved; the door in the world opens itself.

const DIAL_RADIUS: float = 70.0
const DIAL_GAP: float = 190.0

var _lock: InteractableData
var _dials: Array[int] = [0, 0, 0]
var _selected: int = 0
var _solved: bool = false
## Remembers each lock's dial positions between visits.
var _saved: Dictionary = {}


func _ready() -> void:
	UiTheme.make_screen(self)
	EventBus.symbol_lock_requested.connect(open)
	EventBus.returned_to_menu.connect(_close)
	hide()


func open(lock: InteractableData) -> void:
	_lock = lock
	_dials.assign(_saved.get(lock.id, [5, 5, 5]))
	_selected = 0
	_solved = false
	GameState.modal_open = true
	EventBus.interact_prompt_changed.emit("", Vector2.ZERO)
	show()
	queue_redraw()


func _close() -> void:
	if _lock != null:
		_saved[_lock.id] = _dials.duplicate()
	hide()
	GameState.modal_open = false


func _dial_center(i: int) -> Vector2:
	return size * 0.5 + Vector2((i - 1) * DIAL_GAP, 10)


func _input(event: InputEvent) -> void:
	if not visible or _solved:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		_close()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_selected = posmod(_selected - 1, 3)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_selected = posmod(_selected + 1, 3)
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_turn(_selected, 1)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_turn(_selected, -1)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var click: Vector2 = (event as InputEventMouseButton).position
		for i in 3:
			if click.distance_to(_dial_center(i)) < DIAL_RADIUS + 30.0:
				_selected = i
				_turn(i, 1 if click.y < _dial_center(i).y else -1)
	else:
		return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _turn(i: int, step: int) -> void:
	_dials[i] = posmod(_dials[i] + step, SymbolArt.ALL.size())
	AudioManager.play(&"click")
	var answer: PackedStringArray = _lock.symbols
	for d in 3:
		if d >= answer.size() or SymbolArt.ALL[_dials[d]] != answer[d]:
			return
	_solved = true
	_saved[_lock.id] = _dials.duplicate()
	EventBus.symbol_lock_solved.emit(_lock.id)
	get_tree().create_timer(0.7).timeout.connect(_close)


func _draw() -> void:
	if _lock == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	var tick: int = InkDraw.boil_tick()
	var panel: Rect2 = Rect2(size * 0.5 - Vector2(320, 170), Vector2(640, 340))
	InkDraw.rect(self, panel, 7.0, tick, InkDraw.PAPER)
	var font: Font = ThemeDB.fallback_font
	var title: String = "CLICK!" if _solved else "THREE SYMBOLS"
	var w: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	BubbleArt.draw_bold(self, Vector2(size.x * 0.5 - w * 0.5, panel.position.y + 50), title, 30, InkDraw.INK)
	for i in 3:
		var c: Vector2 = _dial_center(i)
		var fill: Color = InkDraw.WHITE if i == _selected else InkDraw.PAPER
		InkDraw.ellipse(self, c, Vector2(DIAL_RADIUS, DIAL_RADIUS), 7.0 if i == _selected else 3.5, tick + i, fill)
		SymbolArt.draw(self, StringName(SymbolArt.ALL[_dials[i]]), c, DIAL_RADIUS * 0.5, tick + 10 + i, InkDraw.INK, 4.0)
		InkDraw.polyline(self, PackedVector2Array([c + Vector2(-12, -DIAL_RADIUS - 8), c + Vector2(0, -DIAL_RADIUS - 20), c + Vector2(12, -DIAL_RADIUS - 8)]), 3.0, tick + 20 + i)
		InkDraw.polyline(self, PackedVector2Array([c + Vector2(-12, DIAL_RADIUS + 8), c + Vector2(0, DIAL_RADIUS + 20), c + Vector2(12, DIAL_RADIUS + 8)]), 3.0, tick + 30 + i)
	var hint: String = "A/D pick a dial   W/S or click to turn   E / Esc to step back"
	var hw: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2(size.x * 0.5 - hw * 0.5, panel.end.y - 18), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, InkDraw.INK)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
