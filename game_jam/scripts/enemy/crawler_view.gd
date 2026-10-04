class_name CrawlerView
extends Node2D
## How the Ink Crawler looks and feels, as a child of its brain (InkCrawler).
## Stop-motion: the drawn pose and position only change POSE_FPS times a
## second, with the odd held frame and twitch. Owns the eye glow (red when
## hunting, pale otherwise) and reports nearness for the dread effects.

const POSE_FPS: float = 8.0
const PENCIL: Color = Color(0.55, 0.62, 0.72, 0.55)

var _brain: InkCrawler
var _pose_timer: float = 0.0
## New random pose each stop-motion tick (ShadowView reads it too).
var _pose_seed: int = 0
var _drip_t: float = 0.0
var _eye_light: PointLight2D
## 0..1 how unfinished the last pose is: right after a move the strokes are
## still being penned in over faint pencil guides.
var _pen: float = 0.0
var _near: float = 0.0


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
	var glimpse: CrawlerGlimpse = CrawlerGlimpse.new()
	add_child(glimpse)


func _process(delta: float) -> void:
	if _brain.is_frozen():
		_eye_light.energy = 0.3 if randf() < 0.5 else 0.0
		return
	_drip_t += delta
	if _pen > 0.0:
		_pen = maxf(0.0, _pen - delta * 9.0)
		queue_redraw()
	_pose_timer -= delta
	if _pose_timer > 0.0:
		return
	_pose_timer = 1.0 / POSE_FPS
	if randf() < 0.12 and _brain.state != InkCrawler.State.LUNGE:
		return
	# Closer = more erratic stop-motion.
	var twitch: Vector2 = Vector2(randf_range(-6, 6), randf_range(-3, 1)) * (1.0 + _near * 1.5) if randf() < 0.1 + _near * 0.3 else Vector2.ZERO
	global_position = _brain.global_position + twitch
	_pose_seed = randi()
	var coil: float = 1.0 if _brain.state == InkCrawler.State.TELEGRAPH else 0.0
	_eye_light.position = CrawlerArt.head_position(_brain.rise, _brain.facing, coil) + Vector2(0, -4)
	_eye_light.color = InkDraw.RED if _brain.is_hunting() else CrawlerArt.PALE
	_eye_light.energy = (1.6 if _brain.is_hunting() else 0.6) * smoothstep(0.5, 1.0, _brain.rise)
	var near: float = 0.0
	if _brain.state != InkCrawler.State.DORMANT:
		near = clampf(1.0 - _brain.position.distance_to(_brain.player_pos()) / 650.0, 0.0, 1.0) * _brain.rise
	_near = near
	if _brain.moved:
		_pen = 1.0
	EventBus.crawler_proximity.emit(near, _brain.moved)
	queue_redraw()


func _draw() -> void:
	var hunting: bool = _brain.is_hunting()
	var to_player: Vector2 = _brain.player_pos() - _brain.position
	var close: float = clampf(1.0 - to_player.length() / 380.0, 0.0, 1.0)
	# Even asleep, the eyes follow the player.
	CrawlerArt.look = Vector2(clampf(to_player.x / 300.0, -1.0, 1.0), clampf(to_player.y / 300.0, -1.0, 1.0))
	var reach: float = 1.0 if _brain.state == InkCrawler.State.LUNGE else 0.0
	var coil: float = 1.0 if _brain.state == InkCrawler.State.TELEGRAPH else 0.0
	var mouth: float = maxf(close, coil) if _brain.rise > 0.6 else 0.0
	if _pen > 0.05 and _brain.rise > 0.3:
		_guides(coil)
	InkDraw.gap_ratio = 0.45 * _pen
	CrawlerArt.draw(self, _brain.rise, _pose_seed, _brain.facing, reach, coil, mouth, _drip_t, InkDraw.RED if hunting else CrawlerArt.PALE)
	InkDraw.gap_ratio = 0.0


## Pencil construction lines under the ink: it is being drawn as it moves.
func _guides(coil: float) -> void:
	var head: Vector2 = CrawlerArt.head_position(_brain.rise, _brain.facing, coil)
	var c: Color = Color(PENCIL, PENCIL.a * _pen)
	draw_arc(head, 34.0, 0.0, TAU, 20, c, 1.5)
	draw_line(head, Vector2(0, -6), c, 1.5)
	draw_line(Vector2(-90, 0), Vector2(90, 0), c, 1.0)
	for i in 3:
		draw_arc(head.lerp(Vector2.ZERO, (i + 1) / 4.0), 10.0, 0.0, TAU, 10, c, 1.0)


func _exit_tree() -> void:
	EventBus.crawler_proximity.emit(0.0, false)
