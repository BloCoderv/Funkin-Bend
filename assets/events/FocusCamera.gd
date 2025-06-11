extends CustomScript


var playstate:PlayState = get_parent().get_parent()

func _on_event(values):
	var char = ""
	match int(values["char"]):
		0: char = "player"
		1: char = "opponent"
		2: char = "gf"
	
	var pos = Vector2(0, 0)
	if values.has("x"):
		pos.x = values["x"]
	if values.has("y"):
		pos.y = values["y"]
	
	var lerp = true
	if values.has("ease"):
		lerp = (values["ease"] != "INSTANT")
	
	playstate.set_camera_target(char, pos, lerp)
