class_name SpriteMap
extends Node2D

signal bake_progress(value:float)
signal bake_finished

const CACHE_VERSION:int = 4
const CACHE_DIRECTORY:String = "user://cache/spritemaps"

static var _frames_cache:Dictionary = {}

## Runtime reader for Funkin' SpriteMap exports (spritemap1.json + Animation.json).
## It also understands the layered multianimateatlas export used by newer assets.

var atlas:Texture2D
var atlas_regions:Dictionary = {}
var symbols:Dictionary = {}
var timelines:Array = []
var source_animations:Dictionary = {}
var current_name:String = ""
var current_frame:int = -1
var frame_commands:Dictionary = {}
var sprite_pool:Array[Sprite2D] = []
var content_bounds:Rect2 = Rect2()
var content_offset:Vector2 = Vector2.ZERO
var baked_frames:Dictionary = {}
var baked_sprite:Sprite2D
var baking:bool = false
var bake_complete:bool = false
var animation_data:Array = []
var asset_key:String = ""
var cache_directory:String = ""
var cache_manifest_path:String = ""
var asset_dir:String = ""
var cache_loading:bool = false
var source_configured:bool = false
var cached_controller_frames:SpriteFrames = null
var baked_images:Dictionary = {}
var mirrored:bool = false
var draw_offset:Vector2 = Vector2.ZERO

func configure(asset_dir:String, animation_data:Array) -> void:
	self.animation_data = animation_data
	self.asset_dir = asset_dir
	asset_key = _make_asset_key(asset_dir)
	cache_directory = _get_cache_path(asset_key)
	cache_manifest_path = cache_directory.path_join("manifest.json")
	if _load_memory_cache():
		_setup_baked_sprite()
		return
	if FileAccess.file_exists(cache_manifest_path):
		cache_loading = true
		return
	_configure_source()

func _configure_source() -> void:
	source_configured = true
	atlas = load(asset_dir.path_join("spritemap1.png"))
	_load_atlas(asset_dir.path_join("spritemap1.json"))
	var animation_file := asset_dir.path_join("Animation.json")
	if FileAccess.file_exists(animation_file):
		var file := FileAccess.open(animation_file, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			var animation_root:Dictionary = parsed.get("AN", {})
			timelines = animation_root.get("TL", {}).get("L", [])
			var symbol_data:Array = parsed.get("SD", {}).get("S", [])
			for symbol in symbol_data:
				symbols[str(symbol.get("SN", ""))] = symbol.get("TL", {})
			_register_source_timelines()

	for animation in animation_data:
		var name := str(animation.get("name", ""))
		if name.is_empty():
			continue
		if animation.get("renderType", "") == "sparrow":
			continue
		var prefix := str(animation.get("prefix", name))
		var source:Dictionary = _find_source_animation(prefix)
		var indices:Array = animation.get("frameIndices", [])
		if !indices.is_empty():
			var label_frames:Array = source.get("frames", [])
			var selected_frames:Array[int] = []
			for index in indices:
				var frame_index := int(index)
				if frame_index >= 0 and frame_index < label_frames.size():
					selected_frames.append(int(label_frames[frame_index]))
			source["frames"] = selected_frames
			source["explicit"] = true
		source_animations[name] = source
	_calculate_content_bounds()
	_setup_baked_sprite()
	if _frames_cache.has(asset_key):
		var cached:Dictionary = _frames_cache[asset_key]
		content_bounds = cached["bounds"]
		cached_controller_frames = cached["frames"]
		bake_complete = true
		_setup_baked_sprite()

func start_bake() -> void:
	if !baking and !bake_complete:
		_bake_frames()

func prepare() -> void:
	if cache_loading:
		cache_loading = false
		if await _load_disk_cache():
			return
		_configure_source()
	if bake_complete:
		return
	if !baking:
		start_bake()
		await bake_finished

func set_animation_frame(animation_name:String, frame:int) -> void:
	if atlas == null or !source_animations.has(animation_name):
		return
	var source:Dictionary = source_animations[animation_name]
	var frames:Array = source.get("frames", [])
	if frames.is_empty():
		return
	var index:int = clampi(frame, 0, frames.size() - 1)
	var source_frame:int = int(frames[index])
	if current_name == animation_name and current_frame == source_frame:
		return
	current_name = animation_name
	current_frame = source_frame
	if baked_frames.has(source_frame):
		baked_sprite.texture = baked_frames[source_frame]
		baked_sprite.visible = true
		for sprite in sprite_pool:
			sprite.visible = false
		return
	baked_sprite.visible = false
	var commands:Array = frame_commands.get(source_frame, [])
	if commands.is_empty() and !frame_commands.has(source_frame):
		commands = []
		_collect_commands(timelines, source_frame, Transform2D.IDENTITY, commands)
		frame_commands[source_frame] = commands
	_apply_commands(commands)

func _bake_frames() -> void:
	if atlas == null or content_bounds.size.x <= 0.0 or baking:
		return
	baking = true
	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.size = Vector2i(ceili(content_bounds.size.x), ceili(content_bounds.size.y))
	add_child(viewport)
	var viewport_sprites:Array[Sprite2D] = []
	var unique_frames:Dictionary = {}
	for source in source_animations.values():
		for source_frame in source.get("frames", []):
			unique_frames[int(source_frame)] = true
	var frame_number:int = 0
	var total_frames:int = maxi(1, unique_frames.size())
	for source_frame in unique_frames:
		var commands:Array = frame_commands.get(int(source_frame), [])
		while viewport_sprites.size() < commands.size():
			var sprite := Sprite2D.new()
			sprite.centered = false
			viewport.add_child(sprite)
			viewport_sprites.append(sprite)
		for index in range(viewport_sprites.size()):
			var sprite:Sprite2D = viewport_sprites[index]
			if index >= commands.size():
				sprite.visible = false
				continue
			var command:Dictionary = commands[index]
			sprite.texture = atlas_regions[command["name"]]
			sprite.transform = Transform2D(0.0, -content_bounds.position) * command["transform"]
			sprite.visible = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		var image := viewport.get_texture().get_image()
		if image:
			baked_images[int(source_frame)] = image
			baked_frames[int(source_frame)] = ImageTexture.create_from_image(image)
		frame_number += 1
		# Reserve the last 10% for writing the incremental disk cache.
		bake_progress.emit(0.9 * float(frame_number) / float(total_frames))
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.queue_free()
	baking = false
	bake_complete = true
	cached_controller_frames = build_baked_frames()
	_frames_cache[asset_key] = {"frames": cached_controller_frames, "bounds": content_bounds}
	await _save_cached_frames()
	for sprite in sprite_pool:
		sprite.visible = false
	if baked_frames.has(current_frame):
		baked_sprite.texture = baked_frames[current_frame]
		baked_sprite.visible = true
	bake_finished.emit()

func _setup_baked_sprite() -> void:
	if baked_sprite != null:
		return
	baked_sprite = Sprite2D.new()
	baked_sprite.centered = false
	baked_sprite.position = Vector2.ZERO
	baked_sprite.visible = false
	add_child(baked_sprite)

func _make_asset_key(asset_dir:String) -> String:
	var files:Array[String] = [
		asset_dir.path_join("spritemap1.png"),
		asset_dir.path_join("spritemap1.json"),
		asset_dir.path_join("Animation.json")
	]
	var source_key:Array = [CACHE_VERSION, asset_dir, JSON.stringify(animation_data)]
	for file_path:String in files:
		source_key.append(FileAccess.get_modified_time(file_path))
		source_key.append(_get_file_size(file_path))
	return JSON.stringify(source_key)

func _get_file_size(file_path:String) -> int:
	if !FileAccess.file_exists(file_path):
		return 0
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return 0
	var size := file.get_length()
	file.close()
	return size

func _get_cache_path(key:String) -> String:
	return CACHE_DIRECTORY.path_join(str(absi(hash(key))))

func _load_memory_cache() -> bool:
	if _frames_cache.has(asset_key):
		var memory_cache:Dictionary = _frames_cache[asset_key]
		cached_controller_frames = memory_cache["frames"]
		content_bounds = memory_cache["bounds"]
		bake_complete = true
		return true
	return false

func _load_disk_cache() -> bool:
	var file := FileAccess.open(cache_manifest_path, FileAccess.READ)
	if file == null:
		return false
	var manifest = JSON.parse_string(file.get_as_text())
	file.close()
	if !(manifest is Dictionary) or int(manifest.get("version", 0)) != CACHE_VERSION:
		return false

	var bounds:Array = manifest.get("bounds", [])
	var serialized_sources:Dictionary = manifest.get("source_animations", {})
	if bounds.size() < 4 or serialized_sources.is_empty():
		return false
	content_bounds = Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3]))
	source_animations.clear()
	for animation_name in serialized_sources:
		var source:Dictionary = serialized_sources[animation_name]
		source_animations[str(animation_name)] = {
			"frames": source.get("frames", [])
		}

	var frame_ids:Array = manifest.get("frames", [])
	if frame_ids.is_empty():
		return false
	baked_frames.clear()
	var total_frames:int = frame_ids.size()
	for index in range(total_frames):
		var source_frame:int = int(frame_ids[index])
		var frame_path := cache_directory.path_join("frame_%s.png" % source_frame)
		var image := Image.new()
		if image.load(frame_path) != OK:
			return false
		baked_frames[source_frame] = ImageTexture.create_from_image(image)
		bake_progress.emit(float(index + 1) / float(total_frames))
		await get_tree().process_frame

	cached_controller_frames = build_baked_frames()
	_frames_cache[asset_key] = {"frames": cached_controller_frames, "bounds": content_bounds}
	bake_complete = true
	_setup_baked_sprite()
	bake_progress.emit(1.0)
	return true

func _save_cached_frames() -> void:
	if cached_controller_frames == null or baked_images.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_directory))
	var frame_ids:Array = baked_images.keys()
	frame_ids.sort()
	var total_frames:int = frame_ids.size()
	for index in range(total_frames):
		var source_frame:int = int(frame_ids[index])
		var image:Image = baked_images[source_frame]
		var frame_path := cache_directory.path_join("frame_%s.png" % source_frame)
		if image.save_png(frame_path) != OK:
			push_warning("SpriteMap: could not save cache frame %s" % source_frame)
			return
		bake_progress.emit(0.9 + (0.1 * float(index + 1) / float(total_frames)))
		await get_tree().process_frame

	var source_manifest:Dictionary = {}
	for animation_name in source_animations:
		var source:Dictionary = source_animations[animation_name]
		source_manifest[str(animation_name)] = {"frames": source.get("frames", [])}
	var manifest:Dictionary = {
		"version": CACHE_VERSION,
		"bounds": [content_bounds.position.x, content_bounds.position.y,
			content_bounds.size.x, content_bounds.size.y],
		"frames": frame_ids,
		"source_animations": source_manifest
	}
	var manifest_file := FileAccess.open(cache_manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		push_warning("SpriteMap: could not write cache manifest")
		return
	manifest_file.store_string(JSON.stringify(manifest))
	manifest_file.close()

func build_baked_frames() -> SpriteFrames:
	if cached_controller_frames != null:
		return cached_controller_frames
	var result := SpriteFrames.new()
	for animation in animation_data:
		var name := str(animation.get("name", ""))
		if name.is_empty() or animation.get("renderType", "") == "sparrow":
			continue
		if !source_animations.has(name):
			continue
		result.add_animation(name)
		result.set_animation_speed(name, float(animation.get("frameRate", 24)))
		result.set_animation_loop(name, bool(animation.get("looped", false)))
		var source:Dictionary = source_animations[name]
		for source_frame in source.get("frames", []):
			var texture:Texture2D = baked_frames.get(int(source_frame))
			if texture != null:
				result.add_frame(name, texture)
	return result

func get_animation_length(animation_name:String) -> int:
	if !source_animations.has(animation_name):
		return 1
	return maxi(1, source_animations[animation_name].get("frames", []).size())

func get_mid_point() -> Vector2:
	return content_bounds.size * 0.5

func get_content_size() -> Vector2:
	return content_bounds.size

func build_controller_frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var blank := ImageTexture.create_from_image(image)
	for animation_name in source_animations:
		var name := str(animation_name)
		result.add_animation(name)
		result.set_animation_speed(name, 24.0)
		result.set_animation_loop(name, true)
		for index in get_animation_length(name):
			result.add_frame(name, blank)
	return result

func _load_atlas(path:String) -> void:
	if !FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	for entry in parsed.get("ATLAS", {}).get("SPRITES", []):
		var sprite:Dictionary = entry.get("SPRITE", {})
		var name := str(sprite.get("name", ""))
		var region := AtlasTexture.new()
		var rect := Rect2(float(sprite.get("x", 0)), float(sprite.get("y", 0)),
			float(sprite.get("w", 0)), float(sprite.get("h", 0)))
		if sprite.get("rotated", false):
			var rotated := atlas.get_image().get_region(rect)
			rotated.rotate_90(COUNTERCLOCKWISE)
			region.atlas = ImageTexture.create_from_image(rotated)
			region.region = Rect2(Vector2.ZERO, rotated.get_size())
		else:
			region.atlas = atlas
			region.region = rect
		region.filter_clip = true
		atlas_regions[name] = region

func set_mirror(mirrored:bool) -> void:
	self.mirrored = mirrored
	_update_draw_position()

func set_draw_offset(draw_offset:Vector2) -> void:
	self.draw_offset = draw_offset
	_update_draw_position()

func _update_draw_position() -> void:
	scale.x = -1.0 if mirrored else 1.0
	position.x = content_bounds.size.x - content_bounds.position.x \
		if mirrored else -content_bounds.position.x
	position.y = -content_bounds.position.y
	position += draw_offset

func _register_source_timelines() -> void:
	for entry in timelines:
		for marker in entry.get("FR", []):
			if !marker.has("N"):
				continue
			var start := int(marker.get("I", 0))
			var duration := maxi(1, int(marker.get("DU", 1)))
			var frames:Array[int] = []
			for frame in range(start, start + duration):
				frames.append(frame)
			source_animations[str(marker["N"])] = {"frames": frames}

func _find_source_animation(prefix:String) -> Dictionary:
	for key in source_animations:
		if str(key).to_lower() == prefix.to_lower():
			return source_animations[key].duplicate(true)
	for key in source_animations:
		if str(key).to_lower().begins_with(prefix.to_lower()):
			return source_animations[key].duplicate(true)
	# Never substitute frame 0 for a missing animation. That silently renders
	# the default pose behind miss/death animations and creates a visible clone.
	return {"frames": []}

func _collect_commands(layers:Array, frame:int, parent_transform:Transform2D, commands:Array) -> void:
	# Animate exports the timeline layers in the opposite order from Godot's
	# child draw order. The last child is drawn on top, so walk the layers
	# backwards to preserve the original front/back composition.
	for layer_index in range(layers.size() - 1, -1, -1):
		var layer:Dictionary = layers[layer_index]
		var layer_frames:Array = layer.get("FR", [])
		var keyframe:Dictionary = _keyframe_at(layer_frames, frame)
		var keyframe_start:int = _keyframe_start(layer_frames, frame)
		for event in keyframe.get("E", []):
			if event.has("ASI"):
				var instance:Dictionary = event["ASI"]
				var texture = atlas_regions.get(str(instance.get("N", "")))
				if texture != null:
					commands.append({
						"name": str(instance.get("N", "")),
						"transform": parent_transform * _event_transform(instance.get("MX", [1, 0, 0, 1, 0, 0]))
					})
			elif event.has("SI"):
				var instance:Dictionary = event["SI"]
				var symbol_timeline:Array = symbols.get(str(instance.get("SN", "")), {}).get("L", [])
				if symbol_timeline.is_empty():
					continue
				var symbol_length := _timeline_length(symbol_timeline)
				var symbol_frame := _get_symbol_frame(instance, frame - keyframe_start, symbol_length)
				_collect_commands(symbol_timeline, symbol_frame,
					parent_transform * _event_transform(instance.get("MX", [1, 0, 0, 1, 0, 0])), commands)

func _keyframe_at(frames:Array, frame:int) -> Dictionary:
	var selected:Dictionary = {}
	for item in frames:
		var start := int(item.get("I", 0))
		if start <= frame:
			selected = item
		else:
			break
	return selected

func _keyframe_start(frames:Array, frame:int) -> int:
	var start:int = 0
	for item in frames:
		var item_start := int(item.get("I", 0))
		if item_start <= frame:
			start = item_start
		else:
			break
	return start

func _get_symbol_frame(instance:Dictionary, elapsed:int, timeline_length:int) -> int:
	var first_frame:int = int(instance.get("FF", 0))
	var last_frame:int = int(instance.get("LF", -1))
	var loop_type:String = str(instance.get("LP", "LP"))
	var last_index:int = maxi(0, timeline_length - 1)
	if loop_type in ["SF", "singleframe"]:
		return clampi(first_frame, 0, last_index)
	if last_frame >= first_frame:
		var length:int = mini(last_frame, last_index) - first_frame + 1
		if loop_type in ["PO", "playonce"]:
			return clampi(first_frame + elapsed, first_frame, first_frame + length - 1)
		return first_frame + posmod(elapsed, maxi(1, length))
	var frame:int = first_frame + elapsed
	if loop_type in ["PO", "playonce"]:
		return clampi(frame, 0, last_index)
	return posmod(frame, timeline_length)

func _apply_commands(commands:Array) -> void:
	while sprite_pool.size() < commands.size():
		var sprite := Sprite2D.new()
		sprite.centered = false
		add_child(sprite)
		sprite_pool.append(sprite)
	for index in range(sprite_pool.size()):
		var sprite:Sprite2D = sprite_pool[index]
		if index >= commands.size():
			sprite.visible = false
			continue
		var command:Dictionary = commands[index]
		sprite.texture = atlas_regions[command["name"]]
		sprite.transform = command["transform"]
		sprite.visible = true

func _calculate_content_bounds() -> void:
	var first := true
	for source in source_animations.values():
		for source_frame in source.get("frames", []):
			if !frame_commands.has(source_frame):
				var commands:Array = []
				_collect_commands(timelines, int(source_frame), Transform2D.IDENTITY, commands)
				frame_commands[source_frame] = commands
			for command in frame_commands[source_frame]:
				var texture:AtlasTexture = atlas_regions[command["name"]]
				var rect := _transformed_rect(texture.region.size, command["transform"])
				if first:
					content_bounds = rect
					first = false
				else:
					content_bounds = content_bounds.merge(rect)
	if first:
		content_bounds = Rect2(Vector2.ZERO, Vector2.ONE)

func _transformed_rect(size:Vector2, transform:Transform2D) -> Rect2:
	var points:Array[Vector2] = [
		transform * Vector2.ZERO,
		transform * Vector2(size.x, 0),
		transform * Vector2(0, size.y),
		transform * size
	]
	var result := Rect2(points[0], Vector2.ZERO)
	for point in points.slice(1):
		result = result.expand(point)
	return result

func _timeline_length(layers:Array) -> int:
	var length := 1
	for layer in layers:
		for frame in layer.get("FR", []):
			length = maxi(length, int(frame.get("I", 0)) + int(frame.get("DU", 1)))
	return length

func _event_transform(matrix:Array) -> Transform2D:
	if matrix.size() < 6:
		return Transform2D.IDENTITY
	return Transform2D(Vector2(float(matrix[0]), float(matrix[1])),
		Vector2(float(matrix[2]), float(matrix[3])),
		Vector2(float(matrix[4]), float(matrix[5])))
