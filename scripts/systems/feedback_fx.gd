extends Node2D
## Comic feedback on its own CanvasLayer: ink-splash particles, onomatopoeia
## ("CREAK", "THUD", "SNATCH!") and a short hit-stop when a word is stolen.

const HIT_STOP: float = 0.08

static var _dot: ImageTexture


func _ready() -> void:
	EventBus.bubble_stolen.connect(_on_bubble_stolen)
	EventBus.ability_failed.connect(_on_ability_failed)
	EventBus.player_caught.connect(_on_player_caught)
	EventBus.bubble_returned.connect(_on_bubble_returned)


## A word goes home: soft, not punchy. Ink drops that start red and fade to
## white as they rise, and a gentle THANK YOU.
func _on_bubble_returned(_bubble: BubbleData, at: Vector2) -> void:
	if at == Vector2.INF:
		at = _player_screen_pos() + Vector2(0, -120)
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, InkDraw.RED)
	ramp.set_color(1, Color(1, 1, 1, 0))
	var drops: CPUParticles2D = splash(at, 26, Color.WHITE)
	drops.gravity = Vector2(0, -160)
	drops.initial_velocity_min = 40.0
	drops.initial_velocity_max = 140.0
	drops.lifetime = 1.2
	drops.color_ramp = ramp
	popup("THANK YOU", at + Vector2(0, -50), 0.8)


func _on_bubble_stolen(_bubble: BubbleData, from: Vector2) -> void:
	if from == Vector2.INF:
		return
	splash(from, 22, InkDraw.RED)
	popup("SNATCH!", from + Vector2(0, -40), 1.0, InkDraw.RED)
	_hit_stop()


func _on_ability_failed(_bubble: BubbleData, _target_id: StringName) -> void:
	popup("THUD", _player_screen_pos() + Vector2(40, -150), 0.8)


func _on_player_caught() -> void:
	var pos: Vector2 = _player_screen_pos() + Vector2(0, -50)
	splash(pos, 40)
	popup("SPLAT!", pos + Vector2(0, -60), 1.3, InkDraw.RED)
	_red_flash()


func _player_screen_pos() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	return player.get_global_transform_with_canvas().origin if player != null else get_viewport_rect().size * 0.5


## One-shot burst of ink drops.
func splash(pos: Vector2, amount: int, color: Color = InkDraw.INK) -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = pos
	particles.texture = _dot_texture()
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 700)
	particles.initial_velocity_min = 140.0
	particles.initial_velocity_max = 320.0
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.1
	particles.color = color
	add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
	return particles


## Comic sound word that punches in, holds, and floats away.
func popup(text: String, pos: Vector2, size_scale: float = 1.0, fill: Color = InkDraw.WHITE) -> void:
	var label: Label = Label.new()
	label.text = text
	var settings: LabelSettings = LabelSettings.new()
	settings.font_size = int(46 * size_scale)
	settings.font_color = fill
	settings.outline_size = 12
	settings.outline_color = InkDraw.INK
	settings.shadow_color = InkDraw.INK
	settings.shadow_offset = Vector2(4, 4)
	label.label_settings = settings
	add_child(label)
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5
	label.position = pos - label.size * 0.5
	label.rotation = randf_range(-0.25, 0.25)
	label.scale = Vector2(0.2, 0.2)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "scale", Vector2(1.25, 1.25), 0.09).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.45)
	tween.parallel().tween_property(label, "position:y", label.position.y - 24.0, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(label.queue_free)


## Caught: one short, hard red flash over the whole page.
func _red_flash() -> void:
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(InkDraw.RED, 0.55)
	flash.size = get_viewport_rect().size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween: Tween = flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)


func _hit_stop() -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(HIT_STOP, true, false, true).timeout
	Engine.time_scale = 1.0


static func _dot_texture() -> ImageTexture:
	if _dot == null:
		var img: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
		for y in 12:
			for x in 12:
				var d: float = Vector2(x - 5.5, y - 5.5).length()
				img.set_pixel(x, y, Color(1, 1, 1, clampf(6.0 - d, 0.0, 1.0)))
		_dot = ImageTexture.create_from_image(img)
	return _dot
