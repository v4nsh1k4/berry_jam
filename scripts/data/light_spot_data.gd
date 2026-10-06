class_name LightSpotData
extends Resource
## A fixed light in a frame (Chapter 1 has no flashlight).

## candle: draws a candle and flickers. moon: cool, steady. glow: plain.
@export var kind: StringName = &"candle"
## Panel coordinates of the light (the flame, for candles).
@export var position: Vector2
@export var radius: float = 220.0
@export var energy: float = 0.8
