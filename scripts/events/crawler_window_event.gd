extends Node2D
## The Ink Crawler's silhouette rises behind the bedchamber window against
## the moon, looks in, and sinks away. Drawn small, as if far outside, with
## its base on the sill so nothing shows below the glass.

const FLAG: StringName = &"seen_crawler_window"
const SILL: Vector2 = Vector2(205, 266)
const SCALE: float = 0.42
const TRIGGER_X: float = 520.0
const DURATION: float = 3.6
const POSE_FPS: float = 8.0

var _playing: bool = false
var _t: float = 0.0
var _pose_left: float = 0.0
var _seed: int = 0


func _ready() -> void:
	if GameState.has_flag(FLAG):
		queue_free()


func _process(delta: float) -> void:
	if not _playing:
		var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and to_local(player.global_position).x > TRIGGER_X:
			_playing = true
			GameState.set_flag(FLAG)
		return
	_t += delta
	_pose_left -= delta
	if _pose_left <= 0.0:
		_pose_left = 1.0 / POSE_FPS
		_seed = randi()
		queue_redraw()
	if _t >= DURATION:
		queue_free()


func _draw() -> void:
	if not _playing:
		return
	var rise: float = smoothstep(0.0, 1.0, _t / 1.1) * (1.0 - smoothstep(2.4, DURATION, _t))
	draw_set_transform(SILL, 0.0, Vector2(SCALE, SCALE))
	CrawlerArt.draw(self, maxf(rise, 0.0), _seed, 1.0, 0.0, 0.0, 0.0, _t, CrawlerArt.PALE, false)
