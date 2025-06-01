extends Control


const TRANSITION_TEXTURE = preload("res://assets/images/ui/transitionGradient.png")
@onready var transition = $Transition

@onready var info:Label = $Info
var prev_screen_size:Vector2 = Vector2.ZERO


func _process(delta):
	info.text = "FPS: " + str(Engine.get_frames_per_second())
	
	var screen_size:Vector2 = get_viewport().get_window().size
	if prev_screen_size != screen_size:
		prev_screen_size = screen_size
		
		var f_size = ( 1280.0 / screen_size.x ) * 16
		info.set("theme_override_font_sizes/font_size", f_size)


func toggle_load_text(loading:bool):
	$Loading.visible = loading

func transition_in():
	transition.texture = TRANSITION_TEXTURE
	transition.position.y = 720
	transition.scale.y = 1
	
	var tw:Tween = create_tween().\
	set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	tw.tween_property(transition, "position:y", -360, 1.0)
	await tw.finished
	transition.texture = null

func transition_out():
	transition.texture = TRANSITION_TEXTURE
	transition.position.y = 1080.0
	transition.scale.y = -1
	
	var tw:Tween = create_tween().\
	set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	tw.tween_property(transition, "position:y", 0.0, 1.0)
	await tw.finished
	transition.texture = null
