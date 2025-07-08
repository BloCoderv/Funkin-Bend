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

@export var sing_duration:int = 4

@export var health_icon:String = "face"
@export var health_color:Color = Color(1, 0, 0)

static func convert_to_bend_from_psych(path:String) -> CharacterData:
	## PSYCH ENGINE 0.7.3
	
	var json = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text()) as Dictionary
	json.close()

	var res = CharacterData.new()
	
	if data.has("assetPath") \
	or data.has("name") \
	or data.has("version"):
		return convert_to_bend(path)
	
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
		if anim["indices"]: XML.add_by_indices(
				res.sprites, anim_path, anim["anim"],
				anim["name"], anim["indices"], anim["fps"], anim["loop"]
		)
		else: XML.add_by_prefix(
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
	
	if data.has("offsets"):
		res.position = Vector2(data["offsets"][0], data["offsets"][1])
	
	if data.has("scale"):
		res.scale = Vector2(data["scale"], data["scale"])
	
	if data.has("flipX"):
		res.flip_x = data["flipX"]
	
	if data.has("singTime"):
		res.sing_duration = data["singTime"]
	
	if data.has("healthIcon"):
		res.health_icon = data["healthIcon"]["id"]
	
	# ANIMATIONS
	res.sprites = SpriteFrames.new()
	
	for anim in data["animations"]:
		
		var asset_path:String = res.image_path
		if anim.has("assetPath"):
			asset_path = "res://assets/images/" + anim["assetPath"]
		
		var frame_indices:Array = []
		if anim.has("frameIndices"): frame_indices = anim["frameIndices"]
		
		var looped:bool = false
		if anim.has("looped"): looped = anim["looped"]
		
		var framerate:int = 24
		if anim.has("frameRate"): framerate = anim["frameRate"]
		
		# LOADING
		if frame_indices: XML.add_by_indices(
				res.sprites, anim_path, anim["name"],
				anim["prefix"], frame_indices, framerate, looped
		)
		else: XML.add_by_prefix(
				res.sprites, anim_path, anim["name"],
				anim["prefix"], framerate, looped
		)
		
		# OFFSETS
		res.offsets[ anim["name"] ] = Vector2(
			anim["offsets"][0], anim["offsets"][1]
		)
		
		# ANIMATIONS
		res.animations.append({
			"name": anim["name"],
			"assetPath": asset_path,
			"prefix": anim["prefix"],
			"fps": framerate,
			"loop": looped,
			"indices": frame_indices
		})
	
	ResourceSaver.save(res, path.get_basename() + ".tres")
	data = null
	var err = DirAccess.remove_absolute(path)
	if err:
		printerr("CharacterData - convert json - remove error: " + err)
		return
	
	return res
