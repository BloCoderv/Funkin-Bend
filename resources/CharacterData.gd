extends Resource
class_name CharacterData

@export var image_path:String = ""
@export var scale:Vector2 = Vector2.ONE
@export var flip_x:bool = false
@export var position:Vector2 = Vector2.ZERO
@export var camera_position:Vector2 = Vector2.ZERO

@export var animations:Array = []
@export var sprites:SpriteFrames = null
@export var offsets:Dictionary[String, Vector2] = {}
@export var rotated_frames:Dictionary[String, Array] = {}

@export var sing_duration:int = 4

@export var health_icon:String = "face"
@export var health_color:Color = Color(1, 0, 0)

static func convert_to_bend_from_psych(path:String) -> CharacterData:
	## PSYCH ENGINE 0.7.3
	
	var json = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text()) as Dictionary
	json.close()

	var res = CharacterData.new()
	
	var anim_path:String = "res://assets/images/" + data["image"]
	
	res.image_path = anim_path
	res.scale = Vector2(data["scale"], data["scale"])
	res.flip_x = data["flip_x"]
	res.sing_duration = data["sing_duration"]
	
	res.position = Vector2(
		data["position"][0], data["position"][1]
	)
	res.camera_position = Vector2(
		data["camera_position"][0],
		data["camera_position"][1]
	)
	
	res.health_icon = data["healthicon"]
	
	var colors:Array = data["healthbar_colors"]
	res.health_color = Color(
		colors[0] / 255.0,
		colors[1] / 255.0,
		colors[2] / 255.0
	)
	
	# ANIMATIONS
	res.sprites = SpriteFrames.new()
	
	for anim in data["animations"]:
		# LOADING
		if anim["indices"]:
			res.rotated_frames[anim["anim"]] = XML.add_by_indices(
				res.sprites, anim_path, anim["anim"],
				anim["name"], anim["indices"], anim["fps"], anim["loop"]
			)
		else:
			res.rotated_frames[anim["anim"]] = XML.add_by_prefix(
				res.sprites, anim_path, anim["anim"],
				anim["name"], anim["fps"], anim["loop"]
			)
		
		
		
		# OFFSETS
		res.offsets[ anim["anim"] ] = Vector2(
			anim["offsets"][0], anim["offsets"][1]
		)
		
		# ANIMATIONS
		res.animations.append({
			"name": anim["anim"],
			"prefix": anim["name"],
			"fps": anim["fps"],
			"loop": anim["loop"],
			"indices": anim["indices"]
		})
	
	ResourceSaver.save(res, path.get_basename() + ".tres")
	data = null
	var err = DirAccess.remove_absolute(path)
	if err:
		printerr("CharacterData - convert json - remove error: " + err)
		return
	
	return res

static func convert_to_bend(path:String) -> CharacterData:
	var json = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text()) as Dictionary
	json.close()
	
	var res:CharacterData = CharacterData.new()
	
	var anim_path:String = "res://assets/images/" + data["assetPath"]
	
	res.image_path = anim_path
	res.scale = Vector2(data["scale"], data["scale"])
	res.flip_x = data["flip_x"]
	res.sing_duration = data["singTime"]
	
	res.position = Vector2(
		data["position"][0], data["position"][1]
	)
	res.camera_position = Vector2(
		data["camera_position"][0],
		data["camera_position"][1]
	)
	
	res.health_icon = data["healthicon"]
	
	var colors:Array = data["healthbar_colors"]
	res.health_color = Color(
		colors[0] / 255.0,
		colors[1] / 255.0,
		colors[2] / 255.0
	)
	
	# ANIMATIONS
	res.sprites = SpriteFrames.new()
	
	for anim in data["animations"]:
		# LOADING
		if anim["indices"]:
			res.rotated_frames[anim["anim"]] = XML.add_by_indices(
				res.sprites, anim_path, anim["anim"],
				anim["name"], anim["indices"], anim["fps"], anim["loop"]
			)
		else:
			res.rotated_frames[anim["anim"]] = XML.add_by_prefix(
				res.sprites, anim_path, anim["anim"],
				anim["name"], anim["fps"], anim["loop"]
			)
		
		
		
		# OFFSETS
		res.offsets[ anim["anim"] ] = Vector2(
			anim["offsets"][0], anim["offsets"][1]
		)
		
		# ANIMATIONS
		res.animations.append({
			"name": anim["anim"],
			"prefix": anim["name"],
			"fps": anim["fps"],
			"loop": anim["loop"],
			"indices": anim["indices"]
		})
	
	ResourceSaver.save(res, path.get_basename() + ".tres")
	data = null
	var err = DirAccess.remove_absolute(path)
	if err:
		printerr("CharacterData - convert json - remove error: " + err)
		return
	
	return res
