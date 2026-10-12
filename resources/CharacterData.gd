extends Resource
class_name CharacterData

const IMPORTER_VERSION:int = 1
static var _runtime_cache:Dictionary[String, CharacterData] = {}

@export var importer_version:int = 0

@export var image_path:String = ""
@export var scale:Vector2 = Vector2.ONE
@export var flip_x:bool = false
@export var position:Vector2 = Vector2.ZERO
@export var camera_position:Vector2 = Vector2.ZERO

@export var animations:Array = []
@export var sprites:SpriteFrames = null
@export var offsets:Dictionary[String, Vector2] = {}
@export var sprite_map_path:String = ""
@export var sprite_map_animations:Array = []

@export var sing_duration:float = 8.0
@export var dance_every:float = 1.0

@export var health_icon:String = "face"
@export var health_color:Color = Color(1, 0, 0)

static func load_character_data(character_name:String) -> CharacterData:
	if _runtime_cache.has(character_name):
		return _runtime_cache[character_name]

	var json_path := "res://assets/data/characters/%s.json" % character_name
	var result:CharacterData = null
	if FileAccess.file_exists(json_path):
		result = convert_to_fnf_base(json_path)

	if result != null:
		_runtime_cache[character_name] = result
	return result

static func clear_runtime_cache() -> void:
	_runtime_cache.clear()

static func convert_to_fnf_base(path:String) -> CharacterData:
	var json = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(json.get_as_text()) as Dictionary
	json.close()
	
	var res:CharacterData = CharacterData.new()
	res.importer_version = IMPORTER_VERSION
	
	var anim_path:String = _resolve_asset_path(data["assetPath"])
	
	res.image_path = anim_path
	if data.get("renderType", "") in ["animateatlas", "multianimateatlas"]:
		res.sprite_map_path = anim_path
		res.sprite_map_animations = data.get("animations", [])
	
	if data.has("offsets"):
		res.position = Vector2(data["offsets"][0], data["offsets"][1])
	
	if data.has("scale"):
		res.scale = Vector2(data["scale"], data["scale"])
	
	if data.has("flipX"):
		res.flip_x = data["flipX"]
	
	if data.has("singTime"):
		res.sing_duration = float(data["singTime"])
	if data.has("danceEvery"):
		res.dance_every = float(data["danceEvery"])
	
	if data.has("healthIcon"):
		res.health_icon = data["healthIcon"]["id"]
	
	# ANIMATIONS
	res.sprites = SpriteFrames.new()
	
	for anim in data["animations"]:
		if anim.has("offsets"):
			res.offsets[anim["name"]] = Vector2(anim["offsets"][0], anim["offsets"][1])
		if res.sprite_map_path != "" and anim.get("renderType", "") != "sparrow":
			continue
		
		var asset_path:String = res.image_path
		if anim.has("assetPath"):
			asset_path = _resolve_asset_path(anim["assetPath"])
		
		var frame_indices:Array = []
		if anim.has("frameIndices"): frame_indices = anim["frameIndices"]
		
		var looped:bool = false
		if anim.has("looped"): looped = anim["looped"]
		
		var framerate:int = 24
		if anim.has("frameRate"): framerate = anim["frameRate"]
		
		# LOADING
		if frame_indices: XML.add_by_indices(
				res.sprites, asset_path, anim["name"],
				anim["prefix"], frame_indices, framerate, looped
		)
		else: XML.add_by_prefix(
				res.sprites, asset_path, anim["name"],
				anim["prefix"], framerate, looped
		)
		
		# OFFSETS
		if !res.offsets.has(anim["name"]):
			res.offsets[anim["name"]] = Vector2.ZERO
		
		# ANIMATIONS
		res.animations.append({
			"name": anim["name"],
			"assetPath": asset_path,
			"prefix": anim["prefix"],
			"fps": framerate,
			"loop": looped,
			"indices": frame_indices
		})
	
	return res

static func _resolve_asset_path(asset_path:String) -> String:
	if asset_path.begins_with("res://"):
		return asset_path
	var relative_path:String = asset_path
	if asset_path.begins_with("shared:"):
		relative_path = asset_path.trim_prefix("shared:")

	# FNF Base uses the shared: namespace for the shipped asset library.
	var candidates:Array[String] = [
		"res://assets/shared/images/" + relative_path,
		"res://assets/shared/images/characters/" + relative_path,
		"res://assets/shared/images/characters/" + relative_path.trim_prefix("characters/"),
		"res://assets/images/" + relative_path,
		"res://assets/images/characters/" + relative_path,
		"res://assets/images/characters/" + relative_path.trim_prefix("characters/")
	]
	for candidate:String in candidates:
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(candidate)) \
		or FileAccess.file_exists(candidate + ".png") \
		or FileAccess.file_exists(candidate + ".xml"):
			return candidate
	return candidates[0]
