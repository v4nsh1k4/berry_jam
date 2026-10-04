class_name Frame
extends Node2D
## One comic panel, built from a FrameData resource. Lives at
## PANEL_RECT.position; children use panel coordinates.

## Where every panel sits on the 1280x720 page. The strip below it is kept
## free for the inventory.
const PANEL_RECT: Rect2 = Rect2(48, 32, 1184, 528)

## Scripted moments (and scripted presences) a frame can list in FrameData.events.
const EVENT_SCRIPTS: Dictionary = {
	&"ink_hand": preload("res://scripts/events/ink_hand_event.gd"),
	&"crawler_window": preload("res://scripts/events/crawler_window_event.gd"),
	&"crawler_fingers": preload("res://scripts/events/crawler_fingers_event.gd"),
	&"passage_stalker": preload("res://scripts/events/passage_stalker_event.gd"),
	&"cellar_chase": preload("res://scripts/events/cellar_chase_event.gd"),
	&"return_gate": preload("res://scripts/events/return_gate_event.gd"),
	&"margin_chase": preload("res://scripts/events/margin_chase_event.gd"),
	&"artist_hand": preload("res://scripts/enemy/artist_hand.gd"),
}

## Interactable kinds with their own behaviour; everything else is the base class.
const KIND_CLASSES: Dictionary = {
	&"hiding_spot": preload("res://scripts/interactables/hiding_spot.gd"),
	&"return_spot": preload("res://scripts/interactables/return_spot.gd"),
	&"light_ink": preload("res://scripts/interactables/light_puzzle.gd"),
	&"lens": preload("res://scripts/interactables/light_puzzle.gd"),
	&"shadow_puzzle": preload("res://scripts/interactables/light_puzzle.gd"),
	&"lit_writing": preload("res://scripts/interactables/light_puzzle.gd"),
	&"lever": preload("res://scripts/interactables/light_puzzle.gd"),
}

var data: FrameData

@onready var _darkness: CanvasModulate = $Darkness
@onready var _paper: ColorRect = $Paper
@onready var _background: FrameBackground = $Background
@onready var _exits: Node2D = $Exits
@onready var _props: Node2D = $Props


func setup(frame_data: FrameData) -> void:
	data = frame_data
	var a: float = data.ambient_light
	_darkness.color = Color(a, a, minf(a * 1.15, 1.0)) if a < 0.8 else Color(1, 1, 1)
	if GameState.has_flag(&"comic_repaired") and a < 0.78:
		_darkness.color = Color(0.78, 0.78, 0.82)
	_paper.size = PANEL_RECT.size
	_background.panel_size = PANEL_RECT.size
	_background.style = data.background_style
	_background.sketch = data.sketch
	_set_halftone(GameState.glitch_of(data))
	EventBus.comic_repaired.connect(_on_comic_repaired)
	if data.spread != null:
		var spread: SpreadController = SpreadController.new()
		_props.add_child(spread)
		spread.setup(data.spread)
	for spot in data.lights:
		var light: LightSpot = LightSpot.new()
		_props.add_child(light)
		light.setup(spot)
	for exit_data in data.exits:
		var zone: ExitZone = ExitZone.new()
		_exits.add_child(zone)
		zone.setup(exit_data)
	for interactable_data in data.interactables:
		var interactable: Interactable = (KIND_CLASSES.get(interactable_data.kind, Interactable) as GDScript).new()
		_props.add_child(interactable)
		interactable.setup(interactable_data)
	for npc_data in data.npcs:
		var npc: Npc = Npc.new()
		_props.add_child(npc)
		npc.setup(npc_data)
	if data.crawler_spawn != Vector2.INF:
		var crawler: InkCrawler
		match data.crawler_kind:
			&"shadow":
				crawler = InkShadow.new()
			&"heart":
				crawler = HeartShadow.new()
			_:
				crawler = InkCrawler.new()
		crawler.position = data.crawler_spawn
		crawler.walk_area = data.walk_area
		crawler.patrol = data.crawler_patrol
		_props.add_child(crawler)
	for event_id in data.events:
		if not EVENT_SCRIPTS.has(event_id):
			push_warning("Frame %s: unknown event '%s'" % [data.id, event_id])
			continue
		var event: Node2D = Node2D.new()
		event.set_script(EVENT_SCRIPTS[event_id])
		_props.add_child(event)


## Collapsing halftone: coarser, heavier dots as the panel breaks down.
func _set_halftone(glitch: float) -> void:
	var paper: ShaderMaterial = _paper.material as ShaderMaterial
	paper.set_shader_parameter("dot_spacing", 7.0 + glitch * 6.0)
	paper.set_shader_parameter("shade_bottom", 0.22 + glitch * 0.25)


## The last word went home: the halftone rebuilds itself and the panel lightens.
func _on_comic_repaired() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_method(_set_halftone, data.glitch, 0.0, 2.5)
	tween.tween_property(_darkness, "color", Color(0.78, 0.78, 0.82), 3.0)
