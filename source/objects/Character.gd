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

var dance_beat_num:int = 2

func _process(delta):
	if !data: return
	
	if animation.begins_with(Util.SING_ANIM_ID) \
	and !is_holding: hold_time += delta
	else: hold_time = 0.0
	
	if hold_time > Conductor.beat_step * data.sing_duration:
		dance()
		hold_time = 0.0

func load_character(char:String, player:bool):
	var path:String = "res://assets/data/characters/" + char
	if FileAccess.file_exists(path + ".json"):
		data = CharacterData.convert_from_json(path + ".json", path)
	elif FileAccess.file_exists(path + ".tres"):
		data = ResourceLoader.load(
			path + ".tres", "Resource", 
			ResourceLoader.CACHE_MODE_IGNORE)
	else:
		OS.alert("Character not exists", "Loading Placeholder")
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
	return sprite_frames.get_frame_texture(
		sprite_frames.get_animation_names()[0], 
			0).get_size() / Vector2(2.0, 2.0)
