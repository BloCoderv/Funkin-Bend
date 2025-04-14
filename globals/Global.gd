extends Node

# PRELOAD
const NOTES = preload("res://assets/images/ui/notes.tres")
const NOTE_HOLD = preload("res://assets/images/ui/NOTE_hold_assets.png")

# SCREEN STUFF
const SCREEN_SIZE = Vector2(1280, 720)

func _ready():
	get_viewport().get_window().focus_entered.connect(_on_focus)
	get_viewport().get_window().focus_exited.connect(_on_focus_lost)

func _on_focus():
	get_tree().paused = false

func _on_focus_lost():
	get_tree().paused = true

func change_scene(path:String, with_transition:bool=false):
	if FileAccess.file_exists(path): return
	assert(get_tree().change_scene_to_file(path) == OK)
	get_tree().paused = false # PAUSE MENU
