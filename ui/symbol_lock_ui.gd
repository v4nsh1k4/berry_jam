extends Control
## Three symbol dials for a symbol_lock. Left/right picks a dial, up/down (or
## clicking a dial's top / bottom half) turns it, Enter / Space / the TRY
## button tries the code, Esc or E steps back. A wrong code gets the usual
## "?"; the right one emits EventBus.symbol_lock_solved and the lock in the
## world resolves itself. The world is paused while the dials are open, so
## nothing can catch the player mid-entry. The title is the lock's caption.

const DIAL_RADIUS: float = 70.0
const DIAL_GAP: float = 190.0
const TRY_RECT: Rect2 = Rect2(-70, 118, 140, 40)

var _lock: InteractableData
var _dials: Array[int] = [0, 0, 0]
var _selected: int = 0
var _solved: bool = false
## Seconds the "?" for a wrong code stays up.
var _wrong: float = 0.0
## Remembers each lock's dial positions between visits.
var _saved: Dictionary = {}


func _ready() -> void:
	UiTheme.make_screen(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.symbol_lock_requested.connect(open)
	EventBus.returned_to_menu.connect(_close)
	hide()


func open(lock: InteractableData) -> void:
	_lock = lock
	_dials.assign(_saved.get(lock.id, [5, 5, 5]))
	_selected = 0
	_solved = false
	_wrong = 0.0
	GameState.modal_open = true
	EventBus.interact_prompt_changed.emit("", Vector2.ZERO)
	get_tree().paused = true
	show()
	queue_redraw()


func _close() -> void:
	if _lock != null:
		_saved[_lock.id] = _dials.duplicate()
	if visible:
		get_tree().paused = false
	hide()
	GameState.modal_open = false


func _dial_center(i: int) -> Vector2:
	return size * 0.5 + Vector2((i - 1) * DIAL_GAP, 10)


func _try_rect() -> Rect2:
	return Rect2(size * 0.5 + TRY_RECT.position, TRY_RECT.size)


func _input(event: InputEvent) -> void:
	if not visible or _solved:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		_close()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_try()
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
		if _try_rect().has_point(click):
			_try()
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
	_wrong = 0.0
	AudioManager.play(&"click")


func _try() -> void:
	var answer: PackedStringArray = _lock.symbols
	for d in 3:
		if d >= answer.size() or SymbolArt.ALL[_dials[d]] != answer[d]:
			_wrong = 1.2
			AudioManager.play(&"thud", -5.0)
			EventBus.player_reaction.emit("?")
			return
	_solved = true
	_saved[_lock.id] = _dials.duplicate()
	EventBus.symbol_lock_solved.emit(_lock.id)
	get_tree().create_timer(0.7, true).timeout.connect(_close)


func _draw() -> void:
	if _lock == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	var tick: int = InkDraw.boil_tick()
	var panel: Rect2 = Rect2(size * 0.5 - Vector2(320, 190), Vector2(640, 400))
	InkDraw.rect(self, panel, 7.0, tick, InkDraw.PAPER)
	var font: Font = ThemeDB.fallback_font
	var title: String = "CLICK!" if _solved else ("?" if _wrong > 0.0 else (_lock.caption if _lock.caption != "" else "THREE SYMBOLS"))
	var w: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	BubbleArt.draw_bold(self, Vector2(size.x * 0.5 - w * 0.5, panel.position.y + 50), title, 30, InkDraw.INK)
	var shake: float = sin(_wrong * 40.0) * 8.0 * _wrong
	for i in 3:
		var c: Vector2 = _dial_center(i) + Vector2(shake, 0)
		var fill: Color = InkDraw.WHITE if i == _selected else InkDraw.PAPER
		InkDraw.ellipse(self, c, Vector2(DIAL_RADIUS, DIAL_RADIUS), 7.0 if i == _selected else 3.5, tick + i, fill)
		SymbolArt.draw(self, StringName(SymbolArt.ALL[_dials[i]]), c, DIAL_RADIUS * 0.5, tick + 10 + i, InkDraw.INK, 4.0)
		InkDraw.polyline(self, PackedVector2Array([c + Vector2(-12, -DIAL_RADIUS - 8), c + Vector2(0, -DIAL_RADIUS - 20), c + Vector2(12, -DIAL_RADIUS - 8)]), 3.0, tick + 20 + i)
		InkDraw.polyline(self, PackedVector2Array([c + Vector2(-12, DIAL_RADIUS + 8), c + Vector2(0, DIAL_RADIUS + 20), c + Vector2(12, DIAL_RADIUS + 8)]), 3.0, tick + 30 + i)
	var button: Rect2 = _try_rect()
	InkDraw.rect(self, button, 4.0, tick + 40, InkDraw.WHITE)
	BubbleArt.draw_bold(self, button.position + Vector2(38, 29), "TRY", 22, InkDraw.INK)
	var hint: String = "A/D pick a dial   W/S or click to turn   Enter: try   E / Esc: step back"
	var hw: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2(size.x * 0.5 - hw * 0.5, panel.end.y - 14), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, InkDraw.INK)


func _process(delta: float) -> void:
	if visible:
		_wrong = maxf(0.0, _wrong - delta)
		queue_redraw()
