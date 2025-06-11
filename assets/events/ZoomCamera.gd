extends CustomScript


var playstate:PlayState = get_parent().get_parent()

func _on_event(values):
	var zoom:float = 1.0
	var duration:float = 4.0
	var ease:String = "linear"
	var direct:bool = false
	
	if !(values is Dictionary):
		duration *= Conductor.sec_per_beat
		playstate.tween_camera_zoom(values, duration, ease)
		return
	
	if values.has("zoom"):
		zoom = values["zoom"]
		
	if values.has("duration"):
		duration = values["duration"]
	
	if values.has("ease"):
		ease = values["ease"]
		duration = 0 if ease == "INSTANT" else duration
	
	if values.has("mode"):
		direct = (values["mode"] == "direct")
	
	duration *= Conductor.sec_per_beat
	
	playstate.tween_camera_zoom(zoom, duration, ease, direct)
