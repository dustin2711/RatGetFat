extends CanvasLayer

@export var camera: Camera2D = null

func _ready():
#	self.offset += Vector2(100, 100)
	self.offset += camera.get_viewport_rect().size / 2.0
	self.scale = camera.zoom
