class_name CrawlerView
extends Node2D
## How the Ink Crawler looks and feels, as a child of its brain (InkCrawler).
## Stop-motion: the drawn pose and position only change POSE_FPS times a
## second, with the odd held frame and twitch. Owns the eye glow (red when
## hunting, pale otherwise) and reports nearness for the dread effects.

const POSE_FPS: float = 8.0

var _brain: InkCrawler
var _pose_timer: float = 0.0
var _pose_seed: int = 0
var _drip_t: float = 0.0
var _eye_light: PointLight2D


func _ready() -> void:
	_brain = get_parent() as InkCrawler
	# Placed by hand on pose ticks instead of following the brain smoothly.
	top_level = true
	global_position = _brain.global_position
	_eye_light = PointLight2D.new()
	_eye_light.texture = LightTextures.radial()
	_eye_light.texture_scale = 0.35
	_eye_light.energy = 0.0
	add_child(_eye_light)


func _process(delta: float) -> void:
	if _brain.is_frozen():
		_eye_light.energy = 0.3 if randf() < 0.5 else 0.0
		return
	_drip_t += delta
	_pose_timer -= delta
	if _pose_timer > 0.0:
		return
	_pose_timer = 1.0 / POSE_FPS
	if randf() < 0.12 and _brain.state != InkCrawler.State.LUNGE:
		return
	var twitch: Vector2 = Vector2(randf_range(-6, 6), randf_range(-3, 1)) if randf() < 0.1 else Vector2.ZERO
	global_position = _brain.global_position + twitch
	_pose_seed = randi()
	var coil: float = 1.0 if _brain.state == InkCrawler.State.TELEGRAPH else 0.0
	_eye_light.position = CrawlerArt.head_position(_brain.rise, _brain.facing, coil) + Vector2(0, -4)
	_eye_light.color = InkDraw.RED if _brain.is_hunting() else CrawlerArt.PALE
	_eye_light.energy = (1.6 if _brain.is_hunting() else 0.6) * smoothstep(0.5, 1.0, _brain.rise)
	var near: float = 0.0
	if _brain.state != InkCrawler.State.DORMANT:
		near = clampf(1.0 - _brain.position.distance_to(_brain.player_pos()) / 650.0, 0.0, 1.0) * _brain.rise
	EventBus.crawler_proximity.emit(near, _brain.moved)
	queue_redraw()


func _draw() -> void:
	var hunting: bool = _brain.is_hunting()
	var close: float = clampf(1.0 - _brain.position.distance_to(_brain.player_pos()) / 260.0, 0.0, 1.0)
	var reach: float = 1.0 if _brain.state == InkCrawler.State.LUNGE else 0.0
	var coil: float = 1.0 if _brain.state == InkCrawler.State.TELEGRAPH else 0.0
	var mouth: float = maxf(close, coil) if _brain.rise > 0.6 else 0.0
	CrawlerArt.draw(self, _brain.rise, _pose_seed, _brain.facing, reach, coil, mouth, _drip_t, InkDraw.RED if hunting else CrawlerArt.PALE)


func _exit_tree() -> void:
	EventBus.crawler_proximity.emit(0.0, false)
