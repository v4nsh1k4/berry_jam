class_name SpreadController
extends Node2D
## Runs a PageSpreadData page inside a normal Frame (Frame.setup adds it
## first, so its panel drawings sit under the props). It keeps the player on
## their panel's floor, hops them across gutters (SpreadHop), drops them into
## the gutter through tears (respawn at the panel's entry, never a death),
## handles jumping, and lights each panel on its own.
##
## Lighting (web-safe, no SubViewports): the frame's CanvasModulate keeps
## everything dark; each panel's drawing, props and (while inside) the player
## carry that panel's light-mask bit, and a soft rectangular fill light per
## panel only lights its own bit. The torch lights every bit, so it reaches
## across panels.

const HOP_TIME: float = 0.45
const DEPTH: float = 8.0
const EDGE: float = 14.0
const GUTTER_BIT: int = 1 << 6

var data: PageSpreadData
var current: SpreadPanelData
var airborne: bool:
	get:
		return _jumper.airborne
var hopping: bool = false
## 0..1 how lit the pencil plank is (for drawing).
var plank_lit: float = 0.0

var _player: Player
var _jumper: SpreadJump = SpreadJump.new()
var _entry: Vector2
var _views: Array[SpreadPanelView] = []
var _note_cooldown: float = 0.0


func setup(spread: PageSpreadData) -> void:
	data = spread
	add_child(_jumper)
	var gutter: SpreadPanelView = SpreadPanelView.new()
	gutter.controller = self
	gutter.light_mask = 1 | GUTTER_BIT
	add_child(gutter)
	_add_fill(Rect2(Vector2.ZERO, Frame.PANEL_RECT.size), 1.0, GUTTER_BIT)
	for i in data.panels.size():
		var panel: SpreadPanelData = data.panels[i]
		var view: SpreadPanelView = SpreadPanelView.new()
		view.controller = self
		view.panel = panel
		view.light_mask = 1 | _bit(i)
		add_child(view)
		_views.append(view)
		if panel.ambient > 0.01:
			_add_fill(panel.rect, panel.ambient * 1.3, _bit(i))
	var fingers: SpreadFingers = SpreadFingers.new()
	fingers.controller = self
	fingers.z_index = 5
	add_child(fingers)
	fingers.enabled = data.finger_hazard
	_assign_masks.call_deferred()


static func _bit(index: int) -> int:
	return 1 << (index + 1)


func _add_fill(rect: Rect2, energy: float, bit: int) -> void:
	var fill: PointLight2D = PointLight2D.new()
	fill.texture = SpreadArt.fill_texture()
	fill.position = rect.get_center()
	fill.scale = rect.size / float(SpreadArt.FILL_SIZE) * 1.04
	fill.energy = energy
	fill.range_item_cull_mask = bit
	add_child(fill)


## Every prop takes the light bit of the panel it stands in.
func _assign_masks() -> void:
	for node in get_parent().get_children():
		if node == self or not node is CanvasItem:
			continue
		var at: Vector2 = (node as Node2D).position
		if node is Interactable:
			at += (node as Interactable).data.size * 0.5
		var index: int = _index_at(at)
		if index >= 0:
			_set_mask_recursive(node as CanvasItem, 1 | _bit(index))
	_player = get_tree().get_first_node_in_group(&"player") as Player
	_jumper.setup(_player)
	if _player != null:
		_enter(_panel_at(to_local(_player.global_position)), to_local(_player.global_position))


static func _set_mask_recursive(item: CanvasItem, mask: int) -> void:
	item.light_mask = mask
	for child in item.get_children():
		if child is CanvasItem:
			_set_mask_recursive(child as CanvasItem, mask)


func _index_at(p: Vector2) -> int:
	for i in data.panels.size():
		if data.panels[i].rect.grow(6.0).has_point(p):
			return i
	return -1


func _panel_at(p: Vector2) -> SpreadPanelData:
	var index: int = _index_at(p)
	return data.panels[index] if index >= 0 else data.panels[0]


func panel_by_id(id: StringName) -> SpreadPanelData:
	for panel in data.panels:
		if panel.id == id:
			return panel
	return null


## The player is now in `panel`, standing at `at`: clamp them to its floor.
func _enter(panel: SpreadPanelData, at: Vector2) -> void:
	current = panel
	_entry = at
	var band: Rect2 = Rect2(panel.rect.position.x + EDGE, panel.floor_y - DEPTH, panel.rect.size.x - EDGE * 2.0, DEPTH * 2.0)
	_player.walk_area = Rect2(to_global(band.position), band.size)
	_player.light_mask = 1 | _bit(data.panels.find(panel))


func is_bridged(panel: SpreadPanelData) -> bool:
	if panel.gap_bridge_flag != &"" and GameState.has_flag(panel.gap_bridge_flag):
		return true
	return panel.gap_lit_bridge and plank_lit > 0.6


func _physics_process(delta: float) -> void:
	_note_cooldown = maxf(0.0, _note_cooldown - delta)
	if _player == null or current == null:
		return
	_update_plank(delta)
	_jumper.update(delta, _player.can_act() and not hopping)
	if hopping or not _player.can_act():
		return
	var p: Vector2 = to_local(_player.global_position)
	var band: Rect2 = Rect2(to_local(_player.walk_area.position), _player.walk_area.size)
	var axis: float = Input.get_axis("move_left", "move_right")
	if axis > 0.0 and p.x >= band.end.x - 2.0 and _try_hop(&"right", p):
		return
	if axis < 0.0 and p.x <= band.position.x + 2.0 and _try_hop(&"left", p):
		return
	if Input.is_action_pressed("move_down") and p.y >= band.end.y - 1.0 and _try_hop(&"down", p):
		return
	if not airborne and _jumper.take_press():
		if not _try_hop(&"jump", p):
			_jumper.jump()
		return
	if airborne:
		return
	# A tear: a short grace to jump, then drop (through to the panel below if
	# a fall hop leads there, else into the gutter).
	if current.gap != Vector2.ZERO and p.x > current.gap.x and p.x < current.gap.y and not is_bridged(current):
		if _jumper.over_tear(get_physics_process_delta_time()) and not _try_hop(&"fall", p):
			_fall_into_gutter()
		return
	_jumper.on_solid_floor()
	_try_hop(&"fall", p)


func _update_plank(delta: float) -> void:
	if current == null or not current.gap_lit_bridge:
		plank_lit = 0.0
		return
	var lamp: Flashlight = get_tree().get_first_node_in_group(&"flashlight") as Flashlight
	var r: Rect2 = Rect2(current.gap.x, current.floor_y - 30.0, current.gap.y - current.gap.x, 50.0)
	var lit: bool = lamp != null and lamp.illuminates_rect(Rect2(to_global(r.position), r.size))
	plank_lit = move_toward(plank_lit, 1.0 if lit else 0.0, delta * (4.0 if lit else 2.0))
	for view in _views:
		if view.panel == current:
			view.queue_redraw()


func _try_hop(trigger: StringName, p: Vector2) -> bool:
	for hop in data.hops:
		if hop.from_panel != current.id or hop.trigger != trigger:
			continue
		if hop.zone_x != Vector2.ZERO and (p.x < hop.zone_x.x or p.x > hop.zone_x.y):
			continue
		if hop.requires_flag != &"" and not GameState.has_flag(hop.requires_flag):
			if _note_cooldown <= 0.0 and hop.locked_caption != "":
				_note_cooldown = 4.0
				EventBus.caption_requested.emit(hop.locked_caption, 2.5)
			return trigger == &"right" or trigger == &"left"
		_hop(hop)
		return true
	return false


## An arc across the gutter into the next panel.
func _hop(hop: SpreadHop) -> void:
	hopping = true
	var target: SpreadPanelData = panel_by_id(hop.to_panel)
	var from: Vector2 = to_local(_player.global_position)
	var to: Vector2 = hop.to_point
	_player.walk_area = Rect2()
	AudioManager.play(&"swoosh", -6.0, 0.08)
	EventBus.player_reaction.emit("WHOOSH")
	EventBus.shake_requested.emit(0.12)
	var arc: float = 90.0 if to.y <= from.y + 40.0 else 30.0
	var tween: Tween = create_tween()
	tween.tween_method(func(k: float) -> void:
		_player.global_position = to_global(from.lerp(to, k) + Vector2(0, -sin(k * PI) * arc)), 0.0, 1.0, HOP_TIME)
	await tween.finished
	if not is_instance_valid(_player):
		return
	_enter(target, to)
	hopping = false


## Into the white: drop, then the gutter spits you back at the panel's entry.
func _fall_into_gutter() -> void:
	hopping = true
	_player.walk_area = Rect2()
	AudioManager.play(&"swoosh", -4.0, 0.2)
	var start: Vector2 = _player.global_position
	var tween: Tween = create_tween()
	tween.tween_property(_player, "global_position", start + Vector2(0, 140), 0.35).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_player, "modulate:a", 0.0, 0.35)
	await tween.finished
	if not is_instance_valid(_player):
		return
	knock_back("You fall into the gutter. The white spits you back.")


## Back to where the player came into this panel (gutter falls, finger stabs).
func knock_back(caption: String) -> void:
	hopping = true
	_player.global_position = to_global(_entry)
	_player.modulate.a = 1.0
	_jumper.cancel()
	_enter(current, _entry)
	EventBus.shake_requested.emit(0.25)
	EventBus.caption_requested.emit(caption, 2.5)
	await get_tree().create_timer(0.2).timeout
	hopping = false
