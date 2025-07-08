extends CustomScript


var playstate:PlayState = get_parent().get_parent()

func _on_event(values):
	var intensity:float = 1.0
	if values.has("intensity"): 
		intensity = values["intensity"]
	
	var rate:int = 4
	if values.has("rate"): 
		rate = values["rate"]
	
	playstate.camera_zoom_intensity = 0.015 * intensity + 1.0
	playstate.hud_camera_zoom_intensity = 0.015 * intensity * 2.0
	
	playstate.camera_zoom_rate = rate
