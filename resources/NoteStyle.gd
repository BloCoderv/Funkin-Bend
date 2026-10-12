extends Resource
class_name NoteStyle

const NOTE_STYLE_REGISTRY: Script = preload("res://source/data/NoteStyleRegistry.gd")
var style_id: String = ""
var _data: Dictionary = {}
var _fallback_style: NoteStyle = null
var _notes: SpriteFrames = SpriteFrames.new()
var _strums: SpriteFrames = SpriteFrames.new()
var _hold_covers: SpriteFrames = SpriteFrames.new()
var _splashes: SpriteFrames = SpriteFrames.new()
var _popups: SpriteFrames = SpriteFrames.new()
var _combo_nums: SpriteFrames = SpriteFrames.new()
var _strum_names: Dictionary = {}
var _splash_names: Dictionary = {}
var _judgement_scales: Dictionary = {}
var _combo_scale: float = 1.0
var _hold_note_texture: Texture2D = null

## Carrega um estilo sem aplicar fallback; o registry decide qual entrada usar.
static func load_style(requested_id: String) -> NoteStyle:
	var style: NoteStyle = NoteStyle.new()
	style.style_id = requested_id.to_lower()
	var path: String = "res://assets/data/notestyles/%s.json" % style.style_id
	if !FileAccess.file_exists(path):
		return style
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return style
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if !(parsed is Dictionary):
		return style
	style._data = parsed as Dictionary
	style._build_visual_cache()
	return style

## Indica se o arquivo do estilo foi encontrado e interpretado.
func has_data() -> bool:
	return !_data.is_empty()

## Constrói a textura da nota e aplica somente as propriedades do estilo.
func build_note_sprite(target: TextureRect, direction: int) -> void:
	var texture: Texture2D = _notes.get_frame_texture(str(direction), 0)
	if texture == null and _fallback() != null:
		_fallback().build_note_sprite(target, direction)
		return
	target.texture = texture
	target.scale = Vector2.ONE * get_note_scale()
	if texture != null:
		target.size = texture.get_size()

## Configura o receptor da strumline a partir dos assets do estilo.
func build_strum_sprite(target: AnimatedSprite2D, direction: int) -> void:
	var animation_key: String = "%sStatic" % _direction_name(direction)
	if !_strums.has_animation(get_strum_animation(animation_key)) and _fallback() != null:
		_fallback().build_strum_sprite(target, direction)
		return
	target.sprite_frames = _strums
	target.scale = Vector2.ONE * get_strumline_scale()
	target.animation = get_strum_animation(animation_key)

## Configura o efeito de splash que já pertence ao receptor.
func build_splash_sprite(target: AnimatedSprite2D) -> void:
	if _splashes.get_animation_names().size() <= 1 and _fallback() != null:
		_fallback().build_splash_sprite(target)
		return
	target.sprite_frames = _splashes
	var parent: Node2D = target.get_parent() as Node2D
	var parent_scale: float = parent.scale.x if parent != null else 1.0
	target.scale = Vector2.ONE * (get_splash_scale() / maxf(absf(parent_scale), 0.001))

## Configura a cobertura de sustain reutilizada pelo receptor.
func build_hold_cover_sprite(target: AnimatedSprite2D, direction: int) -> void:
	if !_hold_covers.has_animation("hold_%s_start" % _direction_name(direction)) and _fallback() != null:
		_fallback().build_hold_cover_sprite(target, direction)
		return
	target.sprite_frames = _hold_covers
	var parent: Node2D = target.get_parent() as Node2D
	var parent_scale: float = parent.scale.x if parent != null and !target.top_level else 1.0
	target.scale = Vector2.ONE * (get_hold_cover_scale() / maxf(absf(parent_scale), 0.001))
	target.animation = get_hold_cover_animation(_direction_name(direction), "start")

## Retorna a escala visual da cabeça da nota.
func get_note_scale() -> float:
	return _number_value("note", "scale", 1.0)

## Retorna o deslocamento visual da cabeça da nota.
func get_note_offsets() -> Vector2:
	return _vector_value("note", "offsets", Vector2.ZERO)

## Retorna a escala aplicada aos receptores e à linha de notas.
func get_strumline_scale() -> float:
	return _number_value("noteStrumline", "scale", 1.0)

## Retorna o deslocamento visual dos receptores.
func get_strumline_offsets() -> Vector2:
	return _vector_value("noteStrumline", "offsets", Vector2.ZERO)

func get_hold_note_scale() -> float:
	return _number_value("holdNote", "scale", 1.0)

func get_hold_note_offsets() -> Vector2:
	return _vector_value("holdNote", "offsets", Vector2.ZERO)

func get_hold_note_end_height() -> float:
	return _number_value("holdNote", "endHeight", 58.0)

func get_hold_atlas_columns() -> int:
	return int(_number_value("holdNote", "atlasColumns", 8.0))

func get_hold_end_offset_y() -> float:
	return _number_value("holdNote", "endOffsetY", 7.0)

func get_splash_scale() -> float:
	return _number_value("noteSplash", "scale", 1.0)

func get_splash_offsets() -> Vector2:
	return _vector_value("noteSplash", "offsets", Vector2.ZERO)

func get_hold_cover_scale() -> float:
	return _number_value("holdNoteCover", "scale", 1.0)

func get_hold_cover_offsets() -> Vector2:
	return _vector_value("holdNoteCover", "offsets", Vector2.ZERO)

func get_hold_note_texture() -> Texture2D:
	if _hold_note_texture != null:
		return _hold_note_texture
	if _fallback() != null:
		return _fallback().get_hold_note_texture()
	return null

func get_note_frames() -> SpriteFrames:
	return _notes

func get_strum_frames() -> SpriteFrames:
	return _strums

func get_splash_frames() -> SpriteFrames:
	return _splashes

func get_hold_cover_frames() -> SpriteFrames:
	return _hold_covers

func get_strum_animation(animation_key: String) -> String:
	if _strum_names.has(animation_key):
		return str(_strum_names[animation_key])
	if _fallback() != null:
		return _fallback().get_strum_animation(animation_key)
	return animation_key

func get_hold_cover_animation(direction: String, state: String) -> String:
	var key: String = "hold_%s_%s" % [direction, state]
	if _hold_covers.has_animation(key):
		return key
	if _fallback() != null:
		return _fallback().get_hold_cover_animation(direction, state)
	return key

func get_splash_animation(direction: int, splash_index: int) -> String:
	var names: Array = _splash_names.get(direction, []) as Array
	if splash_index >= 0 and splash_index < names.size():
		return str(names[splash_index])
	if _fallback() != null:
		return _fallback().get_splash_animation(direction, splash_index)
	return ""

func get_splash_count(direction: int) -> int:
	var names: Array = _splash_names.get(direction, []) as Array
	if !names.is_empty():
		return names.size()
	return _fallback().get_splash_count(direction) if _fallback() != null else 0

func get_popup_frames() -> SpriteFrames:
	if _popups.get_frame_count("default") > 0 or _popups.get_animation_names().size() > 1:
		return _popups
	return _fallback().get_popup_frames() if _fallback() != null else _popups

func get_combo_frames() -> SpriteFrames:
	if _combo_nums.get_frame_count("default") > 0 or _combo_nums.get_animation_names().size() > 1:
		return _combo_nums
	return _fallback().get_combo_frames() if _fallback() != null else _combo_nums

func get_judgement_scale(rating: String) -> float:
	if _judgement_scales.has(rating):
		return float(_judgement_scales[rating])
	return _fallback().get_judgement_scale(rating) if _fallback() != null else 1.0

func get_combo_scale() -> float:
	return _combo_scale if _combo_scale != 1.0 or _fallback() == null else _fallback().get_combo_scale()

func get_countdown_texture(counter: int) -> Texture2D:
	var config_names: Array[String] = ["", "countdownTwo", "countdownOne", "countdownGo"]
	if counter < 0 or counter >= config_names.size() or config_names[counter].is_empty():
		return null
	var assets: Dictionary = _data.get("assets", {}) as Dictionary
	var config: Dictionary = assets.get(config_names[counter], {}) as Dictionary
	var path: String = _resolve_asset_path(str(config.get("assetPath", "")))
	if FileAccess.file_exists(path + ".png"):
		return load(path + ".png") as Texture2D
	return _fallback().get_countdown_texture(counter) if _fallback() != null else null

func get_countdown_sound(counter: int) -> AudioStream:
	var config_names: Array[String] = ["countdownThree", "countdownTwo", "countdownOne", "countdownGo"]
	if counter < 0 or counter >= config_names.size():
		return null
	var assets: Dictionary = _data.get("assets", {}) as Dictionary
	var config: Dictionary = assets.get(config_names[counter], {}) as Dictionary
	var audio_data: Dictionary = config.get("data", {}) as Dictionary
	var audio_path: String = str(audio_data.get("audioPath", ""))
	var name: String = audio_path.get_file()
	if name.is_empty():
		name = ["introTHREE", "introTWO", "introONE", "introGO"][counter]
	var path: String = "res://assets/sounds/countdown/%s.ogg" % name
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return _fallback().get_countdown_sound(counter) if _fallback() != null else null

func _build_visual_cache() -> void:
	var assets: Dictionary = _data.get("assets", {}) as Dictionary
	var hold_config: Dictionary = assets.get("holdNote", {}) as Dictionary
	var hold_path: String = _resolve_asset_path(str(hold_config.get("assetPath", "")))
	if !hold_path.is_empty() and FileAccess.file_exists(hold_path + ".png"):
		_hold_note_texture = load(hold_path + ".png") as Texture2D
	var note_config: Dictionary = assets.get("note", {}) as Dictionary
	_load_directional(_notes, note_config, ["left", "down", "up", "right"])
	var strum_config: Dictionary = assets.get("noteStrumline", {}) as Dictionary
	_load_strums(_strums, strum_config.get("data", {}) as Dictionary, str(strum_config.get("assetPath", "")))
	_load_splashes(assets.get("noteSplash", {}) as Dictionary)
	_load_hold_covers(assets.get("holdNoteCover", {}) as Dictionary)
	_load_popup_images(assets)

func _fallback() -> NoteStyle:
	if _fallback_style != null:
		if _fallback_style == self:
			return null
		return _fallback_style
	var fallback_value: Variant = _data.get("fallback", null)
	if fallback_value == null:
		return null
	var fallback_id: String = str(fallback_value)
	if fallback_id.is_empty() or fallback_id == "null" or fallback_id == style_id:
		return null
	_fallback_style = NOTE_STYLE_REGISTRY.fetch_entry(fallback_id)
	return _fallback_style

func _number_value(asset_name: String, property_name: String, default_value: float) -> float:
	var config: Variant = (_data.get("assets", {}) as Dictionary).get(asset_name, {})
	if config is Dictionary and (config as Dictionary).has(property_name):
		return float((config as Dictionary)[property_name])
	return _fallback()._number_value(asset_name, property_name, default_value) if _fallback() != null else default_value

func _vector_value(asset_name: String, property_name: String, default_value: Vector2) -> Vector2:
	var config: Variant = (_data.get("assets", {}) as Dictionary).get(asset_name, {})
	if config is Dictionary and (config as Dictionary).has(property_name):
		var values: Array = (config as Dictionary)[property_name] as Array
		if values.size() >= 2:
			return Vector2(float(values[0]), float(values[1]))
	return _fallback()._vector_value(asset_name, property_name, default_value) if _fallback() != null else default_value

func _load_directional(frames: SpriteFrames, config: Dictionary, directions: Array[String]) -> void:
	var path: String = _resolve_asset_path(str(config.get("assetPath", "")))
	var data: Dictionary = config.get("data", {}) as Dictionary
	for index: int in directions.size():
		var item: Dictionary = data.get(directions[index], {}) as Dictionary
		XML.add_by_prefix(frames, path, str(index), str(item.get("prefix", "")), 24, false)

func _load_strums(frames: SpriteFrames, entries: Dictionary, default_path: String) -> void:
	for key: Variant in entries:
		var logical_name: String = str(key)
		var item: Dictionary = entries[key] as Dictionary
		var path: String = _resolve_asset_path(str(item.get("assetPath", default_path)))
		_strum_names[logical_name] = logical_name
		var looped: bool = logical_name.ends_with("ConfirmHold") and !Preferences.funkinHoldAnimation
		XML.add_by_prefix(frames, path, logical_name, str(item.get("prefix", "")), 24, looped)

func _load_splashes(config: Dictionary) -> void:
	var path: String = _resolve_asset_path(str(config.get("assetPath", "")))
	var data: Dictionary = config.get("data", {}) as Dictionary
	var directions: Array[String] = ["leftSplashes", "downSplashes", "upSplashes", "rightSplashes"]
	for direction: int in directions.size():
		var entries: Array = data.get(directions[direction], []) as Array
		_splash_names[direction] = []
		for index: int in entries.size():
			var item: Dictionary = entries[index] as Dictionary
			var animation_name: String = "splash%d_%d" % [direction, index]
			XML.add_by_prefix(_splashes, path, animation_name, str(item.get("prefix", "")), float(data.get("framerateDefault", 24)), false)
			(_splash_names[direction] as Array).append(animation_name)

func _load_hold_covers(config: Dictionary) -> void:
	var root_data: Dictionary = config.get("data", {}) as Dictionary
	for direction: String in ["left", "down", "up", "right"]:
		var direction_data: Dictionary = root_data.get(direction, {}) as Dictionary
		var path: String = _resolve_asset_path(str(direction_data.get("assetPath", config.get("assetPath", ""))))
		for state: String in ["start", "hold", "end"]:
			var item: Dictionary = direction_data.get(state, {}) as Dictionary
			XML.add_by_prefix(_hold_covers, path, "hold_%s_%s" % [direction, state], str(item.get("prefix", "")), 24, state == "hold")

func _load_popup_images(assets: Dictionary) -> void:
	for rating: String in ["sick", "good", "bad", "shit"]:
		var config: Dictionary = assets.get("judgement" + rating.capitalize(), {}) as Dictionary
		_add_image_animation(_popups, rating, str(config.get("assetPath", "")))
		_judgement_scales[rating] = float(config.get("scale", 1.0))
	for index: int in 10:
		var config: Dictionary = assets.get("comboNumber" + str(index), {}) as Dictionary
		_add_image_animation(_combo_nums, str(index), str(config.get("assetPath", "")))
		if index == 0:
			_combo_scale = float(config.get("scale", 1.0))

func _add_image_animation(frames: SpriteFrames, animation_name: String, asset_path: String) -> void:
	var path: String = _resolve_asset_path(asset_path)
	if path.is_empty() or !FileAccess.file_exists(path + ".png"):
		return
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, false)
	frames.add_frame(animation_name, load(path + ".png") as Texture2D)

func _direction_name(direction: int) -> String:
	return ["left", "down", "up", "right"][clampi(direction, 0, 3)]

func _resolve_asset_path(asset_path: String) -> String:
	if asset_path.is_empty() or asset_path.begins_with("res://"):
		return asset_path
	var value: String = asset_path
	if value.begins_with("shared:"):
		return "res://assets/shared/images/" + value.trim_prefix("shared:")
	if value.begins_with("default:"):
		return "res://assets/images/" + value.trim_prefix("default:")
	if value.begins_with("week6:"):
		return "res://assets/shared/images/" + value.trim_prefix("week6:")
	return "res://assets/shared/images/" + value
