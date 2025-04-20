extends TextureRect
class_name Bar

@onready var left:ColorRect = $left
@onready var right:ColorRect = $right

var smooth:bool = true # MAKES BAR VALUE LERP

var left_to_right:bool = false
var max_value:float = 100.0
var value:float = 0.0:
	set(v):
		value = clamp(v, 0, max_value)
		_on_value_changed(value)

var color_left:Color = Color.RED
var color_right:Color = Color.GREEN

var margin:Vector2 = Vector2(6, 6)
var bar_middle:float = 0.0
var middle_target:float = 0.0
var bar_target:float = 0.0

var texture_size:Vector2 = texture.get_size()
var offset:Vector2 = Vector2.ZERO

func _ready():
	_on_value_changed(value)
	left.color = color_left
	right.color = color_right
	if !smooth:
		set_process(false)

func _process(delta):
	left.size.x = lerp(left.size.x, bar_target, delta * 6)
	
	right.size.x = texture_size.x - left.size.x
	right.position.x = left.size.x + offset.x
	
	bar_middle = right.position.x

func _on_value_changed(new:float):
	texture_size = texture.get_size()
	offset = margin / 2.0
	
	texture_size.x -= margin.x
	texture_size.y -= margin.x
	
	left.size.y = texture_size.y
	right.size.y = texture_size.y
	
	if left_to_right:
		bar_target = lerp(0.0, texture_size.x, value / 100.0)
	else:
		bar_target = lerp(0.0, texture_size.x, 1 - value / 100.0)
	
	left.position = offset
	right.position.y = offset.y
	
	if !smooth:
		left.size.x = bar_target
		
		right.size.x = texture_size.x - left.size.x
		right.position.x = left.size.x + offset.x
		
		bar_middle = right.position.x

func change_color(c_left:Color, c_right:Color):
	color_left = c_left
	color_right = c_right
	left.color = color_left
	right.color = color_right
