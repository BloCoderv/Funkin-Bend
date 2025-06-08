extends Node
class_name StrumGroup

const STRUM_NOTE_SCENE = preload("res://scenes/notes/StrumNote.tscn")

const SIZE = 150
const SEPARATION = 11
const SCALE = 0.7
const MARGIN = 150
const MANIA = 3

static var strum_notes:Array[StrumNote] = []
static var opponent_strums:Array[StrumNote] = []
static var player_strums:Array[StrumNote] = []

func generate_strums():
	var separation:float = (SIZE + SEPARATION) * SCALE
	
	## PLAYER
	var x:int = int( Global.SCREEN_SIZE.x - MARGIN - (separation * MANIA) )
	
	if Preferences.middlescroll:
		x = int( (Global.SCREEN_SIZE.x / 2) - (separation * (MANIA + 1)) / 2 )
		x += int( separation / 2 )
	
	var strum_y:int = 104
	if Preferences.downscroll: strum_y = Global.SCREEN_SIZE.y - 104
	
	generate_new_strum(Vector2(x, strum_y), false)
	
	## OPPONENT
	var margin:float = MARGIN
	
	if Preferences.middlescroll:
		var sep:float = (SEPARATION + SIZE) * 0.5
		margin = (x / 2) - (sep * (MANIA + 1)) / 2
	
	generate_new_strum(Vector2(margin , strum_y), true)
	
	# STRUMLINE BG
	if Preferences.strumline_bg == 0.0: return
	
	var strum_bg:ColorRect = ColorRect.new()
	add_child(strum_bg)
	strum_bg.name = "StrumLine Background"
	strum_bg.color = Color.BLACK
	strum_bg.color.a = Preferences.strumline_bg
	
	const BG_MARGIN = 16
	strum_bg.position.x = int(x - separation / 2.0)
	strum_bg.size.x = int(separation * (MANIA + 1))
	strum_bg.position.x -= BG_MARGIN / 2.0
	strum_bg.size.x += BG_MARGIN
	
	strum_bg.size.y = Global.SCREEN_SIZE.y

func generate_new_strum(
offset:Vector2, opponent:bool, mania:int = 3) -> void:
	for strum in range(mania + 1):
		var new:StrumNote = STRUM_NOTE_SCENE.instantiate()
		
		new.position = offset
		new.data = strum
		new.scale = Vector2(SCALE, SCALE)
		new.downscroll = Preferences.downscroll
		new.opponent = opponent
		new.z_index = 4 if !Preferences.notes_behind_strum else 5
		new.self_modulate.a = Preferences.strums_opacity
		
		# WITHOUT OPPONENT NOTES
		if new.opponent and !Preferences.opponent_notes:
			new.visible = false
			new.sprite_frames = null
		
		# MIDDLESCROLL
		if new.opponent and Preferences.middlescroll:
			new.scale = Vector2(0.55, 0.55)
		
		var separation:float = (SIZE + SEPARATION) * new.scale.x
		new.position.x += strum * separation
		
		# INSTANTIATE
		add_child(new)
		strum_notes.append(new)
		if !opponent: player_strums.append(new)
		else: opponent_strums.append(new)
