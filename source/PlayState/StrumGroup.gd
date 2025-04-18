extends Node
class_name StrumGroup

const STRUM_NOTE_SCENE = preload("res://scenes/objects/StrumNote.tscn")

static var strum_notes:Array = []
static var opponent_strums:Array = []
static var player_strums:Array = []

const SCALE = 0.7
const SEPARATION = 160 * SCALE
const MARGIN = 150

func generate_strums():
	# PLAYER
	var x:int = Global.SCREEN_SIZE.x - MARGIN - (SEPARATION * 3) # 3 is mania
	var y:int = 110 if !Preferences.downscroll else Global.SCREEN_SIZE.y - 110
	generate_new_strum(Vector2(x, y), false)
	# OPPONENT
	x = MARGIN # 3 is mania
	generate_new_strum(Vector2(x, y), true)

func generate_new_strum(offset:Vector2, opponent:bool, mania:int = 3):
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
		# INSTANTIATE
		add_child(new)
		player_strums.append(new)
		strum_notes.append(new)
