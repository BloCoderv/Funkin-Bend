extends AnimatedSprite2D
class_name XMLSprite

## Reusable runtime XML/PNG sprite. Call load_xml_animation() for each
## animation; the atlas itself is shared by XML.get_atlas_frames().
func load_xml_animation(path:String, animation_name:String, prefix:String,
	fps:int = 24, loop:bool = false, indices:Array = []) -> bool:
	var frames:SpriteFrames = sprite_frames
	if frames == null:
		frames = SpriteFrames.new()
		sprite_frames = frames
	if indices.is_empty():
		XML.add_by_prefix(frames, path, animation_name, prefix, fps, loop)
	else:
		XML.add_by_indices(frames, path, animation_name, prefix, indices, fps, loop)
	return frames.has_animation(animation_name) and frames.get_frame_count(animation_name) > 0
