extends Node

# PRELOAD
const NOTES = preload("res://assets/images/ui/notes.tres")
const NOTE_HOLD = preload("res://assets/images/ui/NOTE_hold_assets.png")
const SPLASHES_TEXTURE = preload("res://assets/images/ui/noteSplashes.tres")

const ICON_NONE = preload("res://assets/images/icons/icon-face.png")

# SCREEN STUFF
const SCREEN_SIZE = Vector2(1280, 720)

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	
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

var hold_textures:Dictionary[int, Array] = {}
func get_hold_textures(data:int):
	if hold_textures.has(data):
		return hold_textures[data]
	
	var tex_size = NOTE_HOLD.get_size().x / 8
	
	var hold = AtlasTexture.new()
	var end = AtlasTexture.new()
	hold.atlas = NOTE_HOLD
	end.atlas = NOTE_HOLD
	
	hold.region.size.x = tex_size
	hold.region.position.x = data * (tex_size * 2)
	end.region = hold.region
	end.region.position.x += tex_size
	
	end.margin.position.y = -15
	end.margin.size.y = -35
	
	hold_textures[data] = [hold, end]
	return [hold, end]
