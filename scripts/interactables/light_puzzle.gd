class_name LightPuzzle
extends Interactable
## Flashlight puzzles, all driven by InteractableData (no per-puzzle code):
##   light_ink      ink that recedes while the cone holds on it for
##                  `light_hold` s (look in `text`: door, pool, growth). Doors
##                  and pools drift back slowly in the dark; growth creeps
##                  back fast. Cleared = resolved (sets_flag, saved).
##   lens           a glass that, lit for `light_hold` s, throws the light on
##                  somewhere else: sets its flag (e.g. lit_writing elsewhere).
##   lit_writing    writing that shows once `requires_flag` is set.
##   lever          (plain E) with requires_flag: hidden until that flag is set,
##                  e.g. by a lens in another panel lighting it.
##   shadow_puzzle  an iron shape on a stand; lit from inside `stand_spot`, its
##                  shadow lands in the outline on the wall (symbols[0]) and
##                  must be held there for `light_hold` s.
## Light still fills the noticed meter, so every use is a risk where it hunts.

const REGROW: Dictionary = {&"door": 0.25, &"pool": 0.25, &"growth": 0.7}

## 0..1 how far the light has got (ink cleared, shadow held, lens warmed).
var progress: float = 0.0
## shadow_puzzle: -1..1 where the shadow falls relative to the outline
## (0 = in place), and whether the object is lit right now.
var shadow_offset: float = 1.0
var lit_now: bool = false


func setup(interactable: InteractableData) -> void:
	super.setup(interactable)
	if resolved:
		progress = 1.0
		_add_done_glow()
	if data.kind == &"shadow_puzzle":
		# A dim pool of light on the chalk mark, so it can be found in the dark.
		var mark: PointLight2D = PointLight2D.new()
		mark.texture = LightTextures.radial()
		mark.texture_scale = 70.0 / LightTextures.RADIAL_RADIUS
		mark.energy = 0.6
		mark.position = data.stand_spot.get_center() - data.position
		add_child(mark)
	if data.kind == &"lit_writing":
		reveal = 1.0 if GameState.has_flag(data.requires_flag) else 0.0
		EventBus.interactable_resolved.connect(_on_flag_maybe_set)


func _on_flag_maybe_set(_id: StringName, _kind: StringName, _pos: Vector2) -> void:
	if GameState.has_flag(data.requires_flag) and reveal < 1.0:
		create_tween().tween_property(self, "reveal", 1.0, 0.8)
		if not resolved:
			resolve()


func _process(delta: float) -> void:
	super._process(delta)
	if data == null or resolved or data.kind == &"lit_writing" or data.kind == &"lever":
		if data != null and data.kind == &"lever":
			_update_group()
		return
	var lamp: Flashlight = get_tree().get_first_node_in_group(&"flashlight") as Flashlight
	var rect: Rect2 = Rect2(global_position, data.size * global_scale)
	lit_now = lamp != null and lamp.illuminates_rect(rect)
	var gain: bool = lit_now
	if data.kind == &"shadow_puzzle":
		gain = lit_now and _update_shadow()
	if gain:
		progress = minf(progress + delta / maxf(data.light_hold, 0.1), 1.0)
	else:
		var back: float = REGROW.get(StringName(data.text), 0.25) if data.kind == &"light_ink" else 0.8
		progress = maxf(progress - delta * back, 0.0)
	if progress >= 1.0:
		_clear()


## Where the shadow falls, from the player's position: true when it sits in
## the wall outline (the player is inside stand_spot).
func _update_shadow() -> bool:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return false
	var spot: Rect2 = Rect2(Frame.PANEL_RECT.position + data.stand_spot.position, data.stand_spot.size)
	var feet: Vector2 = player.global_position
	var centre_x: float = spot.get_center().x
	shadow_offset = clampf((centre_x - feet.x) / 260.0, -1.0, 1.0)
	return spot.has_point(feet)


func _clear() -> void:
	progress = 1.0
	resolve()
	_add_done_glow()
	match data.kind:
		&"light_ink":
			AudioManager.play(&"rub", -8.0, 0.1)
		_:
			AudioManager.play(&"chime", -6.0, 0.0)


## Done markers live in the dark world layer, so a solved shadow puzzle or
## lens carries a small light: its glow shows with the torch on or off, on
## every revisit.
func _add_done_glow() -> void:
	if data.kind != &"shadow_puzzle" and data.kind != &"lens":
		return
	var glow: PointLight2D = PointLight2D.new()
	glow.texture = LightTextures.radial()
	glow.texture_scale = 110.0 / LightTextures.RADIAL_RADIUS
	glow.energy = 0.9
	glow.color = Color(1.0, 0.95, 0.75)
	glow.position = Vector2(data.size.x * 0.5, data.size.y * 0.3 - LightPuzzleArt.OUTLINE_LIFT) if data.kind == &"shadow_puzzle" else data.size * 0.5
	add_child(glow)


## A lever waiting on a flag can't be pulled (or seen) until it is set.
func _update_group() -> void:
	super._update_group()
	if data.kind == &"lever" and data.requires_flag != &"" and not GameState.has_flag(data.requires_flag) and is_in_group(&"interactable"):
		remove_from_group(&"interactable")
