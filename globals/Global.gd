extends Node


## NOTES PRELOAD
const NOTES = preload("res://assets/images/ui/notes.tres")
const NOTE_HOLD = preload("res://assets/images/ui/NOTE_hold_assets.png")
const SPLASHES_TEXTURE = preload("res://assets/images/ui/noteSplashes.tres")
const HOLD_COVER_TEXTURE = preload("res://assets/images/ui/holdCover.tres")

## GAME PRELOAD
const ICON_NONE = preload("res://assets/images/icons/icon-face.png")

## OTHER
const SCREEN_SIZE = Vector2(1280, 720)


func _ready():
	## SETS CLEAR COLOR BLACK
	RenderingServer.set_default_clear_color(Color.WHITE)
	
	if Preferences.auto_pause:
		setup_auto_pause()

func setup_auto_pause():
	get_viewport().get_window().focus_entered.connect(
		func(): 
			if get_tree():
				get_tree().paused = false)
	get_viewport().get_window().focus_exited.connect(
		func(): 
			if get_tree():
				get_tree().paused = true)

func change_scene(path:String, with_transition:bool=false):
	if FileAccess.file_exists(path): return
	assert(get_tree().change_scene_to_file(path) == OK)
	get_tree().paused = false # PAUSE MENU

#region SUSTAIN HOLD

var hold_textures:Dictionary[int, Array] = {}

## RETURNS [ HOLD TEXTURE, HOLD TEXTURE END ]
func get_hold_textures(data:int) -> Array:
	if hold_textures.has(data):
		return hold_textures[data]
	
	var tex_size = NOTE_HOLD.get_size().x / 8
	
	var hold:Texture2D = AtlasTexture.new()
	var end:Texture2D = AtlasTexture.new()
	hold.atlas = NOTE_HOLD
	end.atlas = NOTE_HOLD
	
	hold.region.size.x = tex_size
	hold.region.position.x = data * (tex_size * 2)
	
	end.region = hold.region
	end.region.position.x += tex_size
	end.region.position.y = 7
	end.region.size.y = 58
	
	# CONVERT TO IMAGE
	hold = ImageTexture.create_from_image(hold.get_image())
	end = ImageTexture.create_from_image(end.get_image())
	
	hold_textures[data] = [hold, end]
	return [hold, end]

#endregion
