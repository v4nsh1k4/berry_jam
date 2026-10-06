class_name InkShadow
extends InkCrawler
## The Ink Shadow (first version): a huge Crawler. Same state machine and
## signals; slower but relentless, a longer reach, and a wall of ink behind it
## that blocks the panel as it advances. If the player lingers, it scribbles
## out the hiding spot ahead of it: a visible scribble and a sound first.
## (It is the Artist's hand; the reveal in the Ink Heart shows it. HeartShadow
## is the lair variant that guards the last word.)

## Seconds between erasing hiding spots.
const ERASE_EVERY: float = 7.0
## Warning (scribble + sound) before a spot is gone. The Shadow holds still
## while it scribbles, plus a beat after.
const ERASE_WARNING: float = 0.9

## The wall of ink flooding the panel behind it (off in the lair).
var draws_wall: bool = true

var _erase_timer: float = ERASE_EVERY


func _init() -> void:
	speed_scale = 0.75
	catch_radius = 80.0
	lunge_range = 260.0
	relentless = true


func _make_view() -> Node2D:
	return ShadowView.new()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.DORMANT or is_frozen() or not _erases():
		return
	_erase_timer -= delta
	if _erase_timer <= 0.0:
		_erase_timer = ERASE_EVERY
		_erase_next_spot()


## Whether it is scribbling out hiding spots right now.
func _erases() -> bool:
	return true


## The nearest hiding spot still standing, ahead of it or close behind.
func _erase_next_spot() -> void:
	var best: HidingSpot = null
	var best_d: float = INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var spot: HidingSpot = node as HidingSpot
		if spot == null or spot.erased or spot.erase_progress > 0.0:
			continue
		var d: float = absf(spot.position.x + spot.data.size.x * 0.5 - position.x)
		if d < best_d:
			best = spot
			best_d = d
	if best != null:
		best.scribble_out(ERASE_WARNING)
		# It stops to scribble, and can't lunge for a while after: whoever was
		# hiding there gets a fair head start.
		freeze(ERASE_WARNING + 0.8)
		_lunge_cd = 2.5
