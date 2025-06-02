extends AnimatedSprite2D
class_name Character

var character:String = "bf"

var is_player:bool = false
var is_girlfriend:bool = false

var data:CharacterData = null

var special_anim:bool = false
var dance_idle:bool = false # For "danceLeft" and "danceRight"

var hold_time:float = 0.0
var is_holding:bool = false

var camera_offset:Vector2 = Vector2(0, 0)

var dance_beat_num:int = 2

func _ready():
	connect("frame_changed", check_frame_rotation)
	connect("animation_changed", check_frame_rotation)

func check_frame_rotation():
	if !data: return
	
	if data.rotated_frames.has(animation) \
	and frame + 1 in data.rotated_frames[animation]:
		rotation = deg_to_rad(-90.0)
		scale.x = -data.scale.x
		flip_h = true
	else:
		rotation = deg_to_rad(0.0)
		scale.x = data.scale.x
		flip_h = false

func _process(delta):
	if !data: return
	
	if animation.begins_with(Util.SING_ANIM_ID) \
	and !is_holding: hold_time += delta
	else: hold_time = 0.0
	
	if hold_time > Conductor.beat_step * data.sing_duration:
		dance()
		hold_time = 0.0

func load_character(char:String, player:bool):
	var char_path:String = "res://assets/data/characters/%s.json" % char
	var res_path:String = "res://assets/data/characters/%s.tres" % char
	
	if FileAccess.file_exists(char_path):
		data = CharacterData.convert_to_bend_from_psych(char_path)
	elif FileAccess.file_exists(res_path):
		data = ResourceLoader.load(
			res_path, "Resource",
			ResourceLoader.CACHE_MODE_IGNORE)
	else:
		print_debug("Character: %s not exists - Loading Placeholder..." % char)
		data = ResourceLoader.load(
			"res://assets/data/characters/placeholder.tres", "Resource", 
			ResourceLoader.CACHE_MODE_IGNORE)
	
	is_player = player
	character = char
	
	if name == "Girlfriend":
		is_girlfriend = true
	
	position += data.position
	sprite_frames = data.sprites
	scale = data.scale
	flip_h = (data.flip_x != is_player)
	
	if sprite_frames.has_animation("danceLeft") \
	and sprite_frames.has_animation("danceRight"):
		dance_idle = true
	else:
		dance_idle = false
	
	if dance_idle:
		dance_beat_num = 1
	else:
		dance_beat_num = 2
	dance()

var danced:bool = false
func dance():
	if special_anim: return
	
	if dance_idle:
		danced = !danced
		if danced:
			play_anim("danceLeft")
		else:
			play_anim("danceRight")
	else:
		play_anim("idle")

func play_anim(anim:String):
	if !sprite_frames: return
	
	if sprite_frames.has_animation(anim):
		stop()
		play(anim)
		
		offset = -data.offsets[anim]
		
		if !is_player:
			offset.x *= -1
		
		if is_girlfriend:
			if anim == "singLEFT":
				danced = true
			elif anim == "singRIGHT":
				danced = false
			elif anim == "singUP" or anim == "singDOWN":
				danced = !danced
	else:
		print_debug("{0} not has animation {1}".format([ character, anim ]))

func get_mid_point() -> Vector2:
	if sprite_frames.has_animation("idle"):
		return sprite_frames.get_frame_texture(
			"idle", 0).get_size() / Vector2(2.0, 2.0)
	
	if sprite_frames.has_animation("danceLeft"):
		return sprite_frames.get_frame_texture(
			"danceLeft", 0).get_size() / Vector2(2.0, 2.0
			)
	
	return sprite_frames.get_frame_texture(
		sprite_frames.get_animation_names()[0], 
			0).get_size() / Vector2(2.0, 2.0)
