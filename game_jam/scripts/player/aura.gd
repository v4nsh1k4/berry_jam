extends PointLight2D
## Faint always-on glow so the player and their empty bubble stay visible in
## the dark. It does not count as "light" for the Ink Crawler.


func _ready() -> void:
	texture = LightTextures.radial()
