@tool
class_name XML
extends Node

#region Editor
@export var texture:Texture2D = null
@export var loop:bool = false
@export var fps:int = 24

@export_tool_button("Convert", "PanelContainer")
var convert_action = xml_to_spriteframes
#endregion

func xml_to_spriteframes():
	if !texture:
		push_error("convert XML: texture is null")
		return
	
	var xml_path = texture.resource_path.left( # XML PATH BY TEXTURE PATH
	texture.resource_path.length() - 3) + "xml"
	if !FileAccess.file_exists(xml_path):
		push_error("convert XML: xml not found")
		return
	
	var parser = XMLParser.new()
	var err = parser.open(xml_path)
	if err != OK: # ERROR IN PARSER
		push_error("convert XML: parse error - %s" % err)
		return
	
	var spriteframes:SpriteFrames = SpriteFrames.new()
	spriteframes.remove_animation("default")
	
	while parser.read() != ERR_FILE_EOF: # READ AND CONVERT
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or parser.get_node_name(
		) != "SubTexture": continue
		
		var anim_name = parser.get_named_attribute_value("name")
		anim_name = anim_name.erase(anim_name.length()-4,6)
		
		var position = Vector2(
		parser.get_named_attribute_value("x").to_int(),
		parser.get_named_attribute_value("y").to_int())
		var size = Vector2(
		parser.get_named_attribute_value("width").to_int(),
		parser.get_named_attribute_value("height").to_int())
		
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(position, size)
		
		if !spriteframes.has_animation(anim_name):
			spriteframes.add_animation(anim_name)
			spriteframes.set_animation_speed(anim_name, fps)
			spriteframes.set_animation_loop(anim_name, loop)
		
		# ADD FRAME WITH MARGINS
		if parser.has_attribute("frameX"):
			var frame_position = Vector2(
			parser.get_named_attribute_value("frameX").to_int(),
			parser.get_named_attribute_value("frameY").to_int())
			var frame_size = Vector2(
			parser.get_named_attribute_value("frameWidth").to_int(),
			parser.get_named_attribute_value("frameHeight").to_int())
			
			var atlas_margin = Rect2(-frame_position, frame_size - size)
			
			if atlas_margin.size.x < abs(atlas_margin.position.x):
				atlas_margin.size.x = abs(atlas_margin.position.x)
			if atlas_margin.size.y < abs(atlas_margin.position.y):
				atlas_margin.size.y = abs(atlas_margin.position.y)
			
			atlas.margin = atlas_margin
			spriteframes.add_frame(anim_name, atlas)
		# ADD FRAME WITHOUT MARGIN
		else: spriteframes.add_frame(anim_name, atlas)
	
	# ON FINISHED
	var anim_path = texture.resource_path.left(
	texture.resource_path.length() - 3) + "tres"
	ResourceSaver.save(spriteframes, anim_path)
	print("Salved! in %s" % anim_path)

static func get_frames_dict() -> Dictionary:
	return {}
