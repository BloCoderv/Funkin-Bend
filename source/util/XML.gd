@tool
class_name XML
extends Node

## Runtime XML atlas loader. It keeps the PNG/AtlasTexture frames in memory and
## Builds SpriteFrames at runtime from the FNF atlas source files.
## is required by the game, and each XML/PNG pair is parsed only once.
static var _atlas_cache:Dictionary = {}

@export var texture:Texture2D = null
@export var loop:bool = false
@export var fps:int = 24

@export_tool_button("Convert", "PanelContainer")
var convert_action = xml_to_spriteframes

func xml_to_spriteframes() -> void:
	if !texture:
		push_error("XML: texture is null")
		return
	var frames:Dictionary = get_atlas_frames(texture.resource_path.get_basename())
	var spriteframes:SpriteFrames = SpriteFrames.new()
	for frame_name:String in frames:
		if !spriteframes.has_animation("default"):
			spriteframes.add_animation("default")
		spriteframes.set_animation_speed("default", fps)
		spriteframes.set_animation_loop("default", loop)
		spriteframes.add_frame("default", frames[frame_name])
	# SpriteFrames are built at runtime; FNF assets remain source PNG/XML files.

static func get_xml_parser(path_xml:String) -> XMLParser:
	if !FileAccess.file_exists(path_xml):
		push_error("XML: file not found: %s" % path_xml)
		return null
	var parser:XMLParser = XMLParser.new()
	if parser.open(path_xml) != OK:
		push_error("XML: could not parse %s" % path_xml)
		return null
	return parser

static func get_atlas_frames(path:String) -> Dictionary:
	if _atlas_cache.has(path):
		return _atlas_cache[path]
	var image:Texture2D = load(path + ".png")
	var parser:XMLParser = get_xml_parser(path + ".xml")
	var result:Dictionary = {}
	if image == null or parser == null:
		return result
	var image_data:Image = image.get_image()
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT \
		or parser.get_node_name() != "SubTexture":
			continue
		var frame_name:String = parser.get_named_attribute_value("name")
		result[frame_name] = get_frame_from_parser(parser, image, image_data)
	_atlas_cache[path] = result
	return result

static func _attribute_int(parser:XMLParser, attribute:String, default_value:int) -> int:
	if !parser.has_attribute(attribute):
		return default_value
	return parser.get_named_attribute_value(attribute).to_int()

static func get_frame_from_parser(parser:XMLParser, image:Texture2D, image_data:Image) -> AtlasTexture:
	var position:Vector2 = Vector2(
		_attribute_int(parser, "x", 0),
		_attribute_int(parser, "y", 0))
	var size:Vector2 = Vector2(
		_attribute_int(parser, "width", 0),
		_attribute_int(parser, "height", 0))
	var logical_size:Vector2 = size
	var rotation_value:String = ""
	if parser.has_attribute("rotated"):
		rotation_value = parser.get_named_attribute_value("rotated")
	elif parser.has_attribute("rotate"):
		rotation_value = parser.get_named_attribute_value("rotate")
	var frame:AtlasTexture = AtlasTexture.new()
	if rotation_value.to_lower() in ["true", "1"]:
		var rotated_image:Image = image_data.get_region(Rect2(position, size))
		rotated_image.rotate_90(COUNTERCLOCKWISE)
		frame.atlas = ImageTexture.create_from_image(rotated_image)
		frame.region = Rect2(Vector2.ZERO, rotated_image.get_size())
		logical_size = frame.region.size
	else:
		frame.atlas = image
		frame.region = Rect2(position, size)
	frame.filter_clip = true
	if parser.has_attribute("frameX"):
		var frame_position:Vector2 = Vector2(
			_attribute_int(parser, "frameX", 0),
			_attribute_int(parser, "frameY", 0))
		var frame_size:Vector2 = Vector2(
			_attribute_int(parser, "frameWidth", int(logical_size.x)),
			_attribute_int(parser, "frameHeight", int(logical_size.y)))
		# A margem usa o tamanho logico depois de desfazer rotated; width/height sao do recorte no atlas.
		frame.margin = Rect2(-frame_position, frame_size - logical_size)
	return frame

static func _frame_prefix(frame_name:String) -> String:
	if frame_name.length() >= 4:
		return frame_name.substr(0, frame_name.length() - 4)
	return frame_name

static func _frame_index(frame_name:String) -> int:
	if frame_name.length() < 4:
		return 0
	return frame_name.substr(frame_name.length() - 4).to_int()

static func _prepare_animation(spriteframes:SpriteFrames, anim_name:String, fps:int, loop:bool) -> void:
	if !spriteframes.has_animation(anim_name):
		spriteframes.add_animation(anim_name)
	spriteframes.set_animation_speed(anim_name, fps)
	spriteframes.set_animation_loop(anim_name, loop)

static func add_by_indices(spriteframes:SpriteFrames, path:String, anim_name:String,
	prefix:String, indices:Array, fps:int = 24, loop:bool = false) -> void:
	var frames:Dictionary = get_atlas_frames(path)
	_prepare_animation(spriteframes, anim_name, fps, loop)
	var indexed_frames:Dictionary = {}
	for frame_name:String in frames:
		if _frame_prefix(frame_name).begins_with(prefix):
			indexed_frames[_frame_index(frame_name)] = frames[frame_name]
	for index in indices:
		var frame_index:int = int(index)
		if indexed_frames.has(frame_index):
			spriteframes.add_frame(anim_name, indexed_frames[frame_index])

static func add_by_prefix(spriteframes:SpriteFrames, path:String, anim_name:String,
	prefix:String, fps:int = 24, loop:bool = false) -> void:
	if path.is_empty() or prefix.is_empty():
		return
	var frames:Dictionary = get_atlas_frames(path)
	_prepare_animation(spriteframes, anim_name, fps, loop)
	var matching_names:Array[String] = []
	var normalized_prefix := prefix.trim_suffix("0")
	for frame_name:String in frames:
		if _frame_prefix(frame_name).begins_with(prefix) \
		or (!normalized_prefix.is_empty() and _frame_prefix(frame_name).begins_with(normalized_prefix)):
			matching_names.append(frame_name)
	matching_names.sort()
	for frame_name:String in matching_names:
		spriteframes.add_frame(anim_name, frames[frame_name])

static func build_spriteframes(path:String, definitions:Array, fps:float = 24.0) -> SpriteFrames:
	var result := SpriteFrames.new()
	for definition in definitions:
		var looped:bool = bool(definition[2]) if definition.size() > 2 else false
		add_by_prefix(result, path, str(definition[0]), str(definition[1]), int(fps), looped)
	return result
