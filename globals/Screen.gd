extends Control


@onready var transition = $Transition

@onready var info:Label = $Info
@onready var loading:Label = $Loading
@onready var loading_bar:ProgressBar = $LoadingBar
var prev_screen_size:Vector2 = Vector2.ZERO


func _input(event):
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

var count:float = 0.0
func _process(delta):
	count += delta
	if count > 0.2:
		count = 0.0
		#info.text = "FPS: " + str(Engine.get_frames_per_second())
	
		var screen_size:Vector2 = get_viewport().get_window().size
		if prev_screen_size != screen_size:
			prev_screen_size = screen_size
			
			var f_size = ( 1280.0 / screen_size.x ) * 16
			info.set("theme_override_font_sizes/font_size", f_size)


func toggle_load_text(loading:bool):
	$Loading.visible = loading

func begin_asset_loading(_count:int = 1) -> void:
	loading.visible = true
	loading_bar.visible = true
	loading_bar.value = 0.0
	loading.text = "Preparing SpriteMaps..."

func set_asset_loading_progress(value:float, message:String = "Loading...") -> void:
	loading.visible = true
	loading_bar.visible = true
	loading_bar.value = clampf(value * 100.0, 0.0, 100.0)
	loading.text = message

func end_asset_loading() -> void:
	loading.visible = false
	loading_bar.visible = false

func transition_in():
	transition.position.y = 720
	transition.scale.y = 1
	
	var tw:Tween = create_tween().\
	set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	tw.tween_property(transition, "position:y", -360, 1.0)
	await tw.finished
	transition.texture = null

func transition_out():
	transition.position.y = 1080.0
	transition.scale.y = -1
	
	var tw:Tween = create_tween().\
	set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	tw.tween_property(transition, "position:y", 0.0, 1.0)
	await tw.finished
	transition.texture = null
