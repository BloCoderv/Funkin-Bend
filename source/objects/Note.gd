extends TextureRect
class_name Note

@onready var sustain:TextureRect = $Sustain
@onready var sustain_end:TextureRect = $Sustain_end

var strum_data:int = 0
var data:int = 0

var time:float = 0.0
var length:float = 0.0
var full_length:float = 0.0

var must_press:bool = true # if true, note is from player
var was_hit:bool = false
var is_sustain:bool = true
var can_hit:bool = false
var too_late:bool = false
var is_holding:bool = false

var pivot:Vector2 = Vector2.ZERO # pivot in middle

var texture_size:Vector2 = Vector2.ZERO
var end_tex:AtlasTexture = null

func _ready():
	while StrumGroup.strum_notes.size() - 1 < strum_data:
		pass
	scale = StrumGroup.strum_notes[strum_data].scale
	
	# CALC PIVOT
	texture = Global.NOTES.get_frame_texture(str(strum_data), 0)
	texture_size = texture.get_size() * scale
	pivot = -texture_size / 2

	if !is_sustain:
		sustain.queue_free()
		sustain_end.queue_free()
		return
	
	var textures:Array = Global.get_hold_textures(strum_data)
	
	sustain.texture = textures[0]
	sustain.size.x = sustain.texture.get_size().x
	
	# SUSTAIN END
	end_tex = AtlasTexture.new()
	end_tex.atlas = textures[1]
	sustain_end.texture = end_tex
	
	if StrumGroup.player_strums[strum_data].downscroll:
		sustain.scale.y *= -1
		sustain_end.scale.y *= -1
	
	change_sustain_height(
	NoteGroup.get_sustain_height(length))

func get_sustain_size() -> float:
	return sustain.size.y + (58 + end_tex.margin.position.y)

func change_sustain_height(new:float):
	sustain.size.y = new - 58
	if new - 58 <= 0:
		end_tex.margin.position.y = new - 58
	
	if StrumGroup.player_strums[strum_data].downscroll:
		sustain_end.position.y = sustain.size.y - sustain.position.y
		sustain_end.position.y *= -1
	else:
		sustain_end.position.y = sustain.size.y + sustain.position.y
