extends Node2D
class_name Stage

@export var camera_zoom:float = 1.0

@export var characters:Dictionary = {
	"player": {
		"z_index": 3,
		"position": Vector2(989.5, 885),
		"camera_offset": Vector2(0, 0)
	},
	"opponent": {
		"z_index": 2,
		"position": Vector2(335, 885),
		"camera_offset": Vector2(0, 0)
	},
	"gf": {
		"z_index": 1,
		"position": Vector2(751.5, 787),
		"camera_offset": Vector2(0, 0)
	}
}

@export var optimizations:Dictionary = {
	# CHILD ID
	2: {
		"visible": false
	}
}
