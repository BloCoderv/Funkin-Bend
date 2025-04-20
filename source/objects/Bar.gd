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

func _ready():
	_on_value_changed(value)
	left.color = color_left
	right.color = color_right

func _on_value_changed(new:float):
	var tex_size = texture.get_size()
	var offset = margin / 2.0
	
	tex_size.x -= margin.x
	tex_size.y -= margin.x
	
	left.size.y = tex_size.y
	right.size.y = tex_size.y
	
	if left_to_right:
		left.size.x = lerp(0.0, tex_size.x, value / 100.0)
	else:
		left.size.x = lerp(0.0, tex_size.x, 1 - value / 100.0)
	left.position = offset
	
	right.size.x = tex_size.x - left.size.x
	right.position.x = left.size.x + offset.x
	right.position.y = offset.y
	
	bar_middle = right.position.x

func change_color(c_left:Color, c_right:Color):
	color_left = c_left
	color_right = c_right
	left.color = color_left
	right.color = color_right
