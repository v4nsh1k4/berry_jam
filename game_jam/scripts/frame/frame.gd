class_name Frame
extends Node2D
## One comic panel, built from a FrameData resource. Lives at
## PANEL_RECT.position; children use panel coordinates.

## Where every panel sits on the 1280x720 page. The strip below it is kept
## free for the inventory.
const PANEL_RECT: Rect2 = Rect2(48, 32, 1184, 528)

## Scripted moments a frame can list in FrameData.events.
# TODO(later): Chapter 2 and 3 scripted events register here.
const EVENT_SCRIPTS: Dictionary = {
	&"ink_hand": preload("res://scripts/events/ink_hand_event.gd"),
	&"crawler_window": preload("res://scripts/events/crawler_window_event.gd"),
	&"crawler_fingers": preload("res://scripts/events/crawler_fingers_event.gd"),
	&"passage_stalker": preload("res://scripts/events/passage_stalker_event.gd"),
	&"cellar_chase": preload("res://scripts/events/cellar_chase_event.gd"),
	&"gallery_gate": preload("res://scripts/events/gallery_gate_event.gd"),
	&"margin_chase": preload("res://scripts/events/margin_chase_event.gd"),
}

## Interactable kinds with their own behaviour; everything else is the base class.
const KIND_CLASSES: Dictionary = {
	&"hiding_spot": preload("res://scripts/interactables/hiding_spot.gd"),
	&"return_spot": preload("res://scripts/interactables/return_spot.gd"),
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
	_paper.size = PANEL_RECT.size
	_background.panel_size = PANEL_RECT.size
	_background.style = data.background_style
	_background.sketch = data.sketch
	# Collapsing halftone: coarser, heavier dots as the panel breaks down.
	var paper: ShaderMaterial = _paper.material as ShaderMaterial
	paper.set_shader_parameter("dot_spacing", 7.0 + data.glitch * 6.0)
	paper.set_shader_parameter("shade_bottom", 0.22 + data.glitch * 0.25)
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
		# TODO(later): new enemy types are placed per frame here.
		var crawler: InkCrawler = InkShadow.new() if data.crawler_kind == &"shadow" else InkCrawler.new()
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
