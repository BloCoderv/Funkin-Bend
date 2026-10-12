extends CustomScript

##   <  -----  FocusCamera  -----  >   ##
##   : Essential for Songs

var playstate:PlayState = get_parent().get_parent()

func _on_event(values):
	# Charts antigos e eventos convertidos podem enviar apenas o índice do
	# personagem (float/int). Charts atuais enviam um Dictionary com parâmetros.
	var char_id:int = 0
	var pos := Vector2.ZERO
	var lerp := true
	if values is Dictionary:
		char_id = int(values.get("char", 0))
		pos.x = float(values.get("x", 0.0))
		pos.y = float(values.get("y", 0.0))
		lerp = values.get("ease", "") != "INSTANT"
	elif values is float or values is int:
		char_id = int(values)
	else:
		push_warning("FocusCamera recebeu um valor inválido: %s" % typeof(values))
		return

	var char := ""
	match char_id:
		0: char = "player"
		1: char = "opponent"
		2: char = "gf"
		_:
			push_warning("FocusCamera recebeu personagem inválido: %s" % char_id)
			return
	playstate.set_camera_target(char, pos, lerp)
