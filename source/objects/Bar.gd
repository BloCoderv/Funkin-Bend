@tool
extends Control


enum Direction {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT
}

@onready var left:ColorRect = get_node("Left")
@onready var right:ColorRect = get_node("Right")

@export var bar_direction:Direction = Direction.LEFT_TO_RIGHT:
	set(v): 
		bar_direction = v
		update_bar()

@export var color_left:Color = Util.COLOR_HEALTH_RED:
	set(v):
		color_left = v
		left.color = v

@export var color_right:Color = Util.COLOR_HEALTH_GREEN:
	set(v):
		color_right = v
		right.color = v

@export var min_value:float = 0.0:
	set(v): 
		min_value = v
		update_bar()

@export var max_value:float = 100.0:
	set(v): 
		max_value = v
		update_bar()

@export var value:float = 50.0: 
	set(v): 
		value = clampf(v, min_value, max_value)
		update_bar()

func update_bar():
	if left == null: return
	
	var percent:float = remap(value, min_value, max_value, 0, 100)
	
	if bar_direction == Direction.LEFT_TO_RIGHT: 
		left.size.x = lerp(0.0, size.x, percent / 100)
	else:
		left.size.x = lerp(0.0, size.x, 1 - percent / 100)
	right.size.x = size.x - left.size.x

func _on_resized():
	update_bar()
