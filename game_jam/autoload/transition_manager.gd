extends CanvasLayer
## Comic-style transitions played around a frame swap. `play` covers the
## screen, calls `swap`, then uncovers it, and returns when done.

const SLIDE_TIME: float = 0.38
const SPLASH_TIME: float = 0.42
const HOLD_TIME: float = 0.08

var is_playing: bool = false

var _sheet: PageSheet
var _ink: ColorRect
var _ink_material: ShaderMaterial


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_sheet = PageSheet.new()
	_sheet.visible = false
	add_child(_sheet)

	_ink_material = ShaderMaterial.new()
	_ink_material.shader = preload("res://shaders/ink_splash.gdshader")
	_ink = ColorRect.new()
	_ink.material = _ink_material
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.visible = false
	add_child(_ink)


## `from_focus` / `to_focus` are screen positions the ink splash grows from
## and recedes to (usually the player before and after the swap).
func play(style: ExitData.TransitionStyle, swap: Callable, from_focus: Vector2, to_focus: Vector2) -> void:
	is_playing = true
	EventBus.transition_started.emit()
	match style:
		ExitData.TransitionStyle.SLIDE:
			await _slide(swap)
		ExitData.TransitionStyle.INK_SPLASH:
			await _ink_splash(swap, from_focus, to_focus)
		_:
			swap.call()
	is_playing = false
	EventBus.transition_finished.emit()


func _page_size() -> Vector2:
	return get_viewport().get_visible_rect().size


## Page turn: a blank page slides in from the right, the frame swaps under
## it, and it carries on off to the left.
func _slide(swap: Callable) -> void:
	var size: Vector2 = _page_size()
	_sheet.page_size = size
	_sheet.position = Vector2(size.x + PageSheet.SHADOW_WIDTH, 0)
	_sheet.queue_redraw()
	_sheet.visible = true

	var tween_in: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_in.tween_property(_sheet, "position:x", 0.0, SLIDE_TIME)
	await tween_in.finished
	swap.call()
	await get_tree().create_timer(HOLD_TIME).timeout

	var tween_out: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_out.tween_property(_sheet, "position:x", -size.x, SLIDE_TIME)
	await tween_out.finished
	_sheet.visible = false


## Ink floods out from the player, the frame swaps in the dark, and the ink
## drains back into the player's new position.
func _ink_splash(swap: Callable, from_focus: Vector2, to_focus: Vector2) -> void:
	var size: Vector2 = _page_size()
	_ink.size = size
	_ink_material.set_shader_parameter("rect_size", size)
	_ink_material.set_shader_parameter("seed", randf() * 100.0)
	_ink_material.set_shader_parameter("center", from_focus / size)
	_ink_material.set_shader_parameter("progress", 0.0)
	_ink.visible = true

	var tween_in: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_in.tween_method(_set_ink_progress, 0.0, 1.0, SPLASH_TIME)
	await tween_in.finished
	swap.call()
	_ink_material.set_shader_parameter("center", to_focus / size)
	_ink_material.set_shader_parameter("seed", randf() * 100.0)
	await get_tree().create_timer(HOLD_TIME).timeout

	var tween_out: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_out.tween_method(_set_ink_progress, 1.0, 0.0, SPLASH_TIME)
	await tween_out.finished
	_ink.visible = false


func _set_ink_progress(value: float) -> void:
	_ink_material.set_shader_parameter("progress", value)
