extends AnimatedSprite2D
class_name Character

var character:String = "bf"

var is_player:bool = false
var is_girlfriend:bool = false

var data:CharacterData = null
var sprite_map:SpriteMap = null

var special_anim:bool = false
var dance_idle:bool = false # For "danceLeft" and "danceRight"

var hold_time:float = 0.0
var is_holding:bool = false

var camera_offset:Vector2 = Vector2(0, 0)

func _ready() -> void:
	if !animation_finished.is_connected(_on_animation_finished):
		animation_finished.connect(_on_animation_finished)

func _process(delta:float) -> void:
	if !data: return
	
	if animation.begins_with(Util.SING_ANIM_ID) \
	and (!is_player or !is_holding): hold_time += delta
	else: hold_time = 0.0
	
	if hold_time >= Conductor.beat_step * data.sing_duration:
		var end_animation:String = "%s-end" % animation
		if sprite_frames.has_animation(end_animation):
			play_anim(end_animation)
		else:
			dance(true)
		hold_time = 0.0

func load_character(char:String, player:bool):
	data = CharacterData.load_character_data(char)
	if data == null:
		push_error("Character: FNF Base character data not found: %s" % char)
		return
	
	is_player = player
	character = char
	
	if name == "Girlfriend":
		is_girlfriend = true
	
	position += data.position
	if data.sprite_map_path != "":
		sprite_map = SpriteMap.new()
		add_child(sprite_map)
		sprite_map.configure(data.sprite_map_path, data.sprite_map_animations)
		sprite_frames = sprite_map.build_controller_frames()
		sprite_map.bake_finished.connect(_on_sprite_map_baked)
		if sprite_map.bake_complete:
			_on_sprite_map_baked()
		frame_changed.connect(_on_sprite_map_frame_changed)
	else:
		sprite_frames = data.sprites
	scale = data.scale
	flip_h = (data.flip_x != is_player)
	if sprite_map:
		sprite_map.set_mirror(flip_h)
	
	if sprite_frames.has_animation("danceLeft") \
	and sprite_frames.has_animation("danceRight"):
		dance_idle = true
	else: dance_idle = false
	
	dance()
	if sprite_map:
		_on_sprite_map_frame_changed()

func _on_sprite_map_frame_changed() -> void:
	if sprite_map and !sprite_map.bake_complete and sprite_map.source_animations.has(animation):
		sprite_map.visible = true
		sprite_map.set_animation_frame(animation, frame)
	elif sprite_map:
		sprite_map.visible = false

func _on_sprite_map_baked() -> void:
	if !sprite_map or !sprite_map.bake_complete:
		return
	var active_animation:String = str(animation)
	var baked := sprite_map.build_baked_frames()
	if data.sprites:
		for animation_name in data.sprites.get_animation_names():
			if baked.has_animation(animation_name):
				continue
			baked.add_animation(animation_name)
			baked.set_animation_speed(animation_name, data.sprites.get_animation_speed(animation_name))
			baked.set_animation_loop(animation_name, data.sprites.get_animation_loop(animation_name))
			for index in data.sprites.get_frame_count(animation_name):
				baked.add_frame(animation_name, data.sprites.get_frame_texture(animation_name, index))
	sprite_frames = baked
	sprite_map.visible = false
	self_modulate = Color.WHITE
	if sprite_frames.has_animation(active_animation):
		play_anim(active_animation, true)
	else:
		dance()

var danced:bool = false
func dance(force_restart:bool = false) -> void:
	if special_anim: return
	if !force_restart:
		if animation.begins_with(Util.SING_ANIM_ID):
			return
		var is_idle_animation:bool = animation in ["idle", "danceLeft", "danceRight"]
		if !is_idle_animation and is_playing():
			return
	
	if dance_idle:
		danced = !danced
		if danced:
			play_anim("danceLeft")
		else:
			play_anim("danceRight")
	else:
		play_anim("idle")

func _on_animation_finished() -> void:
	if animation.begins_with("combo") \
	or animation.begins_with("drop") \
	or (animation.ends_with("-end") \
	and !animation.begins_with("idle") \
	and !animation.begins_with("dance")):
		dance(true)

func begin_sing(direction:int) -> void:
	if direction < 0 or direction >= Util.SING_ANIMS.size():
		return
	hold_time = 0.0
	play_anim(Util.SING_ANIMS[direction], true)

func end_sing(direction:int) -> void:
	hold_time = 0.0

func play_anim(anim:String, force:bool = false, backwards:bool = false):
	if !sprite_frames: return
	
	if sprite_frames.has_animation(anim) \
	and sprite_frames.get_frame_count(anim) > 0 \
	and sprite_frames.get_frame_texture(anim, 0) != null:
		if force: stop()
		
		if backwards: play_backwards(anim)
		else: play(anim)
		
		offset = -data.offsets.get(anim, Vector2.ZERO)
		
		if !is_player:
			offset.x *= -1
		if sprite_map:
			sprite_map.set_mirror(flip_h)
			sprite_map.set_draw_offset(offset)
		
		if is_girlfriend:
			if anim == "singLEFT":
				danced = true
			elif anim == "singRIGHT":
				danced = false
			elif anim == "singUP" or anim == "singDOWN":
				danced = !danced
		if sprite_map:
			_on_sprite_map_frame_changed()
	elif !anim.ends_with("miss"):
		print_debug("{0} not has animation {1}".format([ character, anim ]))

func get_mid_point() -> Vector2:
	if sprite_map:
		return sprite_map.get_mid_point()
	if sprite_frames == null:
		return Vector2.ZERO
	var preferred:Array[String] = ["idle", "danceLeft"]
	for animation_name:String in preferred:
		var preferred_texture:Texture2D = _get_animation_texture(animation_name)
		if preferred_texture != null:
			return preferred_texture.get_size() / Vector2(2.0, 2.0)
	for animation_name:String in sprite_frames.get_animation_names():
		var texture:Texture2D = _get_animation_texture(animation_name)
		if texture != null:
			return texture.get_size() / Vector2(2.0, 2.0)
	return Vector2.ZERO

func _get_animation_texture(animation_name:String) -> Texture2D:
	if !sprite_frames.has_animation(animation_name):
		return null
	for frame_index in range(sprite_frames.get_frame_count(animation_name)):
		var texture:Texture2D = sprite_frames.get_frame_texture(animation_name, frame_index)
		if texture != null:
			return texture
	return null
