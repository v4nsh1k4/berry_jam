extends Node2D
## Small caption under whatever the player can interact with.

const FONT_SIZE: int = 16

var _text: String = ""


func _ready() -> void:
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)


func _on_prompt_changed(text: String, screen_pos: Vector2) -> void:
	_text = text
	position = screen_pos
	queue_redraw()


func _draw() -> void:
	if _text == "":
		return
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var box: Rect2 = Rect2(Vector2(-text_size.x * 0.5 - 10, 8), text_size + Vector2(20, 10))
	InkDraw.rect(self, box, 2.5, 5, InkDraw.WHITE)
	# The key ("E", "Hold E") is the red accent; the rest stays ink.
	var split: int = _text.find(":")
	var key: String = _text.substr(0, split + 1) if split > 0 else ""
	var pos: Vector2 = box.position + Vector2(10, 5 + font.get_ascent(FONT_SIZE))
	draw_string(font, pos, key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, InkDraw.RED)
	var key_width: float = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, pos + Vector2(key_width, 0), _text.substr(key.length()), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, InkDraw.INK)
