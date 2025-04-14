extends TextureRect
class_name Note

var strum_data:int = 0
var data:int = 0

var time:float = 0.0
var length:float = 0.0

var must_press:bool = true # if true, note is from player
var was_hit:bool = false
var is_sustain:bool = false
var can_hit:bool = false
var too_late:bool = false

var pivot:Vector2 = Vector2.ZERO # pivot in middle

func _ready():
	# CALC PIVOT
	texture = Global.NOTES.get_frame_texture(str(strum_data), 0)
	var tex_size = texture.get_size() * scale
	pivot = -tex_size / 2
	
	is_sustain = bool(length)
