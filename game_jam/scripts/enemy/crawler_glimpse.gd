class_name CrawlerGlimpse
extends Node2D
## Rare and restrained: while the torch is on, now and then a silhouette of
## the Crawler stands at the very edge of the cone for a few frames, then is
## gone. At most once every COOLDOWN seconds; never while it is hunting.

const COOLDOWN: float = 40.0
const CHANCE_PER_SECOND: float = 0.06
const SHOW_TIME: float = 0.09

var _cooldown: float = 12.0
var _show: float = 0.0


func _ready() -> void:
	top_level = true


func _process(delta: float) -> void:
	var brain: InkCrawler = get_parent().get_parent() as InkCrawler
	if _show > 0.0:
		_show -= delta
		if _show <= 0.0:
			queue_redraw()
		return
	_cooldown -= delta
	if _cooldown > 0.0 or not LightingSystem.is_light_on or brain == null or brain.is_hunting():
		return
	if randf() < CHANCE_PER_SECOND * delta:
		var lamp: Flashlight = get_tree().get_first_node_in_group(&"flashlight") as Flashlight
		if lamp == null:
			return
		var side: float = 1.0 if randf() < 0.5 else -1.0
		var dir: Vector2 = Vector2.from_angle(lamp.global_rotation + side * Flashlight.CONE_HALF_ANGLE * 0.85)
		global_position = lamp.global_position + dir * randf_range(260.0, 380.0) + Vector2(0, 60)
		_show = SHOW_TIME
		_cooldown = COOLDOWN
		AudioManager.play(&"whisper", -14.0, 0.1)
		queue_redraw()


func _draw() -> void:
	if _show <= 0.0:
		return
	var body: PackedVector2Array = PackedVector2Array([Vector2(-18, 0), Vector2(-26, -90), Vector2(-14, -150),
		Vector2(10, -158), Vector2(22, -120), Vector2(18, 0)])
	draw_colored_polygon(body, Color(InkDraw.INK, 0.85))
	draw_circle(Vector2(-4, -138), 3.0, CrawlerArt.PALE)
	draw_circle(Vector2(8, -140), 2.0, CrawlerArt.PALE)
