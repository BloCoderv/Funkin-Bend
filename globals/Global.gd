extends Node


## NOTES PRELOAD
var STRUM_NOTES: SpriteFrames
var NOTES: SpriteFrames
var NOTE_HOLD: Texture2D
var SPLASHES_TEXTURE: SpriteFrames
var HOLD_COVER_TEXTURE: SpriteFrames
var POPUPS: SpriteFrames
var COMBO_NUMS: SpriteFrames
var note_style_id: String = "funkin"
var note_style: NoteStyle = null

const SPLASHES_SCENE = preload("res://scenes/notes/Splashes.tscn")
const NOTE_STYLE_REGISTRY: Script = preload("res://source/data/NoteStyleRegistry.gd")

## GAME PRELOAD
const ICON_NONE = preload("res://icon.svg")

## OTHER
const SCREEN_SIZE = Vector2(1280, 720)

var last_result:Dictionary = {}


func _ready() -> void:
	load_note_style(note_style_id)
	## SETS CLEAR COLOR BLACK
	if !Preferences.godotClearColor: RenderingServer.set_default_clear_color(Color.BLACK)
	
	if Preferences.auto_pause:
		setup_auto_pause()

## Troca o estilo visual e atualiza aliases mantidos para compatibilidade.
func load_note_style(style_id: String) -> void:
	note_style_id = style_id.to_lower()
	hold_textures.clear()
	note_style = NOTE_STYLE_REGISTRY.fetch_entry(note_style_id)
	if note_style == null:
		note_style_id = "funkin"
		note_style = NOTE_STYLE_REGISTRY.fetch_entry(note_style_id)
	if note_style != null and note_style.has_data():
		note_style_id = note_style.style_id
	STRUM_NOTES = note_style.get_strum_frames()
	NOTES = note_style.get_note_frames()
	SPLASHES_TEXTURE = note_style.get_splash_frames()
	HOLD_COVER_TEXTURE = note_style.get_hold_cover_frames()
	NOTE_HOLD = note_style.get_hold_note_texture()
	POPUPS = note_style.get_popup_frames()
	COMBO_NUMS = note_style.get_combo_frames()

func hold_cover_animation(direction: int, state: String) -> String:
	return note_style.get_hold_cover_animation(["left", "down", "up", "right"][clampi(direction, 0, 3)], state)

func setup_auto_pause() -> void:
	get_viewport().get_window().focus_entered.connect(
		func(): 
			if get_tree():
				get_tree().paused = false)
	get_viewport().get_window().focus_exited.connect(
		func(): 
			if get_tree():
				get_tree().paused = true)

func change_scene(path: String, _with_transition: bool = false) -> Error:
	if !FileAccess.file_exists(path):
		push_error("Scene not found: %s" % path)
		return ERR_FILE_NOT_FOUND
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Could not change scene to %s (%s)" % [path, error_string(err)])
	else:
		get_tree().paused = false
	return err

#region SUSTAIN HOLD

var hold_textures:Dictionary[int, Array] = {}

## RETURNS [ HOLD TEXTURE, HOLD TEXTURE END ]
func get_hold_textures(data: int) -> Array:
	if hold_textures.has(data):
		return hold_textures[data]
	if NOTE_HOLD == null:
		return [null, null]
	
	var tex_size: float = NOTE_HOLD.get_size().x / float(note_style.get_hold_atlas_columns())
	
	var hold:Texture2D = AtlasTexture.new()
	var end:Texture2D = AtlasTexture.new()
	hold.atlas = NOTE_HOLD
	end.atlas = NOTE_HOLD
	
	hold.region.size.x = tex_size
	hold.region.position.x = data * (tex_size * 2)
	
	end.region = hold.region
	end.region.position.x += tex_size
	end.region.position.y = note_style.get_hold_end_offset_y()
	end.region.size.y = note_style.get_hold_note_end_height()
	
	# CONVERT TO IMAGE
	hold = ImageTexture.create_from_image(hold.get_image())
	end = ImageTexture.create_from_image(end.get_image())
	
	hold_textures[data] = [hold, end]
	return [hold, end]

#endregion
