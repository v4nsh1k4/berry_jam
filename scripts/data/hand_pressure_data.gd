class_name HandPressureData
extends Resource
## Tuning for the Artist's hand in the return phase. Every value comes as a
## pair: `*_strong` while the player still holds every word, `*_weak` with one
## word left. In between it is blended by the share of words still held. Once
## the last ordinary word is back, the hand stops and only watches.

## Seconds between erase attempts.
@export var interval_strong: float = 4.5
@export var interval_weak: float = 9.0
## Warning before the eraser comes down (shadow on the floor, growl). Never
## shorter than MIN_TELEGRAPH.
@export var telegraph_strong: float = 1.1
@export var telegraph_weak: float = 1.6
## Width of the strip it rubs out, in pixels.
@export var width_strong: float = 230.0
@export var width_weak: float = 120.0
## How fast it drifts after the player, pixels per second.
@export var speed_strong: float = 150.0
@export var speed_weak: float = 60.0
## Seconds the eraser rubs the floor (the only time it can catch).
@export var rub_time: float = 0.55
## Grace after entering a room before the first attempt.
@export var first_delay: float = 3.0

const MIN_TELEGRAPH: float = 0.6


## `held` 0..1 share of ordinary words the player still holds.
func interval(held: float) -> float:
	return lerpf(interval_weak, interval_strong, held)


func telegraph(held: float) -> float:
	return maxf(MIN_TELEGRAPH, lerpf(telegraph_weak, telegraph_strong, held))


func width(held: float) -> float:
	return lerpf(width_weak, width_strong, held)


func speed(held: float) -> float:
	return lerpf(speed_weak, speed_strong, held)
