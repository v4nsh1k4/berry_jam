extends Node2D
## The goal line at the top of the screen, above the panel. After the reveal
## it reads "Give back what you took." and stays (across saves and restarts)
## until the first word goes home, then fades. Anything can set it through
## EventBus.goal_changed ("" hides it).

const FLAG_DONE: StringName = &"goal_first_return"
const FONT_SIZE: int = 18

var _text: String = ""
var _alpha: float = 0.0
var _target: float = 0.0


func _ready() -> void:
	EventBus.goal_changed.connect(_on_goal_changed)
	EventBus.frame_changed.connect(_on_frame_changed)
	EventBus.bubble_returned.connect(_on_bubble_returned)
	EventBus.returned_to_menu.connect(_on_goal_changed.bind(""))
	EventBus.game_reset.connect(_on_goal_changed.bind(""))


func _on_goal_changed(text: String) -> void:
	if text != "":
		_text = text
	_target = 1.0 if text != "" else 0.0


## Loaded saves and restarts land in a frame: show the goal if it still holds.
func _on_frame_changed(_data: FrameData) -> void:
	if GameState.twist_revealed and not GameState.has_flag(FLAG_DONE) and not GameState.has_flag(&"comic_repaired"):
		_on_goal_changed("Give back what you took.")


func _on_bubble_returned(_bubble: BubbleData, _pos: Vector2) -> void:
	if not GameState.has_flag(FLAG_DONE):
		GameState.set_flag(FLAG_DONE)
		_on_goal_changed("")


func _process(delta: float) -> void:
	var speed: float = 2.0 if _target > _alpha else 0.5
	var next: float = move_toward(_alpha, _target, delta * speed)
	if next != _alpha:
		_alpha = next
		queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01 or _text == "":
		return
	var font: Font = ThemeDB.fallback_font
	var w: float = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var x: float = 640.0 - w * 0.5
	draw_rect(Rect2(x - 14, 4, w + 28, 26), Color(InkDraw.PAPER, 0.92 * _alpha))
	draw_rect(Rect2(x - 14, 4, 4, 26), Color(InkDraw.RED, _alpha))
	draw_string(font, Vector2(x, 23), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(InkDraw.INK, _alpha))
