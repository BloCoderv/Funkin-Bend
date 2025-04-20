extends Resource
class_name CharacterData

@export var image:String = ""
@export var scale:Vector2 = Vector2.ONE
@export var flip_x:bool = false
@export var position:Vector2 = Vector2.ZERO

@export var animations:Array = []

@export var health_icon:String = "face"
@export var health_color:Color = Color(1, 0, 0)

static func convert_from_json(path:String, save_to:String) -> CharacterData:
	# CONVERT FROM PSYCH ENGINE 0.7.3
	var json = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text()) as Dictionary
	json.close()
	
	var res:CharacterData = null
	if !FileAccess.file_exists(save_to + ".tres"):
		res = CharacterData.new()
	else:
		res = ResourceLoader.load(save_to + ".tres", "Resource", ResourceLoader.CACHE_MODE_IGNORE)
		var err = DirAccess.remove_absolute(save_to + ".tres")
		if err:
			OS.alert("CharacterData - convert json - remove error: " + err)
			return
	
	res.image = data["image"]
	res.scale = Vector2(data["scale"], data["scale"])
	res.flip_x = data["flip_x"]
	
	res.health_icon = data["healthicon"]
	
	var colors:Array = data["healthbar_colors"]
	res.health_color = Color(
		colors[0] / 255.0,
		colors[0] / 255.0,
		colors[0] / 255.0)
	
	res.animations = data["animations"]
	
	ResourceSaver.save(res, save_to + ".tres")
	data = null
	var err = DirAccess.remove_absolute(save_to + ".json")
	if err:
		OS.alert("CharacterData - convert json - remove error: " + err)
		return
	
	return res
