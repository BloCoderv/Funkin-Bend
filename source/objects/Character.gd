extends AnimatedSprite2D
class_name Character

var character:String = "bf"
var is_player:bool = false
var data:CharacterData = null

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
		OS.alert("load error - char not exists", "CHARACTER ERROR")
		data = CharacterData.new()
