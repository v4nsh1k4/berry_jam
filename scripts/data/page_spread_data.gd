class_name PageSpreadData
extends Resource
## A whole comic page of small panels in one frame (FrameData.spread). The
## player hops between panels across the white gutters (SpreadController);
## each panel is lit on its own.

@export var panels: Array[SpreadPanelData] = []
@export var hops: Array[SpreadHop] = []
## Printed in the page corner.
@export var page_number: int = 13
## Fingers poke up through the gutter if the torch stays on too long.
@export var finger_hazard: bool = true
