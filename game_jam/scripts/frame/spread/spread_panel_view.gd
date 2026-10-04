class_name SpreadPanelView
extends Node2D
## Draws one panel of a spread page (or, with no panel, the white page and
## gutters behind them all). Its own node so it can carry its panel's
## light-mask bit (see SpreadController).

var controller: SpreadController
var panel: SpreadPanelData
var _tick: int = -1


func _process(_delta: float) -> void:
	var tick: int = InkDraw.boil_tick()
	if tick != _tick:
		_tick = tick
		queue_redraw()


func _draw() -> void:
	if panel == null:
		SpreadArt.page(self, controller.data, _tick)
	else:
		SpreadArt.panel(self, panel, controller, _tick)
