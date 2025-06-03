extends Node
class_name StrumGroup

const STRUM_NOTE_SCENE = preload("res://scenes/objects/StrumNote.tscn")

static var strum_notes:Array[StrumNote] = []
static var opponent_strums:Array[StrumNote] = []
static var player_strums:Array[StrumNote] = []

const SCALE = 0.7
const SEPARATION = 160 * SCALE
const MARGIN = 150
const MANIA = 3

func generate_strums():
	## PLAYER
	var x:int = Global.SCREEN_SIZE.x - MARGIN - (SEPARATION * MANIA)
	var y:int = 104 if !Preferences.downscroll else Global.SCREEN_SIZE.y - 104
	generate_new_strum(Vector2(x, y), false)
	
	## OPPONENT
	generate_new_strum(Vector2(MARGIN, y), true)
	
	# STRUMLINE BG
	if Preferences.strumline_bg == 0.0: return
	
	var strum_bg:ColorRect = ColorRect.new()
	add_child(strum_bg)
	strum_bg.name = "StrumLine Background"
	strum_bg.color = Color.BLACK
	strum_bg.color.a = Preferences.strumline_bg
	
	const BG_MARGIN = 16
	strum_bg.position.x = int(x - SEPARATION / 2.0)
	strum_bg.size.x = int(SEPARATION * (MANIA + 1))
	strum_bg.position.x -= BG_MARGIN / 2.0
	strum_bg.size.x += BG_MARGIN
	
	strum_bg.size.y = Global.SCREEN_SIZE.y

func generate_new_strum(
offset:Vector2, opponent:bool, mania:int = 3) -> void:
	for strum in range(mania + 1):
		var new:StrumNote = STRUM_NOTE_SCENE.instantiate()
		# POSITION
		new.position.x = strum * SEPARATION
		new.position.x += offset.x
		new.position.y = offset.y
		
		# SETUP
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
		
		# INSTANTIATE
		add_child(new)
		strum_notes.append(new)
		if !opponent: player_strums.append(new)
		else: opponent_strums.append(new)
