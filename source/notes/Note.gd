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
var is_sustain:bool = false
var can_hit:bool = false
var too_late:bool = false
var is_holding:bool = false

var pivot:Vector2 = Vector2.ZERO # pivot in middle

var texture_size:Vector2 = Vector2.ZERO
var end_tex:AtlasTexture = null

func _ready():
	texture = Global.NOTES.get_frame_texture(str(strum_data), 0)
	
	if !Preferences.opponent_notes \
	and StrumGroup.strum_notes[data].opponent: texture = null
	
	if texture:
		scale = StrumGroup.strum_notes[data].scale
		texture_size = texture.get_size() * scale
		pivot = -texture_size / 2
	
	if !is_sustain:
		sustain.queue_free()
		sustain_end.queue_free()
	else: setup_sustain()

func setup_sustain() -> void:
	var textures:Array = [null, null]
	if texture: 
		textures = Global.get_hold_textures(strum_data)
		
		sustain.texture = textures[0]
		sustain.size.x = sustain.texture.get_size().x
	
	if Preferences.sustain_behind_strum:
		sustain.z_index = -2
		sustain.show_behind_parent = true
		sustain_end.z_index = -2
		sustain_end.show_behind_parent = true
	
	# SUSTAIN END
	end_tex = AtlasTexture.new()
	end_tex.atlas = textures[1]
	sustain_end.texture = end_tex
	
	change_sustain_height(
	NoteGroup.get_sustain_height(length))

func get_sustain_size() -> float:
	return sustain.size.y + (58 + end_tex.margin.position.y)

func change_sustain_height(new:float):
	sustain.size.y = new - 58
	if new - 58 <= 0:
		end_tex.margin.position.y = new - 58
	
	if StrumGroup.strum_notes[data].downscroll:
		sustain.scale.y = -1
		sustain_end.scale.y = -1
		
		sustain_end.position.y = sustain.size.y - sustain.position.y
		sustain_end.position.y *= -1
	else:
		sustain.scale.y = 1
		sustain_end.scale.y = 1
		
		sustain_end.position.y = sustain.size.y + sustain.position.y
