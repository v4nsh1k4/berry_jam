class_name UiTheme
extends RefCounted
## Comic-panel look for menus: white boxes, thick ink borders, bold text.

const BUTTON_FONT_SIZE: int = 26

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.set_stylebox("normal", "Button", _box(InkDraw.WHITE, 4))
	_theme.set_stylebox("hover", "Button", _box(InkDraw.PAPER, 6))
	_theme.set_stylebox("pressed", "Button", _box(InkDraw.INK, 6))
	_theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, 7, Color(0.06, 0.05, 0.07, 1.0), 10))
	_theme.set_stylebox("disabled", "Button", _box(Color(0.85, 0.85, 0.85), 3))
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(state, "Button", InkDraw.INK)
	_theme.set_color("font_pressed_color", "Button", InkDraw.WHITE)
	_theme.set_font_size("font_size", "Button", BUTTON_FONT_SIZE)
	_theme.set_color("font_color", "Label", InkDraw.INK)
	_theme.set_font_size("font_size", "Label", 20)
	_theme.set_stylebox("panel", "PanelContainer", _box(InkDraw.PAPER, 6, InkDraw.INK, 24))
	_theme.set_stylebox("slider", "HSlider", _box(InkDraw.WHITE, 3, InkDraw.INK, 4))
	_theme.set_stylebox("grabber_area", "HSlider", _box(InkDraw.INK, 3, InkDraw.INK, 4))
	_theme.set_stylebox("grabber_area_highlight", "HSlider", _box(InkDraw.INK, 3, InkDraw.INK, 4))
	return _theme


static func _box(fill: Color, border: int, border_color: Color = InkDraw.INK, margin: int = 14) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_border_width_all(border)
	box.border_color = border_color
	box.set_content_margin_all(margin)
	box.content_margin_left = margin + 10
	box.content_margin_right = margin + 10
	box.shadow_color = Color(InkDraw.INK, 0.9) if fill.a > 0.0 else Color.TRANSPARENT
	box.shadow_offset = Vector2(5, 5)
	box.shadow_size = 0 if fill.a == 0.0 else 1
	return box


## A full-screen Control with the theme, ready for menu content.
static func make_screen(parent: Control) -> void:
	parent.theme = get_theme()
	parent.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.mouse_filter = Control.MOUSE_FILTER_STOP


static func make_button(text: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 0)
	button.pressed.connect(on_pressed)
	button.pressed.connect(AudioManager.play_ui_click)
	return button


static func make_label(text: String, font_size: int = 20, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	return label
