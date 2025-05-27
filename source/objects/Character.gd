extends AnimatedSprite2D
class_name Character

var character:String = "bf"

var is_player:bool = false
var is_girlfriend:bool = false

var data:CharacterData = null

var special_anim:bool = false
var dance_idle:bool = false # For "danceLeft" and "danceRight"

var hold_time:float = 0.0
var is_singing:bool = false

var dance_beat_num:int = 2

func _process(delta):
	if !data: return
	
	if is_singing: hold_time += delta
	
	if hold_time >= Conductor.beat_step * 0.0011 * data.sing_duration:
		if !is_player or !is_singing: # or player is pressing
			is_singing = false
			hold_time = 0.0
			dance()

func load_character(char:String, player:bool):
	is_player = player
	character = char
	
	var path:String = "res://assets/data/characters/" + char
	if FileAccess.file_exists(path + ".json"):
		data = CharacterData.convert_from_json(path + ".json", path)
	elif FileAccess.file_exists(path + ".tres"):
		data = ResourceLoader.load(
			path + ".tres", "Resource", 
			ResourceLoader.CACHE_MODE_IGNORE)
	else:
		OS.alert("Character not exists", "Loading Character")
		data = CharacterData.new()
		return
	
	sprite_frames = data.sprites
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

func play_anim(name:String):
	if !sprite_frames: return
	
	if sprite_frames.has_animation(name):
		play(name)
		offset = data.offsets[name]
		
		if is_girlfriend:
			if name == "singLEFT":
				danced = true
			elif name == "singRIGHT":
				danced = false
			elif name == "singUP" or name == "singDOWN":
				danced = !danced
	else:
		print_debug("{0} not has animation {1}".format([ character, name ]))
